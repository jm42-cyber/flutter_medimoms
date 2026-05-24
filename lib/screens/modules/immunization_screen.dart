import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class ImmunizationScreen extends StatefulWidget {
  const ImmunizationScreen({Key? key}) : super(key: key);

  @override
  State<ImmunizationScreen> createState() => _ImmunizationScreenState();
}

class _ImmunizationScreenState extends State<ImmunizationScreen> {
  List<dynamic> records = [];
  bool isLoading = true;
  bool showForm = false;
  Map<String, dynamic>? editingRecord;
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  String searchQuery = '';
  String filterBarangay = 'all';
  List<Map<String, dynamic>> barangays = [];
  int? selectedBarangayId;
  Timer? _debounce;

  // Form controllers - Step 1: Personal & Parent Info
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  String sex = 'Male';
  final motherNameController = TextEditingController();
  final fatherGuardianController = TextEditingController();

  // Step 2: Contact & Birth Details
  final addressController = TextEditingController();
  final barangayController = TextEditingController();
  final contactNoController = TextEditingController();
  final birthWeightController = TextEditingController();
  final birthLengthController = TextEditingController();
  final placeOfBirthController = TextEditingController();
  final birthAttendantController = TextEditingController();
  final currentWeightController = TextEditingController();
  final currentHeightController = TextEditingController();
  final headCircumferenceController = TextEditingController();
  final weightForAgeController = TextEditingController();
  final heightForAgeController = TextEditingController();

  // Step 3: Vaccinations
  final bcgController = TextEditingController();
  final hepaBController = TextEditingController();
  final dpt1Controller = TextEditingController();
  final dpt2Controller = TextEditingController();
  final dpt3Controller = TextEditingController();
  final opv1Controller = TextEditingController();
  final opv2Controller = TextEditingController();
  final opv3Controller = TextEditingController();
  final measlesController = TextEditingController();
  final rotavirus1Controller = TextEditingController();
  final rotavirus2Controller = TextEditingController();
  final pcv1Controller = TextEditingController();
  final pcv2Controller = TextEditingController();
  final pcv3Controller = TextEditingController();
  final mmrController = TextEditingController();

