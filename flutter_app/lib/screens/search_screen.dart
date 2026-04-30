import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../models/movie.dart';
import '../providers/movie_providers.dart';
import '../theme/app_theme.dart';
import 'recommendations_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Movies'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverToBoxAdapter(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGradientStart.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search movies, actors...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Results
          searchResults.when(
            data: (results) {
              if (results == null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_creation_outlined,
                          size: 80.sp,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Search for your favorite movies',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (results.results.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80.sp,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No movies found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final movie = results.results[index];
                      final isFavorite = favorites.any((m) => m.movieId == movie.movieId);

                      return FadeInUp(
                        delay: Duration(milliseconds: 50 * index),
                        duration: const Duration(milliseconds: 600),
                        child: _buildMovieCard(
                          context,
                          movie,
                          isFavorite,
                          isDark,
                        ),
                      );
                    },
                    childCount: results.results.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildShimmerCard(isDark),
                  ),
                  childCount: 5,
                ),
              ),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80.sp,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Search failed',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(
    BuildContext context,
    Movie movie,
    bool isFavorite,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedMovieProvider.notifier).state = movie;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
        );
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: 12.h),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Movie Poster Placeholder
              Container(
                width: 60.w,
                height: 90.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGradientStart,
                      AppTheme.primaryGradientEnd,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.movie,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Movie Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (movie.hasValidYear)
                      Text(
                        '${movie.releaseYear} • ${movie.genresString}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12.sp,
                        ),
                      ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          movie.avgRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '(${movie.ratingCount} ratings)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Favorite Button
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(movie);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppTheme.darkSurface : Colors.grey[300]!,
      highlightColor: isDark ? AppTheme.darkSurface.withOpacity(0.5) : Colors.grey[100]!,
      child: Card(
        elevation: 0,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 90.h,
                color: Colors.white,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16.h,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 12.h,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 12.h,
                      width: 100.w,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
