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
    final stats = ref.watch(statsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 300.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  const AnimatedHeroGradient(),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            'CineMatch',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 42.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            'Discover movies tailored to your taste',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search Bar
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
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
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Search movies...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: const Icon(Icons.filter_list),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),
                // Stats Section
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 800),
                  child: stats.when(
                    data: (stat) => stat != null
                        ? _buildStatsGrid(context, stat)
                        : const SizedBox.shrink(),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                SizedBox(height: 28.h),
                // Quick Actions
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Quick Access',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // Featured Bollywood Movies
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bollywood Spotlight',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        height: 150.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredBollywoodMovies.length,
                          separatorBuilder: (_, __) => SizedBox(width: 12.w),
                          itemBuilder: (context, index) {
                            final movie = _featuredBollywoodMovies[index];
                            return _FeaturedMovieCard(movie: movie);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 800),
                  child: Row(
                    children: [
                      _buildQuickAccessCard(
                        context,
                        icon: Icons.favorite,
                        label: 'Favorites',
                        count: favorites.length,
                        onTap: () {},
                      ),
                      SizedBox(width: 12.w),
                      _buildQuickAccessCard(
                        context,
                        icon: Icons.trending_up,
                        label: 'Popular',
                        count: 0,
                        onTap: () {},
                      ),
                      SizedBox(width: 12.w),
                      _buildQuickAccessCard(
                        context,
                        icon: Icons.star,
                        label: 'Top Rated',
                        count: 0,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                // Recent Searches
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Getting Started',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  duration: const Duration(milliseconds: 800),
                  child: _buildGettingStartedCard(context),
                ),
                SizedBox(height: 40.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppStats stat) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          context,
          icon: Icons.movie,
          label: 'Movies',
          value: stat.totalMovies.toString(),
        ),
        _buildStatCard(
          context,
          icon: Icons.people,
          label: 'Users',
          value: stat.totalUsers.toString(),
        ),
        _buildStatCard(
          context,
          icon: Icons.rate_review,
          label: 'Ratings',
          value: '${stat.totalRatings ~/ 1000}K+',
        ),
        _buildStatCard(
          context,
          icon: Icons.star,
          label: 'Avg Rating',
          value: stat.avgRating.toStringAsFixed(1),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
              padding: EdgeInsets.all(8.w),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          color: isDark ? AppTheme.darkSurface : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryGradientStart,
                  size: 24.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (count > 0) ...[
                  SizedBox(height: 4.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGradientStart.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGradientStart,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGettingStartedCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark
          ? AppTheme.darkSurface.withOpacity(0.5)
          : AppTheme.lightSurface.withOpacity(0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.primaryGradientStart.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎬 How to get started',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            _buildStepItem('1', 'Search for a movie you love', context),
            SizedBox(height: 8.h),
            _buildStepItem('2', 'Get personalized recommendations', context),
            SizedBox(height: 8.h),
            _buildStepItem('3', 'Save favorites for later', context),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String step, String text, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGradientStart,
                AppTheme.primaryGradientEnd,
              ],
            ),
          ),
          padding: EdgeInsets.all(2.w),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.darkBackground,
            ),
            padding: EdgeInsets.all(3.w),
            child: Text(
              step,
              style: const TextStyle(
                color: AppTheme.primaryGradientStart,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }
}

const List<_FeaturedMovie> _featuredBollywoodMovies = [
  _FeaturedMovie('Dilwale Dulhania Le Jayenge', '1995', 'Romance • Drama'),
  _FeaturedMovie('3 Idiots', '2009', 'Comedy • Drama'),
  _FeaturedMovie('Lagaan', '2001', 'Adventure • Drama'),
  _FeaturedMovie('Chak De! India', '2007', 'Drama'),
  _FeaturedMovie('Queen', '2013', 'Comedy • Drama'),
  _FeaturedMovie('Gully Boy', '2019', 'Drama'),
];

class _FeaturedMovie {
  const _FeaturedMovie(this.title, this.year, this.genres);

  final String title;
  final String year;
  final String genres;
}

class _FeaturedMovieCard extends StatelessWidget {
  const _FeaturedMovieCard({required this.movie});

  final _FeaturedMovie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGradientStart.withOpacity(0.95),
            AppTheme.accentStart.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGradientStart.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
            ),
            child: Icon(
              Icons.local_movies,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            movie.year,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            movie.genres,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedHeroGradient extends StatefulWidget {
  const AnimatedHeroGradient({Key? key}) : super(key: key);

  @override
  State<AnimatedHeroGradient> createState() => _AnimatedHeroGradientState();
}

class _AnimatedHeroGradientState extends State<AnimatedHeroGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final drift = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(Alignment.topLeft, const Alignment(0.3, -0.2), drift)!,
              end: Alignment.lerp(Alignment.bottomRight, const Alignment(0.9, 0.7), drift)!,
              colors: [
                AppTheme.primaryGradientStart,
                Color.lerp(AppTheme.primaryGradientEnd, AppTheme.accentPurple, drift)!,
                AppTheme.accentStart.withOpacity(0.9),
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -40.w + 30.w * drift,
                top: 40.h,
                child: _GlowOrb(
                  size: 140.w,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              Positioned(
                right: -20.w,
                top: 120.h - 24.h * drift,
                child: _GlowOrb(
                  size: 110.w,
                  color: AppTheme.accentStart.withOpacity(0.22),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    painter: GridPainter(progress: drift),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.2 + drift * 0.2, -0.3),
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter({this.progress = 0.0});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 40.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.progress != progress;
}
