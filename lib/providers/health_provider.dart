import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cardioguardian/core/api_service.dart';
import 'package:cardioguardian/core/local_database.dart';
import 'package:cardioguardian/core/local_predictor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;

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
  bool get isOnline => _isOnline;
  String get connectionStatus => _connectionStatus;

  HealthProvider() {
    _initConnectivity();
    refreshAll();
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((result) {
      _updateConnectionStatus(result);
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    checkConnection();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

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
    // Hybrid Fetch
    final remotePatients = await ApiService.getPatients();
    if (remotePatients.isNotEmpty) {
      _patients = remotePatients;
      for (var p in remotePatients) {
        await LocalDatabase.savePatient(p);
      }
    } else {
      _patients = await LocalDatabase.getPatients();
    }
    notifyListeners();
  }

  Future<bool> registerPatient(String name, int age, String gender, String contact) async {
    final Map<String, dynamic> data = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "age": age,
      "gender": gender,
      "contact": contact,
    };

    // 1. Save locally immediately (Offline Support)
    await LocalDatabase.savePatient(data);
    
    // 2. Try Remote
    final patient = await ApiService.addPatient(data);
    
    // Refresh UI
    await fetchPatients();
    if (patient != null) {
      await scheduleVisit(patient['id'], patient['name'], "General Checkup");
    } else {
      await scheduleVisit(data['id'], data['name'], "General Checkup (Offline)");
    }
    await fetchDashboardStats();
    return true;
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
    await LocalDatabase.deletePatient(patientId);
    final ok = await ApiService.deletePatient(patientId);
    
    if (_selectedPatient?['id'] == patientId) {
      _selectedPatient = null;
      _pendingVitals = null;
      _riskScore = 0.0;
      _riskStatus = "No Patient Selected";
    }
    await fetchPatients();
    await fetchVisits();
    await fetchDashboardStats();
    return true; // Always return true because it was deleted locally
  }

  Future<void> fetchVisits() async {
    final remoteVisits = await ApiService.getVisits();
    if (remoteVisits.isNotEmpty) {
      _visits = remoteVisits;
      for (var v in remoteVisits) {
        await LocalDatabase.saveVisit(v);
      }
    } else {
      _visits = await LocalDatabase.getVisits();
    }
    notifyListeners();
  }

  Future<void> scheduleVisit(String pId, String pName, String purpose) async {
    final visit = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "patient_id": pId,
      "patient_name": pName,
      "purpose": purpose,
      "status": "Pending",
    };
    
    await LocalDatabase.saveVisit(visit);
    await ApiService.addVisit(visit);
    
    await fetchVisits();
    await fetchDashboardStats();
  }

  Future<bool> completeVisit(String visitId) async {
    await LocalDatabase.updateVisitStatus(visitId, "Completed");
    await ApiService.updateVisitStatus(visitId, "Completed");
    await fetchVisits();
    await fetchDashboardStats();
    return true;
  }

  Future<bool> deleteVisit(String visitId) async {
    await LocalDatabase.deleteVisit(visitId);
    await ApiService.deleteVisit(visitId);
    await fetchVisits();
    await fetchDashboardStats();
    return true;
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

      if (_isConnected) {
        final result = await ApiService.getRiskPrediction(signals);
        _riskScore = (result['risk_score'] as num).toDouble();
        _riskStatus = result['status'];
      } else {
        // Use Local Predictor when offline
        final result = LocalPredictor.predictHeartRisk(signals);
        _riskScore = result['risk_score'];
        _riskStatus = result['status'];
      }
    } catch (e) {
      debugPrint("Provider Prediction Error: $e");
      // Fallback to local on error
      final result = LocalPredictor.predictHeartRisk(_pendingVitals ?? {});
      _riskScore = result['risk_score'];
      _riskStatus = result['status'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCurrentReport() async {
    if (_selectedPatient == null) return false;

    final report = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "patient_id": _selectedPatient!['id'],
      "patient_name": _selectedPatient!['name'],
      "risk_score": _riskScore,
      "risk_status": _riskStatus,
      "vitals": _pendingVitals ?? {},
      "timestamp": DateTime.now().toString(),
    };

    // Save locally
    await LocalDatabase.saveReport(report);
    
    // Save remotely
    await ApiService.saveReport(report);
    
    await fetchReports();
    await fetchDashboardStats();
    return true;
  }

  Future<void> fetchReports() async {
    final remoteReports = await ApiService.getReports();
    if (remoteReports.isNotEmpty) {
      _reports = remoteReports;
      for (var r in remoteReports) {
        await LocalDatabase.saveReport(r);
      }
    } else {
      _reports = await LocalDatabase.getReports();
    }
    notifyListeners();
  }

  Future<bool> logVital(String type, String value, String unit, {String? patientId, String? patientName}) async {
    final vital = {
      "patient_id": patientId ?? _selectedPatient?['id'] ?? "",
      "patient_name": patientName ?? _selectedPatient?['name'] ?? "General",
      "type": type,
      "value": value,
      "unit": unit,
      "timestamp": DateTime.now().toString(),
    };

    await LocalDatabase.saveVital(vital);
    await ApiService.logVitalEntry(vital);
    
    await fetchVitals();
    return true;
  }

  Future<void> fetchVitals() async {
    final remoteVitals = await ApiService.getVitals();
    if (remoteVitals.isNotEmpty) {
      _vitals = remoteVitals;
      for (var v in remoteVitals) {
        await LocalDatabase.saveVital(v);
      }
    } else {
      _vitals = await LocalDatabase.getVitals();
    }
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    final result = await ApiService.getDashboardStats();
    if (result.isNotEmpty) {
      _dashboardStats = result;
    } else {
      // Build local stats if offline
      _dashboardStats = {
        "total_patients": _patients.length,
        "total_visits": _visits.length,
        "total_reports": _reports.length,
        "server_status": "Offline (Local Engine)",
        "mode": "Local"
      };
    }
    notifyListeners();
  }

  Future<void> fetchAnalytics() async {
    _analyticsSummary = await ApiService.getAnalyticsSummary();
    notifyListeners();
  }
}
