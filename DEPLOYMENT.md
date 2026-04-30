# 🎬 CineMatch - Deployment Guide

## Quick Start

### Prerequisites
- **Python 3.8+** with pip
- **Flutter 3.0+** (for mobile UI) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **macOS/Linux** (for shell scripts) or **Windows** (use equivalent commands)
- OpenSSL (usually pre-installed on macOS/Linux)

---

## 📱 Option 1: Backend Only (Flask Server)

### 1. Generate SSL Certificates
```bash
./generate_cert.sh
```

This creates:
- `certs/server.crt` - SSL certificate
- `certs/server.key` - Private key

### 2. Start the Backend Server
```bash
./run_backend.sh
```

**Output:**
```
✓ Server running at: https://localhost:5000

API Endpoints:
  • POST   https://localhost:5000/api/recommend - Get recommendations
  • GET    https://localhost:5000/api/movies - List all movies
  • GET    https://localhost:5000/api/stats - Get dataset statistics
  • GET    https://localhost:5000/api/health - Health check
```

### 3. Test the API

#### Get Health Status
```bash
curl -k https://localhost:5000/api/health
```

#### Get Movie Recommendations
```bash
curl -k -X POST \
  "https://localhost:5000/api/recommend?title=The%20Matrix&limit=10" \
  -H "Content-Type: application/json"
```

#### Get All Movies
```bash
curl -k https://localhost:5000/api/movies?limit=50
```

---

## 📲 Option 2: Full-Stack (Backend + Flutter UI)

### Step 1: Install Flutter
```bash
# Download Flutter from: https://flutter.dev/docs/get-started/install
# Add Flutter to your PATH

flutter doctor  # Verify installation
```

### Step 2: Start Backend Server (Terminal 1)
```bash
./run_backend.sh
```

Wait for the output:
```
✓ Server running at: https://localhost:5000
```

### Step 3: Launch Flutter App (Terminal 2)
```bash
./run_flutter.sh
```

**First run notes:**
- Flutter will download iOS/Android SDKs (takes ~5-10 minutes)
- Select a device when prompted:
  - **iOS Simulator**: `open -a Simulator`
  - **Android Emulator**: `emulator -list-avds` and select one
  - **Web**: Type `w` for Flutter web

### Step 4: Use the App

1. **Home Screen**: See welcome message and app features
2. **Search**: Tap "Start Searching" button
3. **Enter Movie**: Type movie title (e.g., "Toy Story", "The Matrix")
4. **View Results**: Select a movie to get recommendations
5. **Save Favorites**: ❤️ icon to bookmark movies

---

## 🔧 API Documentation

### Base URL
```
https://localhost:5000/api
```

### Endpoints

#### 1. Get Recommendations
**POST** `/recommend`

**Query Parameters:**
- `title` (string, required): Movie title to get recommendations for
- `limit` (integer, optional, default=10): Number of recommendations

**Example:**
```bash
curl -k -X POST "https://localhost:5000/api/recommend?title=Toy%20Story&limit=5"
```

**Response:**
```json
[
  {
    "movie_id": 3114,
    "title": "Toy Story 3",
    "genres": ["Animation", "Adventure", "Comedy"],
    "release_year": 2010,
    "similarity_score": 0.87,
    "avg_rating": 8.3,
    "rating_count": 15423
  }
]
```

#### 2. Get All Movies
**GET** `/movies`

**Query Parameters:**
- `limit` (integer, optional, default=100): Maximum movies to return
- `offset` (integer, optional, default=0): Pagination offset

**Example:**
```bash
curl -k "https://localhost:5000/api/movies?limit=20&offset=0"
```

**Response:**
```json
[
  {
    "movie_id": 1,
    "title": "Toy Story",
    "genres": ["Animation", "Adventure", "Comedy"],
    "release_year": 1995,
    "avg_rating": 8.3,
    "rating_count": 38055
  }
]
```

#### 3. Get Dataset Statistics
**GET** `/stats`

**Example:**
```bash
curl -k "https://localhost:5000/api/stats"
```

**Response:**
```json
{
  "total_movies": 9742,
  "total_ratings": 100836,
  "total_tags": 3683,
  "rating_distribution": { ... },
  "top_genres": { ... }
}
```

#### 4. Health Check
**GET** `/health`

