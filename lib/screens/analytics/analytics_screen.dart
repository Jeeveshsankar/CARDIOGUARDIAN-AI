import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/health_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HealthProvider>().fetchAnalytics();
      context.read<HealthProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<HealthProvider>().fetchAnalytics();
            await context.read<HealthProvider>().fetchReports();
          },
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
                _buildOverviewCards(),
                const SizedBox(height: 32),
                _buildSectionTitle("Risk Score Timeline"),
                const SizedBox(height: 16),
                _buildRiskTimeline(),
                const SizedBox(height: 32),
                _buildSectionTitle("Gender Distribution"),
                const SizedBox(height: 16),
                _buildGenderChart(),
                const SizedBox(height: 32),
                _buildSectionTitle("Age Distribution"),
                const SizedBox(height: 16),
                _buildAgeDistribution(),
                const SizedBox(height: 32),
                _buildSectionTitle("Vital Averages"),
                const SizedBox(height: 16),
                _buildVitalAverages(),
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
          "ANALYTICS",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Live Insights",
              style: AppTheme.darkTheme.textTheme.headlineMedium,
            ),
            GestureDetector(
              onTap: () {
                context.read<HealthProvider>().fetchAnalytics();
                context.read<HealthProvider>().fetchReports();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: AppTheme.primaryColor, size: 14),
                    const SizedBox(width: 6),
                    Text("Refresh", style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _buildOverviewCards() {
    final analytics = context.watch<HealthProvider>().analyticsSummary;
    final totalPatients = analytics['total_patients'] ?? 0;
    final totalAnalyzed = analytics['total_analyzed'] ?? 0;
    final avgRisk = analytics['average_risk_score'] ?? 0.0;

    return Row(
      children: [
        Expanded(child: _statCard("Patients", "$totalPatients", Colors.blueAccent)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Analyzed", "$totalAnalyzed", AppTheme.accentColor)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Avg Risk", "$avgRisk%", Colors.orangeAccent)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      gradientColors: [color.withValues(alpha: 0.1), Colors.transparent],
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRiskTimeline() {
    final analytics = context.watch<HealthProvider>().analyticsSummary;
    final riskTimeline = (analytics['risk_timeline'] as List<dynamic>?) ?? [];

    if (riskTimeline.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text("No predictions yet. Analyze patients to see risk trends.",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < riskTimeline.length; i++) {
      final score = (riskTimeline[i]['risk_score'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), score));
    }

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Risk Scores Over Patients", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("${riskTimeline.length} analyses completed", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: spots.length <= 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChart() {
    final analytics = context.watch<HealthProvider>().analyticsSummary;
    final genderDist = (analytics['gender_distribution'] as Map<String, dynamic>?) ?? {};
    final males = (genderDist['male'] ?? 0) as int;
    final females = (genderDist['female'] ?? 0) as int;
    final others = (genderDist['other'] ?? 0) as int;
    final total = males + females + others;

    if (total == 0) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text("No patient data yet.", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Patient Gender Breakdown", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 6,
                centerSpaceRadius: 35,
                sections: [
                  if (males > 0)
                    PieChartSectionData(value: males.toDouble(), title: 'Male\n$males', color: Colors.blueAccent, radius: 45, titleStyle: _chartStyle()),
                  if (females > 0)
                    PieChartSectionData(value: females.toDouble(), title: 'Female\n$females', color: Colors.pinkAccent, radius: 45, titleStyle: _chartStyle()),
                  if (others > 0)
                    PieChartSectionData(value: others.toDouble(), title: 'Other\n$others', color: Colors.tealAccent, radius: 45, titleStyle: _chartStyle()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDistribution() {
    final analytics = context.watch<HealthProvider>().analyticsSummary;
    final ageDist = (analytics['age_distribution'] as Map<String, dynamic>?) ?? {};

    if (ageDist.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text("No patient data yet.", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
        ),
      );
    }

    final colors = [Colors.blueAccent, Colors.tealAccent, Colors.greenAccent, Colors.orangeAccent, Colors.redAccent, Colors.purpleAccent];
    int i = 0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Age Groups", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          ...ageDist.entries.map((e) {
            final color = colors[i % colors.length];
            i++;
            final count = (e.value as int?) ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text(e.key, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: count > 0 ? count / (ageDist.values.fold<int>(0, (s, v) => s + ((v as int?) ?? 0))).clamp(1, 999) : 0,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: color,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("$count", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVitalAverages() {
    final analytics = context.watch<HealthProvider>().analyticsSummary;
    final vitalAvg = (analytics['vital_averages'] as Map<String, dynamic>?) ?? {};
    final bp = vitalAvg['bp'] ?? 0;
    final chol = vitalAvg['cholesterol'] ?? 0;
    final hr = vitalAvg['heart_rate'] ?? 0;

    if (bp == 0 && chol == 0 && hr == 0) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text("Run ML analyses to see vital averages.", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _vitalAvgRow("Avg Blood Pressure", "$bp mmHg", Icons.monitor_heart, Colors.redAccent),
          const SizedBox(height: 16),
          _vitalAvgRow("Avg Cholesterol", "$chol mg/dL", Icons.science, Colors.orangeAccent),
          const SizedBox(height: 16),
          _vitalAvgRow("Avg Heart Rate", "$hr bpm", Icons.favorite, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _vitalAvgRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
        ),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  TextStyle _chartStyle() => GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white);
}
