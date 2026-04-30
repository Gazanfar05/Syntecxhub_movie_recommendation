import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../services/api_client.dart';

// Configuration
final apiBaseUrlProvider = StateProvider<String>((ref) {
  return 'https://localhost:5000/api';
});

final apiClientProvider = Provider<MovieApi>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final dio = ref.watch(dioProvider);
  return MovieApi(dio, baseUrl: baseUrl);
});

final dioProvider = Provider((ref) {
  // Dio instance is created in api_client.dart
  return createDio();
});

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchResults {
  final List<Movie> results;
  final String query;
  final DateTime timestamp;

  SearchResults({
    required this.results,
    required this.query,
    required this.timestamp,
  });
}

final searchResultsProvider = FutureProvider.autoDispose<SearchResults?>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return null;

  final api = ref.watch(apiClientProvider);
  
  // Add debounce
  await Future.delayed(const Duration(milliseconds: 300));

  try {
    // Pull the catalog in pages so newly added titles are searchable too.
    final movies = <Movie>[];
    const pageSize = 500;
    var offset = 0;

    while (true) {
      final page = await api.getAllMovies(limit: pageSize, offset: offset);
      movies.addAll(page);

      if (page.length < pageSize) {
        break;
      }

      offset += pageSize;
    }
    
    final filtered = movies
        .where((m) =>
            m.title.toLowerCase().contains(query.toLowerCase()) ||
            m.genresString.toLowerCase().contains(query.toLowerCase()))
        .take(20)
        .toList();

    return SearchResults(
      results: filtered,
      query: query,
      timestamp: DateTime.now(),
    );
  } catch (e) {
    throw Exception('Search failed: $e');
  }
});

// Recommendations
final selectedMovieProvider = StateProvider<Movie?>((ref) => null);

final recommendationsProvider = FutureProvider.autoDispose<List<Movie>?>((ref) async {
  final movie = ref.watch(selectedMovieProvider);
  if (movie == null) return null;

  final api = ref.watch(apiClientProvider);
  try {
    final recommendations = await api.getRecommendations(movie.title, limit: 20);
    
    // Convert Recommendation objects to Movie objects with similarity scores
    final movies = recommendations.map((rec) {
      return Movie(
        movieId: rec.movieId,
        title: rec.title,
        genres: rec.genres,
        releaseYear: rec.releaseYear,
        imdbId: rec.imdbId,
        tmdbId: rec.tmdbId,
        avgRating: rec.avgRating,
        ratingCount: rec.ratingCount,
        similarity: rec.similarityScore,
        tags: rec.tags,
      );
    }).toList();

    // Sort by similarity descending
    movies.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    return movies;
  } catch (e) {
    throw Exception('Failed to get recommendations: $e');
  }
});

// Favorites
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Movie>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Movie>> {
  FavoritesNotifier() : super([]);

  void toggleFavorite(Movie movie) {
    if (state.any((m) => m.movieId == movie.movieId)) {
      state = state.where((m) => m.movieId != movie.movieId).toList();
    } else {
      state = [...state, movie];
    }
  }

  bool isFavorite(int movieId) {
    return state.any((m) => m.movieId == movieId);
  }
}