**Example:**
```bash
curl -k "https://localhost:5000/api/health"
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

---

## 🔒 HTTPS/SSL Configuration

### Why Self-Signed Certificates?
Local development requires SSL for Flutter's HTTP client. We use self-signed certificates which are:
- ✅ Free and instantly available
- ✅ Perfect for local testing
- ⚠️ Will show browser security warnings (expected)
- ⚠️ Not suitable for production

### Accepting Certificates in Flutter
The app automatically accepts self-signed certificates for `localhost` development. In production, you would:
1. Get certificates from a trusted CA (e.g., Let's Encrypt)
2. Or implement certificate pinning

### Troubleshooting SSL Errors

**Error: "Certificate verification failed"**
```bash
# Regenerate certificates
./generate_cert.sh

# Restart backend
./run_backend.sh
```

**Error: "Connection refused"**
```bash
# Ensure backend is running
curl -k https://localhost:5000/api/health
```

---

## 🚀 Advanced Usage

### Change API Server Address
In Flutter app settings (future version):
- Default: `https://localhost:5000`
- Can be changed to: `https://192.168.x.x:5000` for network access

### Enable CORS for Different Origins
Edit `backend_enhanced.py`:
```python
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "https://192.168.1.100"],
        "methods": ["GET", "POST", "OPTIONS"]
    }
})
```

### Access from Another Machine
```bash
# On backend machine, find IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Use that IP from Flutter app settings
https://192.168.x.x:5000
```

---

## 📊 Performance Tips

### For Faster Recommendations
- First query takes longer (loads data + builds TF-IDF matrix)
- Subsequent queries use cached results (faster)
- Limit results to 10-20 for best response time

### Memory Usage
- Dataset: ~50MB in memory (9,742 movies with metadata)
- TF-IDF matrix: ~100MB for similarity computation
- Total: ~150MB RAM required

### Network
- Keep backend and app on same machine for development
- Over network: ~100-500ms latency per request

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `flutter: command not found` | Add Flutter to PATH: `export PATH="$PATH:~/flutter/bin"` |
| `Port 5000 already in use` | Kill process: `lsof -ti:5000 \| xargs kill -9` |
| `Certificate verification failed` | Run: `./generate_cert.sh` then restart backend |
| `App crashes on search` | Ensure backend is running and accessible |
| `No movies found` | Wait for dataset to load (first run takes ~10s) |
| `Slow recommendations` | Normal on first query (~2-3 seconds) |

---

## 📁 Project Structure

```
Syntecxhub_movie_recommendation/
├── movie_recommender.py          # Original CLI recommender
├── backend_enhanced.py           # Flask HTTPS server
├── generate_cert.sh              # SSL certificate generator
├── run_backend.sh                # Backend startup script
├── run_flutter.sh                # Flutter app startup script
├── requirements.txt              # Python dependencies
├── data/                         # MovieLens dataset (auto-downloaded)
├── certs/                        # SSL certificates (auto-generated)
└── flutter_app/                  # Flutter mobile app
    ├── lib/
    │   ├── main.dart             # App entry point
    │   ├── theme/                # Design system
    │   ├── models/               # Data models
    │   ├── services/             # API client
    │   ├── providers/            # State management
    │   └── screens/              # UI screens
    └── pubspec.yaml              # Flutter dependencies
```

---

## 🎯 Next Steps

1. **Personalization**: Add user login and collaborative filtering
2. **Advanced Search**: Full-text search, filters by genre/year
3. **Analytics**: Track recommendation accuracy, popular searches
4. **Mobile Optimization**: Offline mode, caching, progressive loading
5. **Cloud Deployment**: Deploy backend to cloud (AWS, GCP, Heroku)

---

## 📝 Notes

- **MovieLens Dataset**: Automatically downloaded on first run (~50MB)
- **First Launch**: Takes ~30 seconds to build recommendation engine
- **Browser Warning**: Expected with self-signed certificates (click "Advanced" → "Proceed")
- **Network Access**: Use IP address instead of `localhost` from other machines

---

## 🆘 Support

For issues:
1. Check [Troubleshooting](#-troubleshooting) section
2. Verify backend is running: `curl -k https://localhost:5000/api/health`
3. Check Flutter logs: `flutter logs`
4. Review Python logs in terminal running `run_backend.sh`
