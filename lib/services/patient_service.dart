import '../config/api_endpoints.dart';
import '../models/patient.dart';
import 'api_service.dart';

class PatientService {
  PatientService._();

  static final PatientService _instance = PatientService._();
  static PatientService get instance => _instance;

  final _api = ApiService.instance;

  Future<List<Patient>> getPatients() async {
    final response = await _api.get(ApiEndpoints.patients);
    final data = response.data;
    final patients = (data['data'] ?? data) as List;
    return patients.map((json) => Patient.fromJson(json)).toList();
  }

  Future<Patient> getPatient(int id) async {
    final response = await _api.get(ApiEndpoints.patient(id));
    final data = response.data;
    return Patient.fromJson(data['data'] ?? data);
  }

  Future<Patient> createPatient(Map<String, dynamic> patientData) async {
    final response = await _api.post(
      ApiEndpoints.patients,
      data: patientData,
    );
    final data = response.data;
    return Patient.fromJson(data['data'] ?? data);
  }

  Future<Patient> updatePatient(int id, Map<String, dynamic> patientData) async {
    final response = await _api.put(
      ApiEndpoints.patient(id),
      data: patientData,
    );
    final data = response.data;
    return Patient.fromJson(data['data'] ?? data);
  }

  Future<void> deletePatient(int id) async {
    await _api.delete(ApiEndpoints.patient(id));
  }

  Future<void> archivePatient(int id) async {
    await _api.post(ApiEndpoints.patientArchive(id));
  }

  Future<void> restorePatient(int id) async {
    await _api.post(ApiEndpoints.patientRestore(id));
  }

  Future<List<Patient>> getArchivedPatients() async {
    final response = await _api.get(ApiEndpoints.archivedPatients);
    final data = response.data;
    final patients = (data['data'] ?? data) as List;
    return patients.map((json) => Patient.fromJson(json)).toList();
  }
}
