import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/api_service.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("EMERGENCY CORE", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSOSButton(),
            const SizedBox(height: 48),
            _buildSectionTitle("Immediate Actions"),
            const SizedBox(height: 16),
            _buildEmergencyGrid(),
            const SizedBox(height: 32),
            _buildSectionTitle("Nearest Critical Care"),
            const SizedBox(height: 16),
            _buildHospitalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white38),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
          ),
          child: GestureDetector(
            onLongPress: () {
              ApiService.logAction("SOS_TRIGGERED", "User initiated long press on SOS button");
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFF5E7E), AppTheme.primaryColor],
                ),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5),
                ],
              ),
              child: const Center(
                child: Text(
                  "SOS",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Hold for 3 seconds to initiate\nemergency sequence",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white54, height: 1.5, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmergencyGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _sosAction("Ambulance", Icons.emergency, Colors.redAccent),
        _sosAction("Hospital", Icons.local_hospital, Colors.orangeAccent),
        _sosAction("Family", Icons.favorite, Colors.blueAccent),
        _sosAction("Medical ID", Icons.badge, Colors.tealAccent),
      ],
    );
  }

  Widget _sosAction(String label, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      gradientColors: [color.withValues(alpha: 0.1), Colors.transparent],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHospitalCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.map, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("St. Mary's Cardiac", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                Text("0.8 mi • Emergency Open", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ApiService.logAction("HOSPITAL_NAVIGATION", "User clicked navigation to St. Mary's Cardiac");
            }, 
            icon: const Icon(Icons.navigation, color: AppTheme.primaryColor)
          ),
        ],
      ),
    );
  }
}