  // Step 4: Supplements & Health
  final vitADateController = TextEditingController();
  final dewormingDateController = TextEditingController();
  final nutritionalStatusController = TextEditingController();
  final allergiesController = TextEditingController();
  final previousIllnessesController = TextEditingController();
  final congenitalAbnormalitiesController = TextEditingController();
  final remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBarangays();
    fetchRecords();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    motherNameController.dispose();
    fatherGuardianController.dispose();
    addressController.dispose();
    barangayController.dispose();
    contactNoController.dispose();
    birthWeightController.dispose();
    birthLengthController.dispose();
    placeOfBirthController.dispose();
    birthAttendantController.dispose();
    currentWeightController.dispose();
    currentHeightController.dispose();
    headCircumferenceController.dispose();
    weightForAgeController.dispose();
    heightForAgeController.dispose();
    bcgController.dispose();
    hepaBController.dispose();
    dpt1Controller.dispose();
    dpt2Controller.dispose();
    dpt3Controller.dispose();
    opv1Controller.dispose();
    opv2Controller.dispose();
    opv3Controller.dispose();
    measlesController.dispose();
    rotavirus1Controller.dispose();
    rotavirus2Controller.dispose();
    pcv1Controller.dispose();
    pcv2Controller.dispose();
    pcv3Controller.dispose();
    mmrController.dispose();
    vitADateController.dispose();
    dewormingDateController.dispose();
    nutritionalStatusController.dispose();
    allergiesController.dispose();
    previousIllnessesController.dispose();
    congenitalAbnormalitiesController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> fetchBarangays() async {
    try {
      final response = await ApiService.instance.get('/user/barangays');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          if (data is Map && data.containsKey('barangays')) {
            barangays = List<Map<String, dynamic>>.from(data['barangays']);
          } else if (data is List) {
            barangays = List<Map<String, dynamic>>.from(data);
          }
        });
      }
    } catch (e) {
      print('Failed to fetch barangays: $e');
    }
  }

  Future<void> fetchRecords() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.instance.get(
        '/immunization-records?page=$currentPage&search=$searchQuery&barangay=$filterBarangay&status=active'
      );
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Safely parse the response data
        List<dynamic> fetchedRecords = [];
        if (data is Map && data.containsKey('data')) {
          fetchedRecords = data['data'] ?? [];
        } else if (data is List) {
          fetchedRecords = data;
        }
        
        // Filter out archived records on frontend as backup
        fetchedRecords = fetchedRecords.where((record) {
          if (record is Map) {
            final status = record['status']?.toString().toLowerCase();
            return status != 'archived';
          }
          return true;
        }).toList();
        
        setState(() {
          records = fetchedRecords;
          totalPages = (data is Map && data.containsKey('last_page')) ? data['last_page'] ?? 1 : 1;
          totalRecords = (data is Map && data.containsKey('total')) ? data['total'] ?? 0 : fetchedRecords.length;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError('Failed to load records: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load records: $e');
      print('Immunization fetch error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Immunization Records',
      child: showForm ? _buildForm() : _buildTable(),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        _buildToolbar(),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : records.isEmpty
                  ? const Center(child: Text('No records found'))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Child Name')),
                            DataColumn(label: Text('Sex')),
                            DataColumn(label: Text('Date of Birth')),
                            DataColumn(label: Text('Mother Name')),
                            DataColumn(label: Text('Barangay')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: records.map((record) {
                          return DataRow(cells: [
                            DataCell(Text('${record['first_name']} ${record['last_name']}')),
                            DataCell(Text(record['sex'] ?? '')),
                            DataCell(Text(record['date_of_birth'] ?? '')),
                            DataCell(Text(record['mother_name'] ?? '')),
                            DataCell(Text(record['barangay']?['name'] ?? '')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                                  onPressed: () => _viewRecord(record),
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                  onPressed: () => _showForm(record: record),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.archive, size: 20, color: Colors.purple),
                                  onPressed: () => _archiveRecord(record['id']),
                                  tooltip: 'Archive',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteRecord(record['id']),
                                  tooltip: 'Delete',
                                ),
                              ],
                            )),
                          ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixText: totalRecords > 0 ? '$totalRecords records' : null,
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  searchQuery = value;
                  currentPage = 1;
                });
                fetchRecords();
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Record'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
        ),
        const SizedBox(width: 8),
        PopupMenuButton(
          icon: const Icon(Icons.download),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'excel', child: Text('Export to Excel')),
            const PopupMenuItem(value: 'pdf', child: Text('Export to PDF')),
          ],
          onSelected: (value) {
            if (value == 'excel') _exportToExcel();
            if (value == 'pdf') _exportToPDF();
          },
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: currentPage > 1 ? () {
              setState(() => currentPage--);
              fetchRecords();
            } : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: currentPage < totalPages ? () {
              setState(() => currentPage++);
              fetchRecords();
            } : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showForm({Map<String, dynamic>? record}) {
    setState(() {
      showForm = true;
      editingRecord = record;
      currentStep = 0;
      if (record != null) {
        _populateForm(record);
      } else {
        _clearForm();
      }
    });
  }

  void _populateForm(Map<String, dynamic> record) {
    firstNameController.text = record['first_name'] ?? '';
    middleNameController.text = record['middle_name'] ?? '';
    lastNameController.text = record['last_name'] ?? '';
    dateOfBirthController.text = record['date_of_birth'] ?? '';
    
    // Handle sex with proper capitalization
    final sexValue = record['sex'];
    if (sexValue != null && ['Male', 'Female'].contains(sexValue)) {
      sex = sexValue;
    } else if (sexValue != null) {
      sex = sexValue.toString().substring(0, 1).toUpperCase() + sexValue.toString().substring(1).toLowerCase();
    } else {
      sex = 'Male';
    }
    
    motherNameController.text = record['mother_name'] ?? '';
    fatherGuardianController.text = record['father_guardian_name'] ?? '';
    addressController.text = record['address'] ?? '';
    if (record['barangay'] is Map) {
      selectedBarangayId = record['barangay']['id'];
      barangayController.text = record['barangay']['name'] ?? '';
    } else if (record['barangay_id'] != null) {
      selectedBarangayId = record['barangay_id'];
    }
    contactNoController.text = record['contact_no'] ?? '';
    birthWeightController.text = record['birth_weight']?.toString() ?? '';
    birthLengthController.text = record['birth_length']?.toString() ?? '';
    placeOfBirthController.text = record['place_of_birth'] ?? '';
    birthAttendantController.text = record['birth_attendant'] ?? '';
    currentWeightController.text = record['current_weight']?.toString() ?? '';
    currentHeightController.text = record['current_height']?.toString() ?? '';
    headCircumferenceController.text = record['head_circumference']?.toString() ?? '';
    weightForAgeController.text = record['weight_for_age'] ?? '';
    heightForAgeController.text = record['height_for_age'] ?? '';
    bcgController.text = record['bcg'] ?? '';
    hepaBController.text = record['hepa_b'] ?? '';
    dpt1Controller.text = record['dpt1'] ?? '';
    dpt2Controller.text = record['dpt2'] ?? '';
    dpt3Controller.text = record['dpt3'] ?? '';
    opv1Controller.text = record['opv1'] ?? '';
    opv2Controller.text = record['opv2'] ?? '';
    opv3Controller.text = record['opv3'] ?? '';
    measlesController.text = record['measles'] ?? '';
    rotavirus1Controller.text = record['rotavirus1'] ?? '';
    rotavirus2Controller.text = record['rotavirus2'] ?? '';
    pcv1Controller.text = record['pcv1'] ?? '';
    pcv2Controller.text = record['pcv2'] ?? '';
    pcv3Controller.text = record['pcv3'] ?? '';
    mmrController.text = record['mmr'] ?? '';
    vitADateController.text = record['vit_a_date'] ?? '';
    dewormingDateController.text = record['deworming_date'] ?? '';
    nutritionalStatusController.text = record['nutritional_status'] ?? '';
    allergiesController.text = record['allergies'] ?? '';
    previousIllnessesController.text = record['previous_illnesses'] ?? '';
    congenitalAbnormalitiesController.text = record['congenital_abnormalities'] ?? '';
    remarksController.text = record['remarks'] ?? '';
  }

  void _clearForm() {
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    dateOfBirthController.clear();
    sex = 'Male';
    motherNameController.clear();
    fatherGuardianController.clear();
    addressController.clear();
    barangayController.clear();
    selectedBarangayId = null;
    contactNoController.clear();
    birthWeightController.clear();
    birthLengthController.clear();
    placeOfBirthController.clear();
    birthAttendantController.clear();
    currentWeightController.clear();
    currentHeightController.clear();
    headCircumferenceController.clear();
    weightForAgeController.clear();
    heightForAgeController.clear();
    bcgController.clear();
    hepaBController.clear();
    dpt1Controller.clear();
    dpt2Controller.clear();
    dpt3Controller.clear();
    opv1Controller.clear();
    opv2Controller.clear();
    opv3Controller.clear();
    measlesController.clear();
    rotavirus1Controller.clear();
    rotavirus2Controller.clear();
    pcv1Controller.clear();
    pcv2Controller.clear();
    pcv3Controller.clear();
    mmrController.clear();
    vitADateController.clear();
    dewormingDateController.clear();
    nutritionalStatusController.clear();
    allergiesController.clear();
    previousIllnessesController.clear();
    congenitalAbnormalitiesController.clear();
    remarksController.clear();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'last_name': lastNameController.text,
      'date_of_birth': dateOfBirthController.text,
      'sex': sex,
      'mother_name': motherNameController.text,
      'father_guardian_name': fatherGuardianController.text,
      'address': addressController.text,
      'barangay_id': selectedBarangayId,
      'contact_no': contactNoController.text,
      'birth_weight': double.tryParse(birthWeightController.text),
      'birth_length': double.tryParse(birthLengthController.text),
      'place_of_birth': placeOfBirthController.text,
      'birth_attendant': birthAttendantController.text,
      'current_weight': double.tryParse(currentWeightController.text),
      'current_height': double.tryParse(currentHeightController.text),
      'head_circumference': double.tryParse(headCircumferenceController.text),
      'weight_for_age': weightForAgeController.text,
      'height_for_age': heightForAgeController.text,
      'bcg': bcgController.text,
      'hepa_b': hepaBController.text,
      'dpt1': dpt1Controller.text,
      'dpt2': dpt2Controller.text,
      'dpt3': dpt3Controller.text,
      'opv1': opv1Controller.text,
      'opv2': opv2Controller.text,
      'opv3': opv3Controller.text,
      'measles': measlesController.text,
      'rotavirus1': rotavirus1Controller.text,
      'rotavirus2': rotavirus2Controller.text,
      'pcv1': pcv1Controller.text,
      'pcv2': pcv2Controller.text,
      'pcv3': pcv3Controller.text,
      'mmr': mmrController.text,
      'vit_a_date': vitADateController.text,
      'deworming_date': dewormingDateController.text,
      'nutritional_status': nutritionalStatusController.text,
      'allergies': allergiesController.text,
      'previous_illnesses': previousIllnessesController.text,
      'congenital_abnormalities': congenitalAbnormalitiesController.text,
      'remarks': remarksController.text,
    };

    try {
      final response = editingRecord == null
          ? await ApiService.instance.post('/immunization-records', data: data)
          : await ApiService.instance.put('/immunization-records/${editingRecord!['id']}', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess(editingRecord == null ? 'Record created' : 'Record updated');
        setState(() => showForm = false);
        fetchRecords();
      } else {
        _showError('Failed to save record');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                editingRecord == null ? 'Add Immunization Record' : 'Edit Record',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => showForm = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepper(),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: _buildStepContent())),
          _buildFormActions(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                color: isCompleted || isActive ? const Color(0xFF10B981) : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                ['Personal', 'Contact & Birth', 'Vaccinations', 'Supplements'][index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF10B981) : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return Container();
    }
  }

  Widget _buildFormActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            ElevatedButton(
              onPressed: () => setState(() => currentStep--),
              child: const Text('Previous'),
            )
          else
            const SizedBox(),
          Row(
            children: [
              if (currentStep < 3)
                ElevatedButton(
                  onPressed: () => setState(() => currentStep++),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Save Record'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
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
        final response = await ApiService.instance.delete('/immunization-records/$id');
        if (response.statusCode == 200) {
          _showSuccess('Record deleted');
          fetchRecords();
        }
      } catch (e) {
        _showError('Failed to delete record');
      }
    }
  }

  Future<void> _archiveRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Record'),
        content: const Text('Are you sure you want to archive this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Find the record to get all its data
        final record = records.firstWhere((r) => r['id'] == id);
        final recordData = Map<String, dynamic>.from(record as Map);
        
        // Debug: Print the record to see what fields it has
        print('Immunization record before archive: $recordData');
        
        // Fix field mappings for backend validation
        // Remove nested objects that backend doesn't expect
        if (recordData.containsKey('barangay')) {
          if (recordData['barangay'] is Map) {
            recordData['barangay_id'] = recordData['barangay']['id'];
            recordData.remove('barangay');
          } else if (recordData['barangay'] is String) {
            // If barangay is already a string, it might be the name, not ID
            // Keep it as is or remove it if backend expects barangay_id
            final barangayName = recordData['barangay'];
            recordData.remove('barangay');
            // You might need to map barangay name to ID here
            // For now, we'll just remove it and let backend handle it
          }
        }
        
        // Ensure sex field is capitalized (backend expects 'Male' or 'Female')
        if (recordData.containsKey('sex') && recordData['sex'] != null) {
          final sexValue = recordData['sex'].toString();
          // Capitalize first letter
          if (sexValue.toLowerCase() == 'male') {
            recordData['sex'] = 'Male';
          } else if (sexValue.toLowerCase() == 'female') {
            recordData['sex'] = 'Female';
          } else {
            // Default to Male if invalid
            recordData['sex'] = 'Male';
          }
        } else {
          // If sex field is missing, default to Male
          recordData['sex'] = 'Male';
        }
        
        // Remove timestamps and other fields backend doesn't need
        recordData.remove('created_at');
        recordData.remove('updated_at');
        recordData.remove('id');
        
        // Add status field to archive
        recordData['status'] = 'archived';
        
        print('Immunization record after cleanup: $recordData');
        
        // Use PUT with complete record data
        final response = await ApiService.instance.put(
          '/immunization-records/$id',
          data: recordData
        );
        
        if (response.statusCode == 200) {
          _showSuccess('Record archived successfully');
          fetchRecords();
        } else {
          _showError('Failed to archive record: Status ${response.statusCode}');
        }
      } catch (e) {
        _showError('Failed to archive record: $e');
        print('Archive error: $e');
      }
    }
  }

  void _viewRecord(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record['first_name']} ${record['last_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewField('Sex', record['sex'] ?? 'N/A'),
              _buildViewField('Date of Birth', record['date_of_birth'] ?? 'N/A'),
              _buildViewField('Mother', record['mother_name'] ?? 'N/A'),
              _buildViewField('Barangay', record['barangay'] is Map ? record['barangay']['name'] ?? 'N/A' : record['barangay']?.toString() ?? 'N/A'),
              _buildViewField('Birth Weight', record['birth_weight']?.toString() ?? 'N/A'),
              _buildViewField('Current Weight', record['current_weight']?.toString() ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showForm(record: record);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final response = await ApiService.instance.get('/immunization-records/export/excel');
      if (response.statusCode == 200) {
        _showSuccess('Excel file downloaded');
      }
    } catch (e) {
      _showError('Export failed');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final response = await ApiService.instance.get('/immunization-records/export/pdf');
      if (response.statusCode == 200) {
        _showSuccess('PDF file downloaded');
      }
    } catch (e) {
      _showError('Export failed');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildTextField('First Name', firstNameController, required: true),
        _buildTextField('Middle Name', middleNameController),
        _buildTextField('Last Name', lastNameController, required: true),
        _buildDateField('Date of Birth', dateOfBirthController),
        _buildDropdown('Sex', sex, ['Male', 'Female'], (val) => setState(() => sex = val!)),
        _buildTextField('Mother\'s Name', motherNameController),
        _buildTextField('Father/Guardian Name', fatherGuardianController),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildTextField('Address', addressController),
        _buildBarangayDropdown(),
        _buildTextField('Contact Number', contactNoController, keyboardType: TextInputType.phone),
        _buildTextField('Birth Weight (kg)', birthWeightController, keyboardType: TextInputType.number),
        _buildTextField('Birth Length (cm)', birthLengthController, keyboardType: TextInputType.number),
        _buildTextField('Place of Birth', placeOfBirthController),
        _buildTextField('Birth Attendant', birthAttendantController),
        _buildTextField('Current Weight (kg)', currentWeightController, keyboardType: TextInputType.number),
        _buildTextField('Current Height (cm)', currentHeightController, keyboardType: TextInputType.number),
        _buildTextField('Head Circumference (cm)', headCircumferenceController, keyboardType: TextInputType.number),
        _buildTextField('Weight for Age', weightForAgeController),
        _buildTextField('Height for Age', heightForAgeController),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildDateField('BCG', bcgController),
        _buildDateField('Hepa B', hepaBController),
        _buildDateField('DPT 1', dpt1Controller),
        _buildDateField('DPT 2', dpt2Controller),
        _buildDateField('DPT 3', dpt3Controller),
        _buildDateField('OPV 1', opv1Controller),
        _buildDateField('OPV 2', opv2Controller),
        _buildDateField('OPV 3', opv3Controller),
        _buildDateField('Measles', measlesController),
        _buildDateField('Rotavirus 1', rotavirus1Controller),
        _buildDateField('Rotavirus 2', rotavirus2Controller),
        _buildDateField('PCV 1', pcv1Controller),
        _buildDateField('PCV 2', pcv2Controller),
        _buildDateField('PCV 3', pcv3Controller),
        _buildDateField('MMR', mmrController),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        _buildDateField('Vitamin A Date', vitADateController),
        _buildDateField('Deworming Date', dewormingDateController),
        _buildTextField('Nutritional Status', nutritionalStatusController),
        _buildTextField('Allergies', allergiesController, maxLines: 2),
        _buildTextField('Previous Illnesses', previousIllnessesController, maxLines: 2),
        _buildTextField('Congenital Abnormalities', congenitalAbnormalitiesController, maxLines: 2),
        _buildTextField('Remarks', remarksController, maxLines: 3),
      ],
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
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(date);
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

  Widget _buildBarangayDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: selectedBarangayId,
        decoration: const InputDecoration(
          labelText: 'Barangay',
          border: OutlineInputBorder(),
        ),
        items: barangays.map((barangay) {
          return DropdownMenuItem<int>(
            value: barangay['id'],
            child: Text(barangay['name'] ?? ''),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedBarangayId = value;
          });
        },
        validator: (value) => value == null ? 'Please select a barangay' : null,
      ),
    );
  }
}
