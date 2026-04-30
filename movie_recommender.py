from __future__ import annotations

import argparse
import io
import re
import sys
import ssl
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from urllib.request import urlopen

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


MOVIELENS_URL = "https://files.grouplens.org/datasets/movielens/ml-latest-small.zip"
DEFAULT_DATA_DIR = Path("data")
DEFAULT_EXTRACT_DIR = DEFAULT_DATA_DIR / "ml-latest-small"


@dataclass(frozen=True)
class DatasetBundle:
    movies: pd.DataFrame
    ratings: pd.DataFrame
    tags: pd.DataFrame
    links: pd.DataFrame


def ensure_movielens_dataset(data_dir: Path = DEFAULT_DATA_DIR) -> Path:
    """Download and extract MovieLens 100k-small data if it is not already present."""
    extract_dir = data_dir / "ml-latest-small"
    movies_path = extract_dir / "movies.csv"
    if movies_path.exists():
        return extract_dir

    data_dir.mkdir(parents=True, exist_ok=True)
    archive_path = data_dir / "ml-latest-small.zip"

    print(f"Downloading MovieLens dataset from {MOVIELENS_URL}...")
    try:
        with urlopen(MOVIELENS_URL, context=ssl.create_default_context()) as response:
            archive_path.write_bytes(response.read())
    except Exception:
        with urlopen(MOVIELENS_URL, context=ssl._create_unverified_context()) as response:
            archive_path.write_bytes(response.read())

    print("Extracting dataset...")
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(data_dir)

    return extract_dir


def load_dataset(extract_dir: Path) -> DatasetBundle:
    movies = pd.read_csv(extract_dir / "movies.csv")
    ratings = pd.read_csv(extract_dir / "ratings.csv")
    tags = pd.read_csv(extract_dir / "tags.csv")
    links = pd.read_csv(extract_dir / "links.csv")
    return DatasetBundle(movies=movies, ratings=ratings, tags=tags, links=links)


def clean_title(title: str) -> str:
    title = re.sub(r"\(\d{4}\)$", "", str(title)).strip()
    title = re.sub(r"[^a-zA-Z0-9\s]", " ", title)
    title = re.sub(r"\s+", " ", title)
    return title.lower().strip()


def normalize_title_for_match(title: str) -> str:
    title = re.sub(r"\(\d{4}\)$", "", str(title)).strip().lower()
    title = re.sub(r"[^a-z0-9,\s]", " ", title)
    title = re.sub(r"\s+", " ", title).strip()

    article_match = re.match(r"^(.*?),\s*(the|a|an)$", title)
    if article_match:
        title = f"{article_match.group(2)} {article_match.group(1)}"

    title = title.replace(",", " ")
    title = re.sub(r"\s+", " ", title)
    return title.strip()


def tokenize_genres(genres: str) -> str:
    if not isinstance(genres, str) or genres == "(no genres listed)":
        return ""
    return genres.replace("|", " ").lower().strip()


def aggregate_tags(tags: pd.DataFrame) -> pd.DataFrame:
    if tags.empty:
        return pd.DataFrame(columns=["movieId", "tag_text"])

    cleaned = tags.copy()
    cleaned["tag"] = cleaned["tag"].fillna("")
    cleaned["tag"] = cleaned["tag"].astype(str).str.lower().str.replace(r"[^a-z0-9\s]", " ", regex=True)
    cleaned["tag"] = cleaned["tag"].str.replace(r"\s+", " ", regex=True).str.strip()
    return (
        cleaned.groupby("movieId", as_index=False)["tag"]
        .apply(lambda s: " ".join(sorted({item for item in s if item})))
        .rename(columns={"tag": "tag_text"})
    )


def build_movie_features(bundle: DatasetBundle) -> pd.DataFrame:
    movies = bundle.movies.copy()
    movies["clean_title"] = movies["title"].map(clean_title)
    movies["match_title"] = movies["title"].map(normalize_title_for_match)
    movies["genre_text"] = movies["genres"].map(tokenize_genres)

    tags = aggregate_tags(bundle.tags)
    movies = movies.merge(tags, on="movieId", how="left")
    movies["tag_text"] = movies["tag_text"].fillna("")

    movies["feature_text"] = (
        movies["clean_title"] + " " + movies["genre_text"] + " " + movies["tag_text"]
    ).str.replace(r"\s+", " ", regex=True).str.strip()

    movies["release_year"] = movies["title"].str.extract(r"\((\d{4})\)")
    movies["release_year"] = pd.to_numeric(movies["release_year"], errors="coerce")

    # Keep the newest duplicate title so the added Bollywood metadata is used.
    movies = movies.drop_duplicates(subset=["match_title"], keep="last")
    return movies


