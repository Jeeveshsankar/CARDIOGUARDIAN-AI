import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static Database? _database;
  static const String dbName = 'cardioguardian.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT,
            age INTEGER,
            gender TEXT,
            contact TEXT,
            last_sync TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE visits (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            patient_name TEXT,
            purpose TEXT,
            status TEXT,
            last_sync TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE reports (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            patient_name TEXT,
            risk_score REAL,
            risk_status TEXT,
            vitals TEXT,
            timestamp TEXT,
            last_sync TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE vitals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id TEXT,
            patient_name TEXT,
            type TEXT,
            value TEXT,
            unit TEXT,
            timestamp TEXT,
            last_sync TIMESTAMP
          )
        ''');
      },
    );
  }

  // --- Patients ---
  static Future<void> savePatient(Map<String, dynamic> patient) async {
    final db = await database;
    await db.insert('patients', {
      'id': patient['id'].toString(),
      'name': patient['name'],
      'age': patient['age'],
      'gender': patient['gender'],
      'contact': patient['contact'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPatients() async {
    final db = await database;
    return await db.query('patients');
  }

  static Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // --- Visits ---
  static Future<void> saveVisit(Map<String, dynamic> visit) async {
    final db = await database;
    await db.insert('visits', {
      'id': visit['id'].toString(),
      'patient_id': visit['patient_id'].toString(),
      'patient_name': visit['patient_name'],
      'purpose': visit['purpose'],
      'status': visit['status'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getVisits() async {
    final db = await database;
    return await db.query('visits');
  }

  static Future<void> updateVisitStatus(String id, String status) async {
    final db = await database;
    await db.update('visits', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteVisit(String id) async {
    final db = await database;
    await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  // --- Reports ---
  static Future<void> saveReport(Map<String, dynamic> report) async {
    final db = await database;
    await db.insert('reports', {
      'id': report['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'patient_id': report['patient_id'].toString(),
      'patient_name': report['patient_name'],
      'risk_score': report['risk_score'],
      'risk_status': report['risk_status'],
      'vitals': jsonEncode(report['vitals']),
      'timestamp': report['timestamp'] ?? DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    final db = await database;
    final res = await db.query('reports');
    return res.map((item) {
      final map = Map<String, dynamic>.from(item);
      map['vitals'] = jsonDecode(map['vitals']);
      return map;
    }).toList();
  }

  // --- Vitals ---
  static Future<void> saveVital(Map<String, dynamic> vital) async {
    final db = await database;
    await db.insert('vitals', {
      'patient_id': vital['patient_id'].toString(),
      'patient_name': vital['patient_name'],
      'type': vital['type'],
      'value': vital['value'],
      'unit': vital['unit'],
      'timestamp': vital['timestamp'] ?? DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getVitals() async {
    final db = await database;
    return await db.query('vitals');
  }
}
