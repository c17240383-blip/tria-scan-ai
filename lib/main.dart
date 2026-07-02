import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/recognition_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TriaScanApp());
}

class TriaScanApp extends StatelessWidget {
  const TriaScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecognitionService(),
      child: MaterialApp(
        title: 'TRIA Scan AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
