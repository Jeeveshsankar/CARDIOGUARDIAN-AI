import 'package:flutter/material.dart';
import 'package:cardioguardian/widgets/glass_container.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cardioguardian/providers/health_provider.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HealthProvider>().fetchPatients());
  }

  void _submitForm() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid age")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await context.read<HealthProvider>().registerPatient(
      _nameController.text,
      age,
      _selectedGender,
      _contactController.text,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _nameController.clear();
        _ageController.clear();
        _contactController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Patient Registered & Saved to Excel Database"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✗ Failed to register. Check server connection."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmDeletePatient(dynamic patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Patient?", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "This will permanently remove ${patient['name']} and all their visits from the database.",
          style: GoogleFonts.outfit(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<HealthProvider>().deletePatient(patient['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? "✓ Patient deleted from database" : "✗ Delete failed"),
                  backgroundColor: ok ? Colors.green : Colors.redAccent,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("Delete", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HealthProvider>().fetchPatients(),
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REGISTRATION", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.accentColor)),
                const SizedBox(height: 8),
                Text("Patient Intake", style: AppTheme.darkTheme.textTheme.headlineMedium),
                const SizedBox(height: 32),
                _buildRegistrationForm(),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ALL REGISTERED PATIENTS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
                    Consumer<HealthProvider>(
                      builder: (_, provider, __) => Text(
                        "${provider.patients.length} total",
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPatientList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("Full Name", _nameController, Icons.person_outline),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField("Age", _ageController, Icons.calendar_today, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildGenderDropdown()),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField("Contact Number", _contactController, Icons.phone_outlined),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text("REGISTER PATIENT", 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.white38, size: 20),
              border: InputBorder.none,
              hintText: "Enter $label",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gender", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              dropdownColor: AppTheme.surfaceColor,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedGender = newValue);
              },
              items: <String>['Male', 'Female', 'Other'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientList() {
    final patients = context.watch<HealthProvider>().patients;
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.people_outline, color: Colors.white12, size: 48),
              const SizedBox(height: 12),
              Text("No patients registered yet.", style: GoogleFonts.outfit(color: Colors.white24)),
              const SizedBox(height: 4),
              Text("Register a patient above to begin.", style: GoogleFonts.outfit(color: Colors.white12, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = patients[index];
        return Dismissible(
          key: Key(p['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
          ),
          confirmDismiss: (_) async {
            _confirmDeletePatient(p);
            return false;
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                  child: Text(
                    p['name'] != null && p['name'].toString().isNotEmpty ? p['name'][0] : '?',
                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("${p['age'] ?? '?'} Yrs • ${p['gender'] ?? '?'} • ID: PAT-${p['id']}", 
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                      if (p['contact'] != null && p['contact'].toString().isNotEmpty)
                        Text("📞 ${p['contact']}", style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeletePatient(p),
                  icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                ),
                const Icon(Icons.check_circle, color: AppTheme.accentColor, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
