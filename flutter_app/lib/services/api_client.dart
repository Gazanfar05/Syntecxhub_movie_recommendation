import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

import '../models/movie.dart';

part 'api_client.g.dart';

// Dio instance factory
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://localhost:5000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      validateStatus: (status) => true,
    ),
  );

  // Disable SSL certificate verification for local development
  (dio.httpClientAdapter as dynamic).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  };

  return dio;
}

@RestApi(baseUrl: 'https://localhost:5000/api')
abstract class MovieApi {
  factory MovieApi(Dio dio, {String? baseUrl}) = _MovieApi;

  @GET('/movies')
  Future<List<Movie>> getAllMovies({
    @Query('limit') int limit = 100,
    @Query('offset') int offset = 0,
  });

  @POST('/recommend')
  Future<List<Recommendation>> getRecommendations(
    @Query('title') String title, {
    @Query('limit') int limit = 10,
  });

  @GET('/health')
  Future<Map<String, dynamic>> getHealth();

  @GET('/stats')
  Future<Map<String, dynamic>> getStats();
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
  final List<String>? tags;

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
    this.tags,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}