def run_eda(bundle: DatasetBundle, movies: pd.DataFrame) -> None:
    ratings = bundle.ratings

    print("\n=== Dataset Overview ===")
    print(f"Movies: {len(bundle.movies):,}")
    print(f"Ratings: {len(ratings):,}")
    print(f"Tags: {len(bundle.tags):,}")
    print(f"Users: {ratings['userId'].nunique():,}")
    print(f"Unique movies rated: {ratings['movieId'].nunique():,}")
    print(f"Average rating: {ratings['rating'].mean():.2f}")

    print("\n=== Missing Values ===")
    missing = pd.DataFrame({
        "movies_missing": bundle.movies.isna().sum(),
        "ratings_missing": ratings.isna().sum(),
    }).fillna(0)
    print(missing.T.to_string())

    print("\n=== Rating Distribution ===")
    print(ratings["rating"].value_counts().sort_index().to_string())

    print("\n=== Top Genres ===")
    genre_counts = (
        bundle.movies["genres"].str.split("|").explode().value_counts().head(10)
    )
    print(genre_counts.to_string())

    print("\n=== Most-Rated Movies ===")
    popularity = (
        ratings.groupby("movieId")
        .agg(rating_count=("rating", "size"), avg_rating=("rating", "mean"))
        .query("rating_count >= 50")
        .sort_values(["avg_rating", "rating_count"], ascending=False)
        .head(10)
        .reset_index()
    )
    popular_movies = movies[["movieId", "title"]].merge(popularity, on="movieId", how="inner")
    print(popular_movies[["title", "rating_count", "avg_rating"]].to_string(index=False))

    print("\n=== Cleaned Metadata Sample ===")
    print(
        movies[["title", "clean_title", "genres", "tag_text", "feature_text"]]
        .head(5)
        .to_string(index=False)
    )


def build_similarity_index(movies: pd.DataFrame) -> tuple[TfidfVectorizer, np.ndarray]:
    vectorizer = TfidfVectorizer(
        stop_words="english",
        ngram_range=(1, 2),
        min_df=1,
        max_features=5000,
    )
    matrix = vectorizer.fit_transform(movies["feature_text"].fillna(""))
    return vectorizer, matrix


def recommend_movies(
    title_query: str,
    movies: pd.DataFrame,
    tfidf_matrix: np.ndarray,
    top_n: int = 5,
) -> pd.DataFrame:
    query = normalize_title_for_match(title_query)
    titles = movies["match_title"].fillna("")
    exact_match = movies[titles == query]
    if exact_match.empty:
        contains_match = movies[titles.str.contains(re.escape(query), na=False)]
        if contains_match.empty:
            raise ValueError(f"Could not find a movie matching: {title_query}")
        exact_match = contains_match.head(1)

    movie_index = exact_match.index[0]
    scores = cosine_similarity(tfidf_matrix[movie_index], tfidf_matrix).ravel()
    ranked_movie_indices = np.argsort(scores)[::-1][1 : top_n + 1]
    movie_ids = ranked_movie_indices.tolist()
    result = movies.loc[movie_ids, ["title", "genres", "release_year"]].copy()
    result["similarity"] = scores[movie_ids]
    return result.sort_values("similarity", ascending=False).reset_index(drop=True)


def run_qualitative_evaluation(movies: pd.DataFrame, tfidf_matrix: np.ndarray) -> None:
    sample_queries = [
        "Toy Story (1995)",
        "The Matrix (1999)",
        "Forrest Gump (1994)",
        "Pulp Fiction (1994)",
    ]

    print("\n=== Qualitative Evaluation ===")
    for query in sample_queries:
        print(f"\nQuery: {query}")
        try:
            recommendations = recommend_movies(query, movies, tfidf_matrix, top_n=5)
            print(recommendations.to_string(index=False, float_format=lambda value: f"{value:.3f}"))
        except ValueError as exc:
            print(str(exc))


def create_flask_app(movies: pd.DataFrame, tfidf_matrix: np.ndarray):
    from flask import Flask, jsonify, request

    app = Flask(__name__)

    @app.get("/health")
    def health():
        return jsonify(status="ok", movies=len(movies))

    @app.get("/recommend")
    def recommend():
        title = request.args.get("title", "").strip()
        limit = int(request.args.get("limit", 5))
        if not title:
            return jsonify(error="Missing required query parameter: title"), 400
        try:
            recs = recommend_movies(title, movies, tfidf_matrix, top_n=limit)
        except ValueError as exc:
            return jsonify(error=str(exc)), 404
        return jsonify(query=title, recommendations=recs.to_dict(orient="records"))

    return app


def parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MovieLens content-based recommender")
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR, help="Directory for the dataset")
    parser.add_argument("--serve", action="store_true", help="Run the Flask API instead of the CLI demo")
    parser.add_argument("--host", default="127.0.0.1", help="Flask host")
    parser.add_argument("--port", type=int, default=5000, help="Flask port")
    return parser.parse_args(list(argv))


def main(argv: Iterable[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])

    extract_dir = ensure_movielens_dataset(args.data_dir)
    bundle = load_dataset(extract_dir)
    movies = build_movie_features(bundle)
    _, tfidf_matrix = build_similarity_index(movies)

    run_eda(bundle, movies)

    if args.serve:
        app = create_flask_app(movies, tfidf_matrix)
        app.run(host=args.host, port=args.port, debug=True)
        return 0

    run_qualitative_evaluation(movies, tfidf_matrix)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
