import 'package:flutter/material.dart';
import 'package:cardioguardian/core/api_service.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:cardioguardian/screens/startup.dart';
import 'package:cardioguardian/providers/health_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HealthProvider())],
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
      home: const StartupScreen(),
    );
  }
}
