import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  bool showForm = false;
  String searchQuery = '';
  String filterStatus = 'all';
  int currentPage = 1;
  int totalPages = 1;
  Map<String, dynamic>? editingAppointment;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final patientNameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final appointmentDateController = TextEditingController();
  final appointmentTimeController = TextEditingController();
  final serviceController = TextEditingController();
  final assignedStaffController = TextEditingController();
  final notesController = TextEditingController();
  String appointmentType = 'Immunization';
  String status = 'scheduled';
  int? barangayId; // Auto-filled from user's barangay

  @override
  void initState() {
    super.initState();
    fetchAppointments();
    _loadUserBarangay();
  }

  Future<void> _loadUserBarangay() async {
    try {
      final response = await ApiService.instance.get('/me');
      if (response.statusCode == 200 && response.data['barangays'] != null) {
        final barangays = response.data['barangays'] as List;
        if (barangays.isNotEmpty) {
          setState(() {
            barangayId = barangays[0]['id'];
          });
        }
      }
    } catch (e) {
      print('Failed to load user barangay: $e');
    }
  }

  @override
  void dispose() {
    patientNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    appointmentDateController.dispose();
    appointmentTimeController.dispose();
    serviceController.dispose();
    assignedStaffController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> fetchAppointments() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.instance.get('/appointments?page=$currentPage');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          appointments = data['data'] ?? [];
          totalPages = data['last_page'] ?? 1;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load appointments');
    }
  }

  void _showForm({Map<String, dynamic>? appointment}) {
    setState(() {
      showForm = true;
      editingAppointment = appointment;
      if (appointment != null) {
        _populateForm(appointment);
      } else {
        _clearForm();
      }
    });
  }

  void _populateForm(Map<String, dynamic> appointment) {
    patientNameController.text = appointment['patient_name'] ?? '';
    contactController.text = appointment['contact_number'] ?? '';
    emailController.text = appointment['email'] ?? '';
    appointmentDateController.text = appointment['appointment_date'] ?? '';
    appointmentTimeController.text = appointment['appointment_time'] ?? '';
    serviceController.text = appointment['service'] ?? '';
    assignedStaffController.text = appointment['assigned_staff'] ?? '';
    notesController.text = appointment['notes'] ?? '';
    appointmentType = appointment['appointment_type'] ?? 'Immunization';
    status = appointment['status'] ?? 'scheduled';
    barangayId = appointment['barangay_id'];
  }

  void _clearForm() {
    patientNameController.clear();
    contactController.clear();
    emailController.clear();
    appointmentDateController.clear();
    appointmentTimeController.clear();
    serviceController.clear();
    assignedStaffController.clear();
    notesController.clear();
    appointmentType = 'Immunization';
    status = 'scheduled';
    // barangayId stays the same (user's barangay)
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (barangayId == null) {
      _showError('Barangay not loaded. Please try again.');
      return;
    }

    final data = {
      'patient_name': patientNameController.text,
      'contact_number': contactController.text,
      'email': emailController.text,
      'appointment_type': appointmentType,
      'service': serviceController.text,
      'appointment_date': appointmentDateController.text,
      'appointment_time': appointmentTimeController.text,
      'assigned_staff': assignedStaffController.text,
      'barangay_id': barangayId,
      'status': status,
      'notes': notesController.text,
    };

    try {
      final response = editingAppointment == null
          ? await ApiService.instance.post('/appointments', data: data)
          : await ApiService.instance.put('/appointments/${editingAppointment!['id']}', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(editingAppointment == null ? 'Appointment created' : 'Appointment updated');
        setState(() => showForm = false);
        fetchAppointments();
      }
    } catch (e) {
      _showError('Failed to save appointment');
    }
  }

  Future<void> _deleteAppointment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.instance.delete('/appointments/$id');
        if (response.statusCode == 200) {
          _showSuccess('Appointment deleted');
          fetchAppointments();
        }
      } catch (e) {
        _showError('Failed to delete appointment');
      }
    }
  }

  Future<void> _updateAppointmentStatus(int id, String newStatus) async {
    try {
      final response = await ApiService.instance.patch(
        '/appointments/$id/status',
        data: {'status': newStatus},
      );
      
      if (response.statusCode == 200) {
        _showSuccess('Appointment ${newStatus == "completed" ? "completed" : "cancelled"}');
        fetchAppointments();
      }
    } catch (e) {
      _showError('Failed to update appointment: $e');
      print('Update appointment error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  List<dynamic> get filteredAppointments {
    return appointments.where((apt) {
      final matchesSearch = apt['patient_name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter = filterStatus == 'all' || apt['status'] == filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Appointments',
      child: showForm ? _buildForm() : _buildList(),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        _buildToolbar(),
        const SizedBox(height: 16),
        _buildStatsCards(),
        const SizedBox(height: 16),
        Expanded(child: _buildAppointmentsList()),
        _buildPagination(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search appointments...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: filterStatus,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (value) => setState(() => filterStatus = value!),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showForm(),
          icon: const Icon(Icons.add),
          label: const Text('New Appointment'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final scheduled = appointments.where((a) => a['status'] == 'scheduled').length;
    final completed = appointments.where((a) => a['status'] == 'completed').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('This Week', appointments.length, Colors.blue, Icons.calendar_today)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Pending', scheduled, Colors.amber, Icons.schedule)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Completed', completed, Colors.green, Icons.check_circle)),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredAppointments.isEmpty) {
      return const Center(child: Text('No appointments found'));
    }

    return ListView.builder(
      itemCount: filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = filteredAppointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    appointment['patient_name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['patient_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment['appointment_date']} at ${appointment['appointment_time']}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment['appointment_type'],
                        style: TextStyle(
                          color: _getTypeColor(appointment['appointment_type']),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(appointment['status']),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: PopupMenuButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: const Icon(Icons.more_vert, size: 16),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle, size: 16, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Complete', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: const [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: const [
                                Icon(Icons.cancel, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.orange)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: const [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'complete') _updateAppointmentStatus(appointment['id'], 'completed');
                          if (value == 'cancel') _updateAppointmentStatus(appointment['id'], 'cancelled');
                          if (value == 'edit') _showForm(appointment: appointment);
                          if (value == 'delete') _deleteAppointment(appointment['id']);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'scheduled':
        color = Colors.green;
        label = '✓';
        break;
      case 'completed':
        color = Colors.grey;
        label = '✓';
        break;
      case 'cancelled':
        color = Colors.red;
        label = '✗';
        break;
      default:
        color = Colors.grey;
        label = '?';
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Immunization':
        return Colors.green;
      case 'Maternal Care':
        return Colors.pink;
      case 'Family Planning':
        return Colors.blue;
      case 'Senior Citizen':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () {
              setState(() => currentPage--);
              fetchAppointments();
            } : null,
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () {
              setState(() => currentPage++);
              fetchAppointments();
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  editingAppointment == null ? 'New Appointment' : 'Edit Appointment',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => showForm = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Patient Name', patientNameController, required: true),
            _buildTextField('Contact Number', contactController, keyboardType: TextInputType.phone),
            _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
            _buildDateField('Appointment Date', appointmentDateController),
            _buildTimeField('Appointment Time', appointmentTimeController),
            _buildDropdown('Appointment Type', appointmentType, [
              'Immunization',
              'Maternal Care',
              'Family Planning',
              'Senior Citizen',
            ], (val) => setState(() => appointmentType = val!)),
            _buildTextField('Service', serviceController),
            _buildTextField('Assigned Staff', assignedStaffController),
            _buildDropdown('Status', status, [
              'scheduled',
              'completed',
              'cancelled',
            ], (val) => setState(() => status = val!)),
            _buildTextField('Notes', notesController, maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showForm = false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAppointment,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(editingAppointment == null ? 'Create' : 'Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required ? (val) => val?.isEmpty ?? true ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(date);
          }
        },
      ),
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        readOnly: true,
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            controller.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          }
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
