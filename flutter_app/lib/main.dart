import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MovieRecommenderApp()));
}

class MovieRecommenderApp extends StatelessWidget {
  const MovieRecommenderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdaptFactor: 0.5,
      builder: (context, child) {
        return MaterialApp(
          title: 'CineMatch',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: child,
          debugShowCheckedModeBanner: false,
        );
      },
      child: const HomeScreen(),
    );
  }
}
