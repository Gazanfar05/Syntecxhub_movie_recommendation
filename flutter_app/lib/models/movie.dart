import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie {
  final int movieId;
  final String title;
  final List<String> genres;
  @JsonKey(name: 'release_year')
  final int releaseYear;
  @JsonKey(name: 'imdb_id')
  final int imdbId;
  @JsonKey(name: 'tmdb_id')
  final int tmdbId;
  @JsonKey(name: 'avg_rating')
  final double avgRating;
  @JsonKey(name: 'rating_count')
  final int ratingCount;
  @JsonKey(defaultValue: 0.0)
  final double similarity;
  final List<String>? tags;

  Movie({
    required this.movieId,
    required this.title,
    required this.genres,
    required this.releaseYear,
    required this.imdbId,
    required this.tmdbId,
    required this.avgRating,
    required this.ratingCount,
    this.similarity = 0.0,
    this.tags,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson() => _$MovieToJson(this);

  String get genresString => genres.join(', ');
  bool get hasValidYear => releaseYear > 0;
  String get imdbUrl => 'https://www.imdb.com/title/tt${imdbId.toString().padLeft(7, '0')}/';
  String get tmdbUrl => 'https://www.themoviedb.org/movie/$tmdbId';
}

@JsonSerializable()
class Recommendation {
  final int movieId;
  final String title;
  final List<String> genres;
  @JsonKey(name: 'release_year')
  final int releaseYear;
  @JsonKey(name: 'similarity_score')
  final double similarityScore;
  @JsonKey(name: 'imdb_id')
  final int imdbId;
  @JsonKey(name: 'tmdb_id')
  final int tmdbId;
  @JsonKey(name: 'avg_rating')
  final double avgRating;
  @JsonKey(name: 'rating_count')
  final int ratingCount;

  Recommendation({
    required this.movieId,
    required this.title,
    required this.genres,
    required this.releaseYear,
    required this.similarityScore,
    required this.imdbId,
    required this.tmdbId,
    required this.avgRating,
    required this.ratingCount,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationToJson(this);

  String get genresString => genres.join(', ');
  String get matchPercentage => '${(similarityScore * 100).toStringAsFixed(0)}%';
}

@JsonSerializable()
class SearchResult {
  final String query;
  final List<Movie> results;
  final int count;

  SearchResult({
    required this.query,
    required this.results,
    required this.count,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultToJson(this);
}

@JsonSerializable()
class RecommendationResponse {
  final String title;
  final List<Recommendation> recommendations;
  final int count;

  RecommendationResponse({
    required this.title,
    required this.recommendations,
    required this.count,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) => _$RecommendationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationResponseToJson(this);
}

@JsonSerializable()
class AppStats {
  @JsonKey(name: 'total_movies')
  final int totalMovies;
  @JsonKey(name: 'total_ratings')
  final int totalRatings;
  @JsonKey(name: 'total_users')
  final int totalUsers;
  @JsonKey(name: 'avg_rating')
  final double avgRating;
  @JsonKey(name: 'top_genres')
  final Map<String, dynamic> topGenres;

  AppStats({
    required this.totalMovies,
    required this.totalRatings,
    required this.totalUsers,
    required this.avgRating,
    required this.topGenres,
  });

  factory AppStats.fromJson(Map<String, dynamic> json) => _$AppStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AppStatsToJson(this);
}
