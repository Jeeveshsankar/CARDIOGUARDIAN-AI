import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/screens/emergency/emergency_screen.dart';
import 'package:flutter_application_1/screens/doctor/doctor_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/health_provider.dart';
import 'package:flutter_application_1/core/api_service.dart';
import 'package:flutter_application_1/screens/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<HealthProvider>();
      provider.refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HealthProvider>().refreshAll(),
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                const SizedBox(height: 24),
                _buildConnectionBanner(),
                const SizedBox(height: 24),
                _buildRiskOverview(),
                const SizedBox(height: 32),
                _buildSectionTitle("Quick Clinical Actions"),
                const SizedBox(height: 16),
                _buildActionGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle("Live System Stats"),
                const SizedBox(height: 16),
                _buildLiveStats(),
                const SizedBox(height: 32),
                _buildSectionTitle("Risk Distribution"),
                const SizedBox(height: 16),
                _buildRiskDistribution(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CARDIO GUARDIAN AI",
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            Text("Clinical Dashboard", style: AppTheme.darkTheme.textTheme.headlineMedium),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.read<HealthProvider>().refreshAll(),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                child: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                child: const Icon(Icons.settings_outlined, color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionBanner() {
    final provider = context.watch<HealthProvider>();
    final connected = provider.isConnected;
    
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gradientColors: [
        connected ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
        Colors.transparent,
      ],
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: connected ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (connected ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              connected ? "Backend Connected • Excel Database Active" : "Backend Offline • Check server or WiFi",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: connected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          Text(
            ApiService.baseUrl,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white38),
    );
  }

  Widget _buildRiskOverview() {
    final health = context.watch<HealthProvider>();
    final p = health.selectedPatient;
    
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      gradientColors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.transparent],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p != null ? "RISK FOR ${p['name'].toString().toUpperCase()}" : "NO ACTIVE PATIENT", 
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text("${health.riskScore}%", 
                  style: GoogleFonts.outfit(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -2)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.security, size: 14, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Text(health.riskStatus, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 75,
            height: 75,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: health.riskScore / 100, 
                  strokeWidth: 6, 
                  backgroundColor: Colors.white12, 
                  color: AppTheme.primaryColor
                ),
                Center(child: Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 28)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _actionItem("Emergency", FontAwesomeIcons.truckMedical, AppTheme.primaryColor, () {
          ApiService.logAction("NAVIGATE_EMERGENCY", "User clicked Emergency button");
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
        }),
        _actionItem("Specialists", FontAwesomeIcons.userDoctor, AppTheme.secondaryColor, () {
          ApiService.logAction("NAVIGATE_CONSULT", "User clicked Consult button");
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorScreen()));
        }),
      ],
    );
  }

  Widget _actionItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        gradientColors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        border: Border.all(color: color.withValues(alpha: 0.2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStats() {
    final stats = context.watch<HealthProvider>().dashboardStats;
    final totalPatients = stats['total_patients'] ?? 0;
    final totalVisits = stats['total_visits'] ?? 0;
    final pendingVisits = stats['pending_visits'] ?? 0;
    final totalPredictions = stats['total_predictions'] ?? 0;
    final mlStatus = stats['ml_model_status'] ?? 'Unknown';
    final excelStatus = stats['excel_status'] ?? 'Unknown';

    return Column(
      children: [
        _vitalRow("Registered Patients", "$totalPatients", Icons.people_outline, Colors.blueAccent),
        const SizedBox(height: 12),
        _vitalRow("Today's Visits", "$totalVisits ($pendingVisits pending)", Icons.calendar_today_outlined, Colors.orangeAccent),
        const SizedBox(height: 12),
        _vitalRow("ML Predictions", "$totalPredictions completed", Icons.analytics_outlined, Colors.purpleAccent),
        const SizedBox(height: 12),
        _vitalRow("ML Model", mlStatus, Icons.memory, mlStatus == 'Loaded' ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(height: 12),
        _vitalRow("Excel Database", excelStatus, Icons.storage, excelStatus == 'Connected' ? Colors.greenAccent : Colors.redAccent),
      ],
    );
  }

  Widget _buildRiskDistribution() {
    final stats = context.watch<HealthProvider>().dashboardStats;
    final riskDist = stats['risk_distribution'] as Map<String, dynamic>? ?? {};
    final high = riskDist['high'] ?? 0;
    final moderate = riskDist['moderate'] ?? 0;
    final low = riskDist['low'] ?? 0;
    final total = high + moderate + low;

    if (total == 0) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text("No predictions made yet. Analyze a patient to see risk distribution.",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _riskBar("High Risk (>70%)", high, total, Colors.redAccent),
          const SizedBox(height: 16),
          _riskBar("Moderate (30-70%)", moderate, total, Colors.orangeAccent),
          const SizedBox(height: 16),
          _riskBar("Low Risk (<30%)", low, total, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _riskBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            Text("$count patients", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          color: color,
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _vitalRow(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Flexible(
            child: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
