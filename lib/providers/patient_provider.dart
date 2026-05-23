import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

class PatientProvider extends ChangeNotifier {
  final _patientService = PatientService.instance;

  List<Patient> _patients = [];
  List<Patient> _archivedPatients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Patient> get patients => _patients;
  List<Patient> get archivedPatients => _archivedPatients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Patient> get maternalPatients =>
      _patients.where((p) => p.age >= 15 && p.age <= 49 && p.gender.toLowerCase() == 'female').toList();

  List<Patient> get seniorPatients =>
      _patients.where((p) => p.age >= 60).toList();

  List<Patient> get childPatients =>
      _patients.where((p) => p.age < 18).toList();

  Map<String, int> getStatistics() {
    return {
      'total': _patients.length,
      'maternal': maternalPatients.length,
      'senior': seniorPatients.length,
      'child': childPatients.length,
      'archived': _archivedPatients.length,
    };
  }

  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _patients = await _patientService.getPatients();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Load patients error: $e');
    }
  }

  Future<void> loadArchivedPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _archivedPatients = await _patientService.getArchivedPatients();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Load archived patients error: $e');
    }
  }

  Future<Patient?> getPatient(int id) async {
    try {
      return await _patientService.getPatient(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('❌ Get patient error: $e');
      return null;
    }
  }

  Future<bool> addPatient(Map<String, dynamic> patientData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patient = await _patientService.createPatient(patientData);
      _patients.add(patient);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Add patient error: $e');
      return false;
    }
  }

  Future<bool> updatePatient(int id, Map<String, dynamic> patientData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPatient = await _patientService.updatePatient(id, patientData);
      final index = _patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        _patients[index] = updatedPatient;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Update patient error: $e');
      return false;
    }
  }

  Future<bool> deletePatient(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _patientService.deletePatient(id);
      _patients.removeWhere((p) => p.id == id);
      _archivedPatients.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Delete patient error: $e');
      return false;
    }
  }

  Future<bool> archivePatient(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _patientService.archivePatient(id);
      final patient = _patients.firstWhere((p) => p.id == id);
      _patients.removeWhere((p) => p.id == id);
      _archivedPatients.add(patient.copyWith(isArchived: true));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Archive patient error: $e');
      return false;
    }
  }

  Future<bool> restoreArchivedPatient(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _patientService.restorePatient(id);
      final patient = _archivedPatients.firstWhere((p) => p.id == id);
      _archivedPatients.removeWhere((p) => p.id == id);
      _patients.add(patient.copyWith(isArchived: false));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Restore patient error: $e');
      return false;
    }
  }

  Patient? getPatientById(int id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Patient> searchPatients(String query) {
    if (query.isEmpty) return _patients;
    final lowerQuery = query.toLowerCase();
    return _patients.where((p) =>
      p.fullName.toLowerCase().contains(lowerQuery) ||
      p.id.toString().contains(lowerQuery) ||
      (p.email?.toLowerCase().contains(lowerQuery) ?? false) ||
      (p.phone?.contains(query) ?? false)
    ).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
