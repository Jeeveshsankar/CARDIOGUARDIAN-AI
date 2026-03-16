import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_service.dart';

class HealthProvider with ChangeNotifier {
  List<dynamic> _patients = [];
  List<dynamic> _visits = [];
  List<dynamic> _reports = [];
  List<dynamic> _vitals = [];
  Map<String, dynamic> _dashboardStats = {};
  Map<String, dynamic> _analyticsSummary = {};
  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic>? _pendingVitals;
  int _currentTabIndex = 0;

  double _riskScore = 0.0;
  String _riskStatus = "No Patient Selected";
  bool _isLoading = false;
  bool _isConnected = false;
  String _connectionStatus = "Checking...";

  List<dynamic> get patients => _patients;
  List<dynamic> get visits => _visits;
  List<dynamic> get reports => _reports;
  List<dynamic> get vitals => _vitals;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  Map<String, dynamic> get analyticsSummary => _analyticsSummary;
  Map<String, dynamic>? get selectedPatient => _selectedPatient;
  Map<String, dynamic>? get pendingVitals => _pendingVitals;
  int get currentTabIndex => _currentTabIndex;
  double get riskScore => _riskScore;
  String get riskStatus => _riskStatus;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    _isConnected = await ApiService.testConnection();
    _connectionStatus = _isConnected ? "Connected" : "Offline";
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchPatients(),
      fetchVisits(),
      fetchDashboardStats(),
      fetchReports(),
      checkConnection(),
    ]);
  }

  Future<void> fetchPatients() async {
    _patients = await ApiService.getPatients();
    notifyListeners();
  }

  Future<bool> registerPatient(String name, int age, String gender, String contact) async {
    final patient = await ApiService.addPatient({
      "name": name,
      "age": age,
      "gender": gender,
      "contact": contact,
    });
    if (patient != null) {
      await fetchPatients();
      await scheduleVisit(patient['id'], patient['name'], "General Checkup");
      await fetchDashboardStats();
      return true;
    }
    return false;
  }

  Future<bool> updatePatient(String patientId, Map<String, dynamic> updates) async {
    final result = await ApiService.updatePatient(patientId, updates);
    if (result != null && result['error'] == null) {
      await fetchPatients();
      await fetchDashboardStats();
      return true;
    }
    return false;
  }

  Future<bool> deletePatient(String patientId) async {
    final ok = await ApiService.deletePatient(patientId);
    if (ok) {
      if (_selectedPatient?['id'] == patientId) {
        _selectedPatient = null;
        _pendingVitals = null;
        _riskScore = 0.0;
        _riskStatus = "No Patient Selected";
      }
      await fetchPatients();
      await fetchVisits();
      await fetchDashboardStats();
    }
    return ok;
  }

  Future<void> fetchVisits() async {
    _visits = await ApiService.getVisits();
    notifyListeners();
  }

  Future<void> scheduleVisit(String pId, String pName, String purpose) async {
    await ApiService.addVisit({
      "patient_id": pId,
      "patient_name": pName,
      "purpose": purpose,
    });
    await fetchVisits();
    await fetchDashboardStats();
  }

  Future<bool> completeVisit(String visitId) async {
    final ok = await ApiService.updateVisitStatus(visitId, "Completed");
    if (ok) {
      await fetchVisits();
      await fetchDashboardStats();
    }
    return ok;
  }

  Future<bool> deleteVisit(String visitId) async {
    final ok = await ApiService.deleteVisit(visitId);
    if (ok) {
      await fetchVisits();
      await fetchDashboardStats();
    }
    return ok;
  }

  void selectPatient(Map<String, dynamic> patient) {
    _selectedPatient = patient;
    _pendingVitals = null;
    _riskScore = 0.0;
    _riskStatus = "Awaiting Vitals Entry";
    _currentTabIndex = 3;
    notifyListeners();
  }

  void selectPatientWithVitals(Map<String, dynamic> patient, Map<String, dynamic> vitals) {
    _selectedPatient = patient;
    _pendingVitals = vitals;
    _riskScore = 0.0;
    _riskStatus = "Processing...";
    _currentTabIndex = 3;
    notifyListeners();
    updateRiskPrediction();
  }

  Future<void> updateRiskPrediction() async {
    if (_selectedPatient == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> signals = _pendingVitals ?? {
        "age": _selectedPatient!['age'],
        "sex": _selectedPatient!['gender'].toString().toLowerCase() == 'male' ? 1 : 0,
        "cp": 1,
        "trestbps": 120,
        "chol": 200,
        "fbs": 0,
        "restecg": 1,
        "thalach": 150,
        "exang": 0,
        "oldpeak": 0.0,
        "slope": 1,
        "ca": 0,
        "thal": 2
      };

      final result = await ApiService.getRiskPrediction(signals);
      _riskScore = (result['risk_score'] as num).toDouble();
      _riskStatus = result['status'];
    } catch (e) {
      debugPrint("Provider Error: $e");
      _riskStatus = "Connection Error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCurrentReport() async {
    if (_selectedPatient == null) return false;

    final report = {
      "patient_id": _selectedPatient!['id'],
      "patient_name": _selectedPatient!['name'],
      "risk_score": _riskScore,
      "risk_status": _riskStatus,
      "vitals": _pendingVitals ?? {},
    };

    final result = await ApiService.saveReport(report);
    if (result != null) {
      await fetchReports();
      await fetchDashboardStats();
      return true;
    }
    return false;
  }

  Future<void> fetchReports() async {
    _reports = await ApiService.getReports();
    notifyListeners();
  }

  Future<bool> logVital(String type, String value, String unit, {String? patientId, String? patientName}) async {
    final result = await ApiService.logVitalEntry({
      "patient_id": patientId ?? _selectedPatient?['id'] ?? "",
      "patient_name": patientName ?? _selectedPatient?['name'] ?? "General",
      "type": type,
      "value": value,
      "unit": unit,
    });
    if (result != null) {
      await fetchVitals();
      return true;
    }
    return false;
  }

  Future<void> fetchVitals() async {
    _vitals = await ApiService.getVitals();
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _dashboardStats = await ApiService.getDashboardStats();
    notifyListeners();
  }

  Future<void> fetchAnalytics() async {
    _analyticsSummary = await ApiService.getAnalyticsSummary();
    notifyListeners();
  }
}
