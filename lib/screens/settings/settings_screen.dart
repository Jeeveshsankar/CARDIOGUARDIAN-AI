import 'package:flutter/material.dart';
import 'package:cardioguardian/core/api_service.dart';
import 'package:cardioguardian/widgets/glass_container.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _controller = TextEditingController();
  bool _testing = false;
  String _status = '';
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ApiService.baseUrl;
    _test();
  }

  Future<void> _test() async {
    setState(() { _testing = true; _status = 'Testing...'; });
    final ok = await ApiService.testConnection();
    setState(() {
      _testing = false;
      _connected = ok;
      _status = ok ? '✓ Connected to backend' : '✗ Cannot reach server. Check IP & backend.';
    });
  }

  Future<void> _save() async {
    await ApiService.setServerUrl(_controller.text);
    await _test();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server URL saved!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("SERVER SETTINGS", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(20),
              gradientColors: [_connected ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1), Colors.transparent],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: _connected ? Colors.greenAccent : Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(_testing ? 'Testing...' : _status,
                          style: GoogleFonts.outfit(
                            color: _connected ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text("Backend Server IP", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "http://192.168.1.X:8000",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text("Enter the IP shown when you run start_server.bat on the host PC.",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _test,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text("TEST", style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("SAVE & RECONNECT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HOW TO GET THE IP", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.accentColor)),
                  const SizedBox(height: 12),
                  _step("1", "On the host PC, double-click  backend/start_server.bat"),
                  _step("2", "It will print:  Network URL: http://192.168.X.X:8000"),
                  _step("3", "Enter that URL here and tap SAVE & RECONNECT"),
                  _step("4", "Make sure phone & PC are on the same WiFi"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Text(num, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13))),
        ],
      ),
    );
  }
}
