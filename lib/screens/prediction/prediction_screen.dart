import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/health_provider.dart';
import 'package:flutter_application_1/core/api_service.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final p = provider.selectedPatient;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ML DIAGNOSTICS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              Text("Predictive Analysis", style: AppTheme.darkTheme.textTheme.headlineMedium),
              const SizedBox(height: 32),
              
              if (p == null)
                _buildNoneSelectedState()
              else ...[
                _buildPatientInfo(p, provider.pendingVitals),
                const SizedBox(height: 24),
                _buildRiskHub(context, provider),
                const SizedBox(height: 32),
                _buildSectionTitle("Clinical Input Data"),
                const SizedBox(height: 16),
                _buildVitalsUsed(provider.pendingVitals, p),
                const SizedBox(height: 32),
                _buildSectionTitle("AI Feature Impact"),
                const SizedBox(height: 16),
                _buildImpactList(provider.pendingVitals),
                const SizedBox(height: 30),
                _buildSaveAction(context, provider),
                const SizedBox(height: 16),
                _buildReportsSection(context, provider),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white38),
    );
  }

  Widget _buildNoneSelectedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            const Icon(Icons.biotech_outlined, color: Colors.white12, size: 80),
            const SizedBox(height: 24),
            Text("No patient selected for analysis.", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Go to 'Visits' tab and click 'Enter Vitals & Diagnose'", style: GoogleFonts.outfit(color: Colors.white10, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> p, Map<String, dynamic>? vitals) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gradientColors: [AppTheme.accentColor.withValues(alpha: 0.1), Colors.transparent],
      child: Row(
        children: [
          Icon(Icons.person, color: AppTheme.accentColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'].toString().toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                Text("${p['age']} Yrs • ${p['gender']} • ID: PAT-${p['id']}", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                if (vitals != null)
                  Text("BP: ${vitals['trestbps']}mmHg • Chol: ${vitals['chol']}mg/dL • HR: ${vitals['thalach']}bpm",
                    style: GoogleFonts.outfit(color: AppTheme.accentColor.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskHub(BuildContext context, HealthProvider provider) {
    Color riskColor = AppTheme.primaryColor;
    if (provider.riskScore <= 30) {
      riskColor = Colors.greenAccent;
    } else if (provider.riskScore <= 70) {
      riskColor = Colors.orangeAccent;
    } else {
      riskColor = Colors.redAccent;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.isConnected ? "Cloud AI Risk Score" : "Local Engine Risk Score", 
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text("${provider.riskScore}%", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (!provider.isConnected)
                    Text("Offline Prediction Mode", style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Text(provider.riskStatus, style: GoogleFonts.outfit(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Risk progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.riskScore / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: riskColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () {
                ApiService.logAction("ML_RECALCULATE_CLICK", "User triggered new risk analysis for ${provider.selectedPatient?['name']}");
                provider.updateRiskPrediction();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.05), elevation: 0),
              child: provider.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text("RUN AI DIAGNOSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsUsed(Map<String, dynamic>? vitals, Map<String, dynamic> p) {
    if (vitals == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Text(
          "No vitals entered. Go to the Visits tab and tap 'Enter Vitals & Diagnose'.",
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _vitalDataRow("Systolic BP", "${vitals['trestbps']} mmHg"),
          _divider(),
          _vitalDataRow("Cholesterol", "${vitals['chol']} mg/dL"),
          _divider(),
          _vitalDataRow("Max Heart Rate", "${vitals['thalach']} bpm"),
          _divider(),
          _vitalDataRow("ST Depression", "${vitals['oldpeak']}"),
          _divider(),
          _vitalDataRow("Exercise Angina", vitals['exang'] == 1 ? "Yes" : "No"),
          _divider(),
          _vitalDataRow("Chest Pain", ["None", "Mild", "Moderate", "Severe"][vitals['cp'] ?? 1]),
        ],
      ),
    );
  }

  Widget _vitalDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildImpactList(Map<String, dynamic>? vitals) {
    final bp = (vitals?['trestbps'] as int?) ?? 120;
    final chol = (vitals?['chol'] as int?) ?? 200;
    final hr = (vitals?['thalach'] as int?) ?? 150;

    final bpWeight = (bp / 200.0).clamp(0.0, 1.0);
    final cholWeight = (chol / 400.0).clamp(0.0, 1.0);
    final hrWeight = (1.0 - hr / 202.0).clamp(0.0, 1.0);

    return GlassContainer(
      child: Column(
        children: [
          _impactRow("Systolic BP ($bp mmHg)", bpWeight, Colors.redAccent),
          _divider(),
          _impactRow("Cholesterol ($chol mg/dL)", cholWeight, Colors.orangeAccent),
          _divider(),
          _impactRow("Heart Rate Risk Factor", hrWeight, Colors.blueAccent),
        ],
      ),
    );
  }


  Widget _divider() => Container(height: 1, color: Colors.white.withValues(alpha: 0.05));

  Widget _impactRow(String label, double weight, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))),
              Text("${(weight * 100).toInt()}%", style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: weight,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveAction(BuildContext context, HealthProvider provider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (provider.selectedPatient != null && provider.riskScore > 0) {
              final saved = await provider.saveCurrentReport();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    saved 
                      ? "✓ ML Report saved to Excel database for ${provider.selectedPatient?['name']}" 
                      : "✗ Failed to save report. Check server.",
                  ),
                  backgroundColor: saved ? Colors.green : Colors.redAccent,
                ));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Run a diagnosis first before saving the report."),
              ));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_alt, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  "SAVE REPORT TO EXCEL",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context, HealthProvider provider) {
    final reports = provider.reports.where(
      (r) => r['patient_id'] == provider.selectedPatient?['id']
    ).toList();

    if (reports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionTitle("Previous Reports for this Patient"),
        const SizedBox(height: 12),
        ...reports.reversed.take(5).map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassContainer(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: AppTheme.accentColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Risk: ${r['risk_score']}% — ${r['risk_status']}", 
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(r['timestamp'] ?? '', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
