import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/glass_container.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/core/api_service.dart';

class DoctorScreen extends StatelessWidget {
  const DoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("SPECIALISTS", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearch(),
            const SizedBox(height: 32),
            _buildSectionTitle("Available Cardiologists"),
            const SizedBox(height: 16),
            _buildDoctorList(),
            const SizedBox(height: 32),
            _buildSectionTitle("Your Appointments"),
            const SizedBox(height: 16),
            _buildAppointmentCard(),
            const SizedBox(height: 40),
          ],
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

  Widget _buildSearch() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      radius: 15,
      child: TextField(
        onSubmitted: (val) {
          ApiService.logAction("DOCTOR_SEARCH", "User searched for: $val");
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: "Search cardiologists...",
          hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.white38, size: 20),
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doctors = [
          {"name": "Dr. Sarah Wilson", "role": "Cardiologist", "img": "SW"},
          {"name": "Dr. Mark Rutter", "role": "Heart Surgeon", "img": "MR"},
        ];
        return _doctorItem(doctors[index]["name"]!, doctors[index]["role"]!, doctors[index]["img"]!);
      },
    );
  }

  Widget _doctorItem(String name, String role, String initials) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
            child: Text(initials, style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                Text(role, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ApiService.logAction("VIDEO_CALL_CLICK", "User initiated video call with $name");
            },
            icon: const Icon(Icons.video_call_outlined, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return GlassContainer(
      gradientColors: [AppTheme.secondaryColor.withValues(alpha: 0.1), Colors.transparent],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calendar_month, color: AppTheme.secondaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Session with Dr. Wilson", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Tomorrow • 09:30 AM", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white12)),
                  child: const Text("Reschedule", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ApiService.logAction("APPOINTMENT_CONFIRM", "User confirmed session with Dr. Wilson");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text("Confirm Session", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
