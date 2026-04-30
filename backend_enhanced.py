"""
CineMatch - Movie Recommendation Backend
Simple Flask API with TF-IDF content-based recommendations
"""

import argparse
import os
import ssl
import threading
import pickle
import joblib
from pathlib import Path
from scipy import sparse
import time
import urllib.request
import zipfile
from collections import defaultdict
from datetime import datetime
from functools import wraps

import numpy as np
import pandas as pd
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


# ============================================================================
# DATA LOADING & PREPROCESSING
# ============================================================================

class RecommendationEngine:
    """Movie recommendation engine using TF-IDF and cosine similarity"""
    
    def __init__(self, data_dir="data/ml-latest-small"):
        self.data_dir = data_dir
        self.movies_df = None
        self.tfidf_matrix = None
        self.vectorizer = None
        self.movie_index = {}
        self.initialized = False
        self.cache_dir = Path(".cache")
        self.cache_dir.mkdir(exist_ok=True)
        
    def load_dataset(self):
        """Load and preprocess MovieLens dataset"""
        print(f"📂 Loading dataset from {self.data_dir}...")
        
        # Download if missing
        self._ensure_dataset()
        
        # Load CSVs
        movies = pd.read_csv(f"{self.data_dir}/movies.csv")
        tags = pd.read_csv(f"{self.data_dir}/tags.csv")
        ratings = pd.read_csv(f"{self.data_dir}/ratings.csv")
        
        # Extract year from title: "Movie (1999)" -> 1999
        movies["release_year"] = movies["title"].str.extract(r"\((\d{4})\)")[0].astype("Int64")
        
        # Clean title: "Movie (1999)" -> "Movie"
        movies["clean_title"] = movies["title"].str.replace(r"\s*\(\d{4}\)\s*$", "", regex=True)
        movies["clean_title"] = movies["clean_title"].fillna("")
        
        # Handle "The" at the end: "Title, The" -> "The Title"
        movies["match_title"] = movies["clean_title"].apply(self._normalize_title)
        
        # Aggregate tags per movie
        tags["tag"] = tags["tag"].fillna("").astype(str)
        tags_agg = tags.groupby("movieId")["tag"].apply(lambda x: ", ".join(x)).reset_index()
        tags_agg.columns = ["movieId", "tags_combined"]
        
        # Calculate average rating and count
        ratings_agg = ratings.groupby("movieId").agg({
            "rating": ["mean", "count"]
        }).reset_index()
        ratings_agg.columns = ["movieId", "avg_rating", "rating_count"]
        
        # Merge everything
        movies = movies.merge(ratings_agg, on="movieId", how="left")
        movies = movies.merge(tags_agg, on="movieId", how="left")

        # Prefer the latest row for any duplicated title so manually added
        # Bollywood metadata overrides the older MovieLens copy.
        movies = movies.drop_duplicates(subset=["match_title"], keep="last")
        
        # Fill NaN values
        movies["avg_rating"] = movies["avg_rating"].fillna(0.0)
        movies["rating_count"] = movies["rating_count"].fillna(0).astype(int)
        movies["tags_combined"] = movies["tags_combined"].fillna("")
        
        # Create feature text for TF-IDF
        movies["feature_text"] = (
            movies["clean_title"].fillna("") + " " +
            movies["genres"].fillna("") + " " + 
            movies["tags_combined"].fillna("")
        ).str.lower()
        
        self.movies_df = movies[[
            "movieId", "title", "clean_title", "match_title", 
            "genres", "release_year", "avg_rating", "rating_count",
            "tags_combined", "feature_text"
        ]].copy()
        
        print(f"✓ Loaded {len(self.movies_df)} movies")
        
    def _ensure_dataset(self):
        """Download dataset if missing"""
        if os.path.exists(f"{self.data_dir}/movies.csv"):
            return
        
        print(f"📥 Downloading MovieLens dataset...")
        
        url = "http://files.grouplens.org/datasets/movielens/ml-latest-small.zip"
        zip_path = "/tmp/ml-latest-small.zip"
        
        try:
            default_context = ssl.create_default_context()
            try:
                with urllib.request.urlopen(url, context=default_context) as response, open(zip_path, "wb") as output_file:
                    output_file.write(response.read())
            except Exception:
                fallback_context = ssl._create_unverified_context()
                with urllib.request.urlopen(url, context=fallback_context) as response, open(zip_path, "wb") as output_file:
                    output_file.write(response.read())
            with zipfile.ZipFile(zip_path, "r") as zip_ref:
                zip_ref.extractall("data")
            os.remove(zip_path)
            print(f"✓ Dataset downloaded and extracted")
        except Exception as e:
            print(f"✗ Download failed: {e}")
            raise
    
    @staticmethod
    def _normalize_title(title):
        """Normalize title: 'Title, The' -> 'The Title'"""
        articles = ["the", "a", "an"]
        words = title.split()
        if words and words[-1].lower() in articles:
            return f"{words[-1]} {' '.join(words[:-1])}"
        return title
    
    def build_tfidf_matrix(self):
        """Build TF-IDF matrix from feature text"""
        print("🔨 Building TF-IDF matrix...")

        # Try to load cached matrix and vectorizer
        if self._load_cache():
            print("✓ Loaded TF-IDF matrix and vectorizer from cache")
            self.initialized = True
            return

        self.vectorizer = TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            stop_words="english",
            min_df=1,
            max_df=0.8
        )
        
        self.tfidf_matrix = self.vectorizer.fit_transform(
            self.movies_df["feature_text"].fillna("")
        )
        
        # Build movie index for fast lookup
        for idx, row in self.movies_df.iterrows():
            self.movie_index[row["match_title"].lower()] = idx
            # Also add original title
            self.movie_index[row["clean_title"].lower()] = idx
        
        print(f"✓ TF-IDF matrix built: {self.tfidf_matrix.shape}")
        self.initialized = True
        # Save to cache for faster restarts
        try:
            self._save_cache()
        except Exception as e:
            print(f"⚠️ Failed to save TF-IDF cache: {e}")
    
    def get_recommendations(self, movie_title, limit=10):
        """Get recommendations for a movie"""
        if not self.initialized:
            return []
        
        # Find movie
        search_title = self._normalize_title(movie_title.lower())
        
        if search_title not in self.movie_index:
            # Try fuzzy match
            matches = [title for title in self.movie_index.keys() 
                      if search_title in title or title in search_title]
            if not matches:
                return []
            search_title = matches[0]
        
        movie_idx = self.movie_index[search_title]
        
        # Calculate similarities
        similarities = cosine_similarity(
            self.tfidf_matrix[movie_idx:movie_idx+1],
            self.tfidf_matrix
        ).ravel()
        
        # Get top recommendations (excluding the movie itself)
        top_indices = np.argsort(similarities)[::-1][1:limit+1]
        
        recommendations = []
        for idx in top_indices:
            row = self.movies_df.iloc[idx]
            recommendations.append({
                "movieId": int(row["movieId"]),
                "title": row["title"],
                "genres": row["genres"].split("|") if isinstance(row["genres"], str) else [],
                "releaseYear": int(row["release_year"]) if pd.notna(row["release_year"]) else 0,
                "similarityScore": float(similarities[idx]),
                "imdbId": 0,
                "tmdbId": 0,
                "avgRating": float(row["avg_rating"]) if pd.notna(row["avg_rating"]) else 0.0,
                "ratingCount": int(row["rating_count"]) if pd.notna(row["rating_count"]) else 0,
            })
        
        return recommendations
    
    def get_stats(self):
        """Get dataset statistics"""
        if self.movies_df is None:
            return {}
        
        genres = defaultdict(int)
        for genre_str in self.movies_df["genres"].fillna(""):
            if isinstance(genre_str, str):
                for g in genre_str.split("|"):
                    genres[g] += 1
        
        return {
            "totalMovies": len(self.movies_df),
            "avgRating": float(self.movies_df["avg_rating"].mean()),
            "avgRatingCount": float(self.movies_df["rating_count"].mean()),
            "topGenres": dict(sorted(genres.items(), key=lambda x: x[1], reverse=True)[:10]),
        }

    # --------------------
    # Caching helpers
    # --------------------
    def _cache_paths(self):
        return {
            "vectorizer": self.cache_dir / "vectorizer.joblib",
            "matrix": self.cache_dir / "tfidf.npz",
            "movies": self.cache_dir / "movies.pkl",
            "index": self.cache_dir / "movie_index.pkl",
            "popular": self.cache_dir / "popular_recs.pkl",
        }

    def _save_cache(self):
        paths = self._cache_paths()
        joblib.dump(self.vectorizer, paths["vectorizer"])
        sparse.save_npz(str(paths["matrix"]), self.tfidf_matrix)
        self.movies_df.to_pickle(paths["movies"])
        with open(paths["index"], "wb") as f:
            pickle.dump(self.movie_index, f)

    def _load_cache(self):
        paths = self._cache_paths()
        try:
            if paths["vectorizer"].exists() and paths["matrix"].exists() and paths["movies"].exists():
                self.vectorizer = joblib.load(paths["vectorizer"])
                self.tfidf_matrix = sparse.load_npz(str(paths["matrix"]))
                self.movies_df = pd.read_pickle(paths["movies"])
                with open(paths["index"], "rb") as f:
                    self.movie_index = pickle.load(f)
                return True
        except Exception as e:
            print(f"⚠️ Error loading cache: {e}")
        return False

    def save_popular_recommendations(self, data):
        paths = self._cache_paths()
        with open(paths["popular"], "wb") as f:
            pickle.dump(data, f)

    def load_popular_recommendations(self):
        paths = self._cache_paths()
        try:
            if paths["popular"].exists():
                with open(paths["popular"], "rb") as f:
                    return pickle.load(f)
        except Exception as e:
            print(f"⚠️ Error loading popular recommendations: {e}")
        return {}


