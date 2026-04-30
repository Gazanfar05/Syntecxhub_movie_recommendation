import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/movie_providers.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Gradient Background
            Container(
              width: double.infinity,
              height: 400.h,
              decoration: BoxDecoration(
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
                  // Animated Background Pattern
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Icon(
                            Icons.movie,
                            size: 80.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            'CineMatch',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 48.sp,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            'Discover Movies You\'ll Love',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 800),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: AppTheme.accentStart,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentStart.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Start Searching',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Popular Movies Section
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'How It Works',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Steps
                  _buildStepCard(
                    context,
                    1,
                    'Search',
                    'Find any movie from our vast collection',
                    Icons.search,
                    isDark,
                  ),
                  SizedBox(height: 12.h),
                  _buildStepCard(
                    context,
                    2,
                    'Select',
                    'Pick your favorite from the results',
                    Icons.touch_app,
                    isDark,
                  ),
                  SizedBox(height: 12.h),
                  _buildStepCard(
                    context,
                    3,
                    'Discover',
                    'Get personalized recommendations instantly',
                    Icons.star,
                    isDark,
                  ),
                ],
              ),
            ),
            // Features Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Features',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Smart Matching',
                          Icons.bolt,
                          AppTheme.accentStart,
                          isDark,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'AI Powered',
                          Icons.auto_awesome,
                          AppTheme.accentEnd,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Fast Results',
                          Icons.speed,
                          AppTheme.primaryGradientStart,
                          isDark,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Save Favorites',
                          Icons.favorite_border,
                          AppTheme.primaryGradientEnd,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  if (favorites.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Favorites (${favorites.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          'View All',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentStart,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    int step,
    String title,
    String description,
    IconData icon,
    bool isDark,
  ) {
    return FadeInLeft(
      delay: Duration(milliseconds: 200 * step),
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: isDark ? AppTheme.darkSurface : Colors.white,
          border: Border.all(
            color: AppTheme.accentStart.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
                  icon,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: color.withOpacity(isDark ? 0.1 : 0.05),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
