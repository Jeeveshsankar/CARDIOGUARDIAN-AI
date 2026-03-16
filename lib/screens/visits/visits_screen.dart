import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/health_provider.dart';
import 'package:flutter_application_1/core/api_service.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HealthProvider>().fetchVisits();
      context.read<HealthProvider>().fetchPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<HealthProvider>().visits;
    final patients = context.watch<HealthProvider>().patients;

    final pendingVisits = visits.where((v) => v['status'] != 'Completed').toList();
    final completedVisits = visits.where((v) => v['status'] == 'Completed').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<HealthProvider>().fetchVisits();
            await context.read<HealthProvider>().fetchPatients();
          },
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TODAY'S APPOINTMENTS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Clinical Queue", style: AppTheme.darkTheme.textTheme.headlineMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${pendingVisits.length} pending",
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Pending visits
                if (pendingVisits.isEmpty && completedVisits.isEmpty)
                  _buildEmptyState()
                else ...[
                  if (pendingVisits.isNotEmpty) ...[
                    Text("PENDING", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.orangeAccent)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingVisits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final v = pendingVisits[index];
                        final p = patients.firstWhere(
                          (element) => element['id'] == v['patient_id'],
                          orElse: () => null,
                        );
                        return _buildVisitCard(v, p, isPending: true);
                      },
                    ),
                  ],
                  if (completedVisits.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text("COMPLETED", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.greenAccent)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedVisits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = completedVisits[index];
                        final p = patients.firstWhere(
                          (element) => element['id'] == v['patient_id'],
                          orElse: () => null,
                        );
                        return _buildVisitCard(v, p, isPending: false);
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.event_note_outlined, color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text("No patients scheduled yet.", style: GoogleFonts.outfit(color: Colors.white24)),
            const SizedBox(height: 8),
            Text("Register a patient in the 'Patients' tab to begin.", style: GoogleFonts.outfit(color: Colors.white12, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(dynamic v, dynamic p, {required bool isPending}) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      gradientColors: isPending 
        ? null 
        : [Colors.greenAccent.withValues(alpha: 0.05), Colors.transparent],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (isPending ? AppTheme.primaryColor : Colors.greenAccent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isPending ? Icons.medical_services_outlined : Icons.check_circle_outline,
                  color: isPending ? AppTheme.primaryColor : Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['patient_name'] ?? 'Unknown',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Text(v['purpose'] ?? 'General', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
                    if (p != null)
                      Text("${p['age']} Yrs • ${p['gender']}",
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isPending ? Icons.pending_actions : Icons.check_circle,
                    color: isPending ? Colors.orangeAccent : Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPending ? "Pending" : "Done",
                    style: GoogleFonts.outfit(fontSize: 9, color: isPending ? Colors.orangeAccent : Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        if (p != null) {
                          _showVitalsDialog(context, p);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Patient data not found. Please re-register.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text("ENTER VITALS & DIAGNOSE",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await context.read<HealthProvider>().completeVisit(v['id']);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? "✓ Visit marked as completed" : "✗ Failed to update"),
                          backgroundColor: ok ? Colors.green : Colors.redAccent,
                        ));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showVitalsDialog(BuildContext context, dynamic patient) {
    final formKey = GlobalKey<FormState>();
    final bpController = TextEditingController(text: "120");
    final cholController = TextEditingController(text: "200");
    final hrController = TextEditingController(text: "150");
    final oldpeakController = TextEditingController(text: "0.0");
    int cp = 1;
    int exang = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text("CLINICAL VITALS INTAKE",
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryColor)),
                      const SizedBox(height: 8),
                      Text(patient['name'],
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("${patient['age']} Yrs • ${patient['gender']}",
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
                      const SizedBox(height: 24),
                      
                      // Systolic BP
                      _dialogField("Systolic BP (mmHg)", bpController, "e.g. 130"),
                      const SizedBox(height: 16),
                      _dialogField("Serum Cholesterol (mg/dL)", cholController, "e.g. 240"),
                      const SizedBox(height: 16),
                      _dialogField("Max Heart Rate (bpm)", hrController, "e.g. 155"),
                      const SizedBox(height: 16),
                      _dialogField("ST Depression (oldpeak)", oldpeakController, "e.g. 1.5", isDecimal: true),
                      const SizedBox(height: 20),

                      // Chest Pain Type
                      Text("Chest Pain Type", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _chip("None", cp == 0, () => setDialogState(() => cp = 0)),
                          _chip("Mild", cp == 1, () => setDialogState(() => cp = 1)),
                          _chip("Moderate", cp == 2, () => setDialogState(() => cp = 2)),
                          _chip("Severe", cp == 3, () => setDialogState(() => cp = 3)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Exercise-induced angina
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Exercise-Induced Angina",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
                          Switch(
                            value: exang == 1,
                            onChanged: (val) => setDialogState(() => exang = val ? 1 : 0),
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      
                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            final vitals = {
                              "age": patient['age'],
                              "sex": patient['gender'].toString().toLowerCase() == 'male' ? 1 : 0,
                              "cp": cp,
                              "trestbps": int.tryParse(bpController.text) ?? 120,
                              "chol": int.tryParse(cholController.text) ?? 200,
                              "fbs": 0,
                              "restecg": 1,
                              "thalach": int.tryParse(hrController.text) ?? 150,
                              "exang": exang,
                              "oldpeak": double.tryParse(oldpeakController.text) ?? 0.0,
                              "slope": 1,
                              "ca": 0,
                              "thal": 2,
                            };
                            ApiService.logAction("VITALS_SUBMITTED", "Vitals entered for ${patient['name']}: BP=${bpController.text}, Chol=${cholController.text}");
                            context.read<HealthProvider>().selectPatientWithVitals(patient, vitals);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text("RUN ML DIAGNOSIS",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogField(String label, TextEditingController controller, String hint, {bool isDecimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.white12),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: selected ? Colors.white : Colors.white38, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
