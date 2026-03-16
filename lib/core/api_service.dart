import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrl = 'http://127.0.0.1:8000';

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost') {
        _baseUrl = 'http://$host:8000';
      } else {
        _baseUrl = 'http://127.0.0.1:8000';
      }
    }
    
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
    debugPrint('ApiService initialized with: $_baseUrl');
  }

  static Future<void> setServerUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _baseUrl);
    debugPrint('Server URL updated to: $_baseUrl');
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/dashboard/stats')).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
      return {};
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
      return {};
    }
  }

  static Future<List<dynamic>> getPatients() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/patients')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> addPatient(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/patients/add'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> updatePatient(String patientId, Map<String, dynamic> data) async {
    try {
      final r = await http.put(Uri.parse('$_baseUrl/patients/$patientId'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : null;
    } catch (_) { return null; }
  }

  static Future<bool> deletePatient(String patientId) async {
    try {
      final r = await http.delete(Uri.parse('$_baseUrl/patients/$patientId')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<List<dynamic>> getVisits() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/visits')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> addVisit(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/visits/add'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : null;
    } catch (_) { return null; }
  }

  static Future<bool> updateVisitStatus(String visitId, String status) async {
    try {
      final r = await http.put(Uri.parse('$_baseUrl/visits/$visitId/status?status=$status')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<bool> deleteVisit(String visitId) async {
    try {
      final r = await http.delete(Uri.parse('$_baseUrl/visits/$visitId')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  static Future<Map<String, dynamic>> getRiskPrediction(Map<String, dynamic> signals) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/predict'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(signals)).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 ? jsonDecode(r.body) : {"risk_score": 0.0, "status": "Error"};
    } catch (_) { return {"risk_score": 0.0, "status": "Offline"}; }
  }

  static Future<Map<String, dynamic>?> saveReport(Map<String, dynamic> report) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/reports/save'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(report)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : null;
    } catch (e) {
      debugPrint('Save report error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getReports() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/reports')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) { return []; }
  }

  static Future<List<dynamic>> getPatientReports(String patientId) async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/reports/patient/$patientId')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) { return []; }
  }

  static Future<Map<String, dynamic>?> logVitalEntry(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/vitals/log'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : null;
    } catch (_) { return null; }
  }

  static Future<List<dynamic>> getVitals() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/vitals')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : [];
    } catch (_) { return []; }
  }

  static Future<String> getAssistantResponse(String message) async {
    try {
      final r = await http.post(Uri.parse('$_baseUrl/assistant/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message})).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 ? jsonDecode(r.body)['reply'] : "Service unavailable.";
    } catch (_) { return "Connection error. Check server."; }
  }

  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/analytics/summary')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : {};
    } catch (_) { return {}; }
  }

  static Future<void> logAction(String actionName, String details) async {
    try {
      await http.post(Uri.parse('$_baseUrl/log/action'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'action_name': actionName, 'details': details})).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<void> logVital(Map<String, dynamic> data) async {
    try {
      await http.post(Uri.parse('$_baseUrl/log/vital'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getExcelData() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/excel/data')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200 ? jsonDecode(r.body) : {"rows": [], "count": 0};
    } catch (_) { return {"rows": [], "count": 0}; }
  }
}
