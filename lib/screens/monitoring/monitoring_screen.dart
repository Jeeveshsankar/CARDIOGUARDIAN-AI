import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/health_provider.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HealthProvider>().fetchVitals());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HealthProvider>().fetchVitals(),
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSectionTitle("Real-time Diagnostics"),
                const SizedBox(height: 16),
                _buildLiveECGTracker(),
                const SizedBox(height: 32),
                _buildSectionTitle("Log Patient Vitals"),
                const SizedBox(height: 16),
                _buildLogGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle("Recent Vital Entries"),
                const SizedBox(height: 16),
                _buildRecentVitals(),
                const SizedBox(height: 32),
                _buildSectionTitle("Device Connectivity"),
                const SizedBox(height: 16),
                _buildWearableSyncStatus(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MONITORING",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Clinical Vitals",
          style: AppTheme.darkTheme.textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildLiveECGTracker() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ECG Waveform",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Lead II Configuration",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              _liveTag(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(painter: ECGPainter()),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricSmall("PR", "160ms"),
              _metricSmall("QRS", "90ms"),
              _metricSmall("QTc", "410ms"),
              _metricSmall("ST", "Normal"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text("LIVE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _metricSmall(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildLogGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _logBtn("Log BP", Icons.monitor_heart, Colors.blue, "Blood Pressure", "mmHg"),
        _logBtn("Log Weight", Icons.scale, Colors.orange, "Weight", "kg"),
        _logBtn("Log Meal", Icons.restaurant, Colors.green, "Meal", "cal"),
        _logBtn("Log Labs", Icons.science, Colors.purple, "Lab Result", "units"),
      ],
    );
  }

  Widget _logBtn(String label, IconData icon, Color color, String logType, String unit) {
    return GestureDetector(
      onTap: () => _showVitalLogDialog(logType, unit),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showVitalLogDialog(String type, String defaultUnit) {
    final valueController = TextEditingController();
    final unitController = TextEditingController(text: defaultUnit);
    final provider = context.read<HealthProvider>();
    final selectedPatient = provider.selectedPatient;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Log $type", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedPatient != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text("Patient: ${selectedPatient['name']}", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontSize: 13)),
              ),
            Text("Value", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Enter $type value",
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(height: 16),
            Text("Unit", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: unitController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (valueController.text.isEmpty) return;
              Navigator.pop(ctx);
              
              final ok = await provider.logVital(
                type,
                valueController.text,
                unitController.text,
                patientId: selectedPatient?['id'],
                patientName: selectedPatient?['name'],
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? "✓ $type logged to Excel database" : "✗ Failed to log vital"),
                  backgroundColor: ok ? Colors.green : Colors.redAccent,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text("SAVE TO EXCEL", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVitals() {
    final vitals = context.watch<HealthProvider>().vitals;
    
    if (vitals.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text("No vitals logged yet. Tap a button above to start logging.",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final recentVitals = vitals.reversed.take(10).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentVitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final v = recentVitals[index];
        return GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getVitalIcon(v['type']?.toString() ?? ''),
                  color: AppTheme.accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['type']?.toString() ?? 'Unknown', 
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    if (v['patient_name'] != null && v['patient_name'].toString().isNotEmpty)
                      Text(v['patient_name'].toString(), 
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${v['value'] ?? '?'} ${v['unit'] ?? ''}", 
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(v['timestamp']?.toString() ?? '', 
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getVitalIcon(String type) {
    switch (type.toLowerCase()) {
      case 'blood pressure': return Icons.monitor_heart;
      case 'weight': return Icons.scale;
      case 'meal': return Icons.restaurant;
      case 'lab result': return Icons.science;
      default: return Icons.medical_services;
    }
  }

  Widget _buildWearableSyncStatus() {
    final connected = context.watch<HealthProvider>().isConnected;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppTheme.accentColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Excel Database", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  connected ? "All vitals synced to health_database.xlsx" : "Backend offline — logs queued locally",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
          Icon(connected ? Icons.check_circle : Icons.error_outline, 
            color: connected ? AppTheme.accentColor : Colors.redAccent, size: 20),
        ],
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    
    double x = 0;
    while (x < size.width) {
      path.lineTo(x + 15, size.height * 0.5);
      path.lineTo(x + 20, size.height * 0.45);
      path.lineTo(x + 25, size.height * 0.55);
      path.lineTo(x + 30, size.height * 0.1);
      path.lineTo(x + 35, size.height * 0.9);
      path.lineTo(x + 40, size.height * 0.5);
      path.lineTo(x + 50, size.height * 0.4);
      path.lineTo(x + 60, size.height * 0.5);
      path.lineTo(x + 80, size.height * 0.5);
      x += 80;
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