# ============================================================================
# FLASK APP
# ============================================================================

def create_app(engine):
    """Create Flask app with movie engine"""
    app = Flask(__name__)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    
    # Request tracking per endpoint and IP
    request_times = defaultdict(list)
    
    # Rate limiting decorator
    def rate_limit(max_requests=60, period=60):
        def decorator(f):
            @wraps(f)
            def wrapped(*args, **kwargs):
                ip = request.remote_addr
                bucket_key = f"{f.__name__}:{ip}"
                now = time.time()
                
                # Clean old requests
                request_times[bucket_key] = [t for t in request_times[bucket_key] 
                                     if now - t < period]
                
                # Check limit
                if len(request_times[bucket_key]) >= max_requests:
                    return jsonify({"error": "Rate limit exceeded"}), 429
                
                request_times[bucket_key].append(now)
                return f(*args, **kwargs)
            return wrapped
        return decorator
    
    # Response cache
    cache = {}
    cache_ttl = 300  # 5 minutes
    # Precomputed popular recommendations
    popular_cache = engine.load_popular_recommendations() if hasattr(engine, 'load_popular_recommendations') else {}
    favorites_store = {}
    
    @app.after_request
    def after_request(response):
        """Add security headers"""
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        return response
    
    # ======================================================================
    # API ENDPOINTS
    # ======================================================================
    
    @app.route("/", methods=["GET"])
    def index():
        """Serve the web UI"""
        react_index = os.path.join('web', 'react_index.html')
        if os.path.exists(react_index):
            return send_from_directory('web', 'react_index.html')
        return send_from_directory('web', 'index.html')
    
    @app.route("/api/health", methods=["GET"])
    @rate_limit(max_requests=100)
    def health():
        """Health check endpoint"""
        return jsonify({
            "status": "healthy" if engine.initialized else "initializing",
            "version": "1.0.0",
            "timestamp": datetime.utcnow().isoformat(),
        }), 200
    
    @app.route("/api/movies", methods=["GET"])
    @rate_limit(max_requests=60)
    def get_movies():
        """Get all movies (with pagination)"""
        if not engine.initialized:
            return jsonify({"error": "Engine not initialized"}), 503
        
        limit = int(request.args.get("limit", 100))
        offset = int(request.args.get("offset", 0))
        year = request.args.get("year")
        genre = request.args.get("genre")
        
        limit = min(limit, 500)  # Max 500

        df = engine.movies_df
        if year:
            try:
                y = int(year)
                df = df[df["release_year"] == y]
            except Exception:
                pass
        if genre:
            df = df[df["genres"].str.contains(genre, case=False, na=False)]

        movies = df.iloc[offset:offset+limit]
        
        result = []
        for _, row in movies.iterrows():
            result.append({
                "movieId": int(row["movieId"]),
                "title": row["title"],
                "genres": row["genres"].split("|") if isinstance(row["genres"], str) else [],
                "releaseYear": int(row["release_year"]) if pd.notna(row["release_year"]) else 0,
                "imdbId": 0,
                "tmdbId": 0,
                "avgRating": float(row["avg_rating"]) if pd.notna(row["avg_rating"]) else 0.0,
                "ratingCount": int(row["rating_count"]) if pd.notna(row["rating_count"]) else 0,
            })
        
        return jsonify(result), 200
    
    @app.route("/api/recommend", methods=["POST", "GET"])
    @rate_limit(max_requests=30)
    def get_recommendations():
        """Get recommendations for a movie"""
        if not engine.initialized:
            return jsonify({"error": "Engine not initialized"}), 503
        
        title = request.args.get("title", "").strip()
        limit = int(request.args.get("limit", 10))
        
        if not title:
            return jsonify({"error": "Movie title required"}), 400
        
        limit = min(limit, 50)  # Max 50
        
        # Check cache
        cache_key = f"{title}:{limit}"
        if cache_key in cache:
            cached_data, cached_time = cache[cache_key]
            if time.time() - cached_time < cache_ttl:
                return jsonify(cached_data), 200
        
        try:
            recommendations = engine.get_recommendations(title, limit)
            
            if not recommendations:
                return jsonify({"error": f"Movie \"{title}\" not found"}), 404
            
            # Cache the result
            cache[cache_key] = (recommendations, time.time())
            
            return jsonify(recommendations), 200
        
        except Exception as e:
            return jsonify({"error": str(e)}), 500
    
    @app.route("/api/stats", methods=["GET"])
    @rate_limit(max_requests=100)
    def get_stats():
        """Get dataset statistics"""
        if not engine.initialized:
            return jsonify({"error": "Engine not initialized"}), 503
        
        return jsonify(engine.get_stats()), 200

    @app.route("/api/movie/<int:movie_id>", methods=["GET"])
    @rate_limit(max_requests=100)
    def movie_detail(movie_id):
        """Get movie details by ID"""
        if not engine.initialized:
            return jsonify({"error": "Engine not initialized"}), 503
        df = engine.movies_df
        row = df[df["movieId"] == movie_id]
        if row.empty:
            return jsonify({"error": "Movie not found"}), 404
        row = row.iloc[0]
        return jsonify({
            "movieId": int(row["movieId"]),
            "title": row["title"],
            "genres": row["genres"].split("|") if isinstance(row["genres"], str) else [],
            "releaseYear": int(row["release_year"]) if pd.notna(row["release_year"]) else 0,
            "avgRating": float(row["avg_rating"]) if pd.notna(row["avg_rating"]) else 0.0,
            "ratingCount": int(row["rating_count"]) if pd.notna(row["rating_count"]) else 0,
            "tags": row["tags_combined"],
        }), 200

    @app.route("/api/favorites", methods=["GET", "POST", "DELETE"])
    def favorites():
        """Simple favorites store per-IP (local dev only)"""
        ip = request.remote_addr
        if request.method == "GET":
            return jsonify(favorites_store.get(ip, [])), 200
        data = request.get_json() or {}
        if request.method == "POST":
            movie_id = int(data.get("movieId", 0))
            favorites_store.setdefault(ip, [])
            if movie_id and movie_id not in favorites_store[ip]:
                favorites_store[ip].append(movie_id)
            return jsonify(favorites_store[ip]), 200
        if request.method == "DELETE":
            movie_id = int(data.get("movieId", 0))
            favorites_store.setdefault(ip, [])
            if movie_id in favorites_store[ip]:
                favorites_store[ip].remove(movie_id)
            return jsonify(favorites_store[ip]), 200

    @app.route("/api/precompute_popular", methods=["POST"]) 
    def precompute_popular():
        """Precompute recommendations for top popular movies and cache them."""
        if not engine.initialized:
            return jsonify({"error": "Engine not initialized"}), 503
        params = request.get_json() or {}
        top_k = int(params.get("top_k", 100))
        rec_limit = int(params.get("rec_limit", 10))
        method = params.get("method", "content")  # content or collaborative

        # Determine top movies by rating_count
        df = engine.movies_df.sort_values(by="rating_count", ascending=False).head(top_k)
        popular = {}
        for _, row in df.iterrows():
            title = row["match_title"] if pd.notna(row["match_title"]) else row["clean_title"]
            try:
                recs = engine.get_recommendations(title, rec_limit)
            except Exception:
                recs = []
            popular[int(row["movieId"])]= recs

        # Save and update in-memory cache
        if hasattr(engine, 'save_popular_recommendations'):
            try:
                engine.save_popular_recommendations(popular)
            except Exception as e:
                print(f"⚠️ Could not save popular recommendations: {e}")
        popular_cache.update(popular)
        return jsonify({"status": "ok", "computed": len(popular)}), 200

    @app.route("/api/popular/<int:movie_id>", methods=["GET"])
    def get_precomputed(movie_id):
        if str(movie_id) in popular_cache:
            return jsonify(popular_cache[str(movie_id)]), 200
        if movie_id in popular_cache:
            return jsonify(popular_cache[movie_id]), 200
        return jsonify({"error": "No precomputed recommendations for this movie"}), 404
    
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Endpoint not found"}), 404
    
    @app.errorhandler(500)
    def server_error(e):
        return jsonify({"error": "Internal server error"}), 500
    
    return app


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="CineMatch Movie Recommendation Server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    
    args = parser.parse_args()
    
    # Initialize engine (start async to serve app quickly)
    print("🚀 Preparing CineMatch recommendation engine (initializing in background)...")
    engine = RecommendationEngine()

    def init_engine():
        try:
            engine.load_dataset()
            engine.build_tfidf_matrix()
            print("✅ Engine initialization complete")
        except Exception as e:
            print(f"✗ Failed to initialize engine: {e}")

    # Start background initialization thread
    threading.Thread(target=init_engine, daemon=True).start()

    # Create Flask app
    app = create_app(engine)
    
    # Start server
    print(f"\n✓ Server running at: http://localhost:{args.port}")
    print(f"Health check: http://localhost:{args.port}/api/health")
    print(f"Recommend: http://localhost:{args.port}/api/recommend?title=Toy%20Story")
    print(f"🛑 Press Ctrl+C to stop\n")
    
    try:
        app.run(
            host=args.host,
            port=args.port,
            debug=False,
            use_reloader=False,
            threaded=True,
        )
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped")


if __name__ == "__main__":
    main()
