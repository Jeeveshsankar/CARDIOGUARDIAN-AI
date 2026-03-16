import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_service.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/screens/splash_screen.dart';
import 'package:flutter_application_1/providers/health_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: const CardioGuardianApp(),
    ),
  );
}

class CardioGuardianApp extends StatelessWidget {
  const CardioGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CardioGuardian AI',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
