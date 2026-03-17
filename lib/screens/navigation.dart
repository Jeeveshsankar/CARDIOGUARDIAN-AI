import 'package:flutter/material.dart';
import 'package:cardioguardian/screens/dashboard/dashboard.dart';
import 'package:cardioguardian/screens/patients/patients.dart';
import 'package:cardioguardian/screens/visits/visits.dart';
import 'package:cardioguardian/screens/prediction/prediction.dart';
import 'package:cardioguardian/screens/assistant/assistant.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cardioguardian/providers/health_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const PatientsScreen(),
    const VisitsScreen(),
    const PredictionScreen(),
    const AssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = context.watch<HealthProvider>().currentTabIndex;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.8),
                radius: 1.5,
                colors: [Color(0xFF1A1A1A), Color(0xFF010101)],
              ),
            ),
          ),

          IndexedStack(
            index: currentTabIndex,
            children: _screens,
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, FontAwesomeIcons.house, "Home"),
                    _navItem(1, FontAwesomeIcons.users, "Patients"),
                    _navItem(2, FontAwesomeIcons.calendarCheck, "Visits"),
                    _navItem(3, FontAwesomeIcons.brain, "ML Model"),
                    _navItem(4, FontAwesomeIcons.message, "AI Chat"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final provider = context.read<HealthProvider>();
    bool isSelected = provider.currentTabIndex == index;
    return GestureDetector(
      onTap: () => provider.setTabIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.primaryColor : Colors.white38,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}


