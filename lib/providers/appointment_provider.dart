import 'package:flutter/foundation.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String type; // 'checkup', 'followup', 'emergency'
  final String status; // 'scheduled', 'completed', 'cancelled'
  String notes;
  final String category; // 'maternal', 'senior', 'child'

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.type,
    required this.status,
    this.notes = '',
    required this.category,
  });
}

class AppointmentProvider with ChangeNotifier {
  final List<Appointment> _appointments = [
    Appointment(
      id: 'A001',
      patientId: 'M002',
      patientName: 'Ana Garcia',
      dateTime: DateTime(2025, 11, 2, 10, 0),
      type: 'followup',
      status: 'scheduled',
      category: 'maternal',
      notes: 'Blood pressure monitoring',
    ),
    Appointment(
      id: 'A002',
      patientId: 'S004',
      patientName: 'Rosa Santos',
      dateTime: DateTime(2025, 11, 1, 9, 0),
      type: 'emergency',
      status: 'scheduled',
      category: 'senior',
      notes: 'Chest pain follow-up',
    ),
    Appointment(
      id: 'A003',
      patientId: 'M001',
      patientName: 'Maria Santos',
      dateTime: DateTime(2025, 11, 5, 14, 0),
      type: 'checkup',
      status: 'scheduled',
      category: 'maternal',
      notes: 'Regular prenatal checkup',
    ),
    Appointment(
      id: 'A004',
      patientId: 'S002',
      patientName: 'Carmen Dela Cruz',
      dateTime: DateTime(2025, 11, 5, 11, 0),
      type: 'checkup',
      status: 'scheduled',
      category: 'senior',
      notes: 'Blood sugar monitoring',
    ),
  ];

  List<Appointment> get allAppointments => _appointments;

  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.year == now.year &&
          apt.dateTime.month == now.month &&
          apt.dateTime.day == now.day &&
          apt.status == 'scheduled';
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.isAfter(now) && apt.status == 'scheduled';
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get thisWeekAppointments {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return _appointments.where((apt) {
      return apt.dateTime.isAfter(now) &&
          apt.dateTime.isBefore(weekFromNow) &&
          apt.status == 'scheduled';
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  int get pendingCount =>
      _appointments.where((apt) => apt.status == 'scheduled').length;

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  void updateAppointment(String id, Appointment updatedAppointment) {
    final index = _appointments.indexWhere((apt) => apt.id == id);
    if (index != -1) {
      _appointments[index] = updatedAppointment;
      notifyListeners();
    }
  }

  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((apt) => apt.id == id);
    if (index != -1) {
      _appointments[index] = Appointment(
        id: _appointments[index].id,
        patientId: _appointments[index].patientId,
        patientName: _appointments[index].patientName,
        dateTime: _appointments[index].dateTime,
        type: _appointments[index].type,
        status: 'cancelled',
        notes: _appointments[index].notes,
        category: _appointments[index].category,
      );
      notifyListeners();
    }
  }

  void completeAppointment(String id, String notes) {
    final index = _appointments.indexWhere((apt) => apt.id == id);
    if (index != -1) {
      _appointments[index] = Appointment(
        id: _appointments[index].id,
        patientId: _appointments[index].patientId,
        patientName: _appointments[index].patientName,
        dateTime: _appointments[index].dateTime,
        type: _appointments[index].type,
        status: 'completed',
        notes: notes,
        category: _appointments[index].category,
      );
      notifyListeners();
    }
  }

  List<Appointment> getPatientAppointments(String patientId) {
    return _appointments.where((apt) => apt.patientId == patientId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  bool hasConflict(DateTime dateTime) {
    return _appointments.any((apt) =>
        apt.dateTime.year == dateTime.year &&
        apt.dateTime.month == dateTime.month &&
        apt.dateTime.day == dateTime.day &&
        apt.dateTime.hour == dateTime.hour &&
        apt.status == 'scheduled');
  }
}
