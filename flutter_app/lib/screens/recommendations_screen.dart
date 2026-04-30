import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/movie.dart';
import '../providers/movie_providers.dart';
import '../theme/app_theme.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  late ScrollController _scrollController;
  late int _limit;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _limit = 10;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      setState(() => _limit += 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMovie = ref.watch(selectedMovieProvider);
    final recommendations = ref.watch(recommendationsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (selectedMovie == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recommendations'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'No movie selected',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Selected Movie Card
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGradientStart,
                      AppTheme.primaryGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGradientStart.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      selectedMovie.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Recommendations Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'People who liked this also liked:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Recommendations Grid
            recommendations.when(
              data: (recs) {
                if (recs == null || recs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Text(
                        'No recommendations available',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                final displayRecs = recs.take(_limit).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: displayRecs.length,
                  itemBuilder: (context, index) {
                    final rec = displayRecs[index];
                    final isFavorite = favorites.any((m) => m.movieId == rec.movieId);

                    return FadeInUp(
                      delay: Duration(milliseconds: 50 * index),
                      duration: const Duration(milliseconds: 600),
                      child: _buildRecommendationCard(
                        context,
                        rec,
                        isFavorite,
                        isDark,
                      ),
                    );
                  },
                );
              },
              loading: () => Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        AppTheme.accentStart,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Finding recommendations...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
              error: (error, stackTrace) => Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80.sp,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load recommendations',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(recommendationsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    Movie movie,
    bool isFavorite,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedMovieProvider.notifier).state = movie;
        // Refresh recommendations for the new movie
        ref.refresh(recommendationsProvider);
      },
      child: Card(
        elevation: 0,
        color: isDark ? AppTheme.darkSurface : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster Placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGradientStart,
                      AppTheme.primaryGradientEnd,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.movie,
                        color: Colors.white30,
                        size: 48.sp,
                      ),
                    ),
                    // Similarity Score Badge
                    Positioned(
                      top: 8.w,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${(movie.similarity * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Movie Info
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (movie.hasValidYear)
                    Text(
                      movie.releaseYear.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.sp,
                        color: Colors.grey,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14.sp,
                      ),
                      Text(
                        movie.avgRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            constraints: BoxConstraints(
                              minHeight: 24.h,
                              minWidth: 24.w,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 16.sp,
                            ),
                            onPressed: () {
                              ref.read(favoritesProvider.notifier).toggleFavorite(movie);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
