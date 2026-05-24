import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class SeniorCitizenScreen extends StatefulWidget {
  const SeniorCitizenScreen({Key? key}) : super(key: key);

  @override
  State<SeniorCitizenScreen> createState() => _SeniorCitizenScreenState();
}

class _SeniorCitizenScreenState extends State<SeniorCitizenScreen> {
  List<dynamic> records = [];
  List<dynamic> barangays = [];
  bool isLoading = true;
  bool showForm = false;
  Map<String, dynamic>? editingRecord;
  int currentPage = 1;
  int totalPages = 1;
  String searchQuery = '';
  String filterBarangay = 'all';
  String filterStatus = 'all';
  int? selectedBarangayId;

  // Form controllers - Step 1: Personal Info
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final barangayController = TextEditingController();
  final contactController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final emergencyNameController = TextEditingController();
  String gender = 'Male';
  String civilStatus = 'Single';
  
  // Step 2: Health Assessment
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final bpController = TextEditingController();
  final bloodSugarController = TextEditingController();
  final cholesterolController = TextEditingController();
  String bloodType = 'Unknown';
  final chronicConditionsController = TextEditingController();
  final medicationsController = TextEditingController();
  final allergiesController = TextEditingController();
  
  // Step 3: Functional & Social Assessment
  String mobilityStatus = 'Independent';
  String visionStatus = 'Normal';
  String hearingStatus = 'Normal';
  String mentalStatus = 'Alert';
  final adlScoreController = TextEditingController();
  final iadlScoreController = TextEditingController();
  String livingArrangement = 'With Family';
  final caregiverController = TextEditingController();
  bool hasPhilHealth = false;
  bool hasSeniorId = false;
  
  // Step 4: Screenings & Immunization
  final lastCheckupController = TextEditingController();
  final nextCheckupController = TextEditingController();
  bool fluVaccine = false;
  bool pneumoniaVaccine = false;
  bool covidVaccine = false;
  final covidDosesController = TextEditingController();
  final nutritionAssessmentController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecords();
    fetchBarangays();
  }

  Future<void> fetchBarangays() async {
    try {
      final response = await ApiService.instance.get('/user/barangays');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          if (data is Map && data.containsKey('barangays')) {
            barangays = List<dynamic>.from(data['barangays']);
          } else if (data is List) {
            barangays = data;
          }
        });
      }
    } catch (e) {
      print('Failed to fetch barangays: $e');
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    ageController.dispose();
    addressController.dispose();
    barangayController.dispose();
    contactController.dispose();
    emergencyContactController.dispose();
    emergencyNameController.dispose();
    weightController.dispose();
    heightController.dispose();
    bpController.dispose();
    bloodSugarController.dispose();
    cholesterolController.dispose();
    chronicConditionsController.dispose();
    medicationsController.dispose();
    allergiesController.dispose();
    adlScoreController.dispose();
    iadlScoreController.dispose();
    caregiverController.dispose();
    lastCheckupController.dispose();
    nextCheckupController.dispose();
    covidDosesController.dispose();
    nutritionAssessmentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> fetchRecords() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.instance.get(
        '/senior-citizen-records?page=$currentPage&search=$searchQuery&barangay=$filterBarangay&status=active'
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
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError('Failed to load records: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load records: $e');
      print('Senior Citizen fetch error: $e');
    }
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
    ageController.text = record['age']?.toString() ?? '';
    addressController.text = record['address'] ?? '';
    
    if (record['barangay'] is Map) {
      selectedBarangayId = record['barangay']['id'];
      barangayController.text = record['barangay']['name'] ?? '';
    } else if (record['barangay_id'] != null) {
      selectedBarangayId = record['barangay_id'];
    }
    
    contactController.text = record['contact_number'] ?? '';
    emergencyContactController.text = record['emergency_contact'] ?? '';
    emergencyNameController.text = record['emergency_name'] ?? '';
    
    // Handle gender with proper capitalization
    final genderValue = record['gender'];
    if (genderValue != null && ['Male', 'Female'].contains(genderValue)) {
      gender = genderValue;
    } else if (genderValue != null) {
      gender = genderValue.toString().substring(0, 1).toUpperCase() + genderValue.toString().substring(1).toLowerCase();
    } else {
      gender = 'Male';
    }
    
    // Handle civil status with proper capitalization
    final civilValue = record['civil_status'];
    if (civilValue != null && ['Single', 'Married', 'Widowed', 'Separated'].contains(civilValue)) {
      civilStatus = civilValue;
    } else if (civilValue != null) {
      civilStatus = civilValue.toString().substring(0, 1).toUpperCase() + civilValue.toString().substring(1).toLowerCase();
    } else {
      civilStatus = 'Single';
    }
    
    weightController.text = record['weight']?.toString() ?? '';
    heightController.text = record['height']?.toString() ?? '';
    bpController.text = record['blood_pressure'] ?? '';
    bloodSugarController.text = record['blood_sugar']?.toString() ?? '';
    cholesterolController.text = record['cholesterol']?.toString() ?? '';
    
    // Handle blood type
    final bloodTypeValue = record['blood_type'];
    if (bloodTypeValue != null && ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodTypeValue)) {
      bloodType = bloodTypeValue;
    } else {
      bloodType = 'Unknown';
    }
    
    chronicConditionsController.text = record['chronic_conditions'] ?? '';
    medicationsController.text = record['medications'] ?? '';
    allergiesController.text = record['allergies'] ?? '';
    
    // Handle mobility status
    final mobilityValue = record['mobility_status'];
    if (mobilityValue != null && ['Independent', 'Assisted', 'Wheelchair', 'Bedridden'].contains(mobilityValue)) {
      mobilityStatus = mobilityValue;
    } else if (mobilityValue != null) {
      mobilityStatus = mobilityValue.toString().substring(0, 1).toUpperCase() + mobilityValue.toString().substring(1).toLowerCase();
    } else {
      mobilityStatus = 'Independent';
    }
    
    // Handle vision status
    final visionValue = record['vision_status'];
    if (visionValue != null && ['Normal', 'Impaired', 'Blind'].contains(visionValue)) {
      visionStatus = visionValue;
    } else if (visionValue != null) {
      visionStatus = visionValue.toString().substring(0, 1).toUpperCase() + visionValue.toString().substring(1).toLowerCase();
    } else {
      visionStatus = 'Normal';
    }
    
    // Handle hearing status
    final hearingValue = record['hearing_status'];
    if (hearingValue != null && ['Normal', 'Impaired', 'Deaf'].contains(hearingValue)) {
      hearingStatus = hearingValue;
    } else if (hearingValue != null) {
      hearingStatus = hearingValue.toString().substring(0, 1).toUpperCase() + hearingValue.toString().substring(1).toLowerCase();
    } else {
      hearingStatus = 'Normal';
    }
    
    // Handle mental status
    final mentalValue = record['mental_status'];
    if (mentalValue != null && ['Alert', 'Confused', 'Disoriented', 'Dementia'].contains(mentalValue)) {
      mentalStatus = mentalValue;
    } else if (mentalValue != null) {
      mentalStatus = mentalValue.toString().substring(0, 1).toUpperCase() + mentalValue.toString().substring(1).toLowerCase();
    } else {
      mentalStatus = 'Alert';
    }
    
    adlScoreController.text = record['adl_score']?.toString() ?? '';
    iadlScoreController.text = record['iadl_score']?.toString() ?? '';
    
    // Handle living arrangement
    final livingValue = record['living_arrangement'];
    if (livingValue != null && ['With Family', 'Alone', 'Care Facility', 'With Spouse'].contains(livingValue)) {
      livingArrangement = livingValue;
    } else {
      livingArrangement = 'With Family';
    }
    
    caregiverController.text = record['caregiver'] ?? '';
    hasPhilHealth = record['has_philhealth'] == 1 || record['has_philhealth'] == true;
    hasSeniorId = record['has_senior_id'] == 1 || record['has_senior_id'] == true;
    lastCheckupController.text = record['last_checkup'] ?? '';
    nextCheckupController.text = record['next_checkup'] ?? '';
    fluVaccine = record['flu_vaccine'] == 1 || record['flu_vaccine'] == true;
    pneumoniaVaccine = record['pneumonia_vaccine'] == 1 || record['pneumonia_vaccine'] == true;
    covidVaccine = record['covid_vaccine'] == 1 || record['covid_vaccine'] == true;
    covidDosesController.text = record['covid_doses']?.toString() ?? '';
    nutritionAssessmentController.text = record['nutrition_assessment'] ?? '';
    notesController.text = record['notes'] ?? '';
  }

  void _clearForm() {
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    dateOfBirthController.clear();
    ageController.clear();
    addressController.clear();
    barangayController.clear();
    selectedBarangayId = null;
    contactController.clear();
    emergencyContactController.clear();
    emergencyNameController.clear();
    weightController.clear();
    heightController.clear();
    bpController.clear();
    bloodSugarController.clear();
    cholesterolController.clear();
    chronicConditionsController.clear();
    medicationsController.clear();
    allergiesController.clear();
    adlScoreController.clear();
    iadlScoreController.clear();
    caregiverController.clear();
    lastCheckupController.clear();
    nextCheckupController.clear();
    covidDosesController.clear();
    nutritionAssessmentController.clear();
    notesController.clear();
    gender = 'Male';
    civilStatus = 'Single';
    bloodType = 'Unknown';
    mobilityStatus = 'Independent';
    visionStatus = 'Normal';
    hearingStatus = 'Normal';
    mentalStatus = 'Alert';
    livingArrangement = 'With Family';
    hasPhilHealth = false;
    hasSeniorId = false;
    fluVaccine = false;
    pneumoniaVaccine = false;
    covidVaccine = false;
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'last_name': lastNameController.text,
      'date_of_birth': dateOfBirthController.text,
      'age': int.tryParse(ageController.text),
      'sex': gender,
      'civil_status': civilStatus,
      'address': addressController.text,
      'barangay_id': selectedBarangayId,
      'contact_number': contactController.text,
      'emergency_contact': emergencyContactController.text,
      'emergency_name': emergencyNameController.text,
      'weight': double.tryParse(weightController.text),
      'height': double.tryParse(heightController.text),
      'blood_pressure': bpController.text,
      'blood_sugar': double.tryParse(bloodSugarController.text),
      'cholesterol': double.tryParse(cholesterolController.text),
      'blood_type': bloodType,
      'chronic_conditions': chronicConditionsController.text,
      'medications': medicationsController.text,
      'allergies': allergiesController.text,
      'mobility_status': mobilityStatus,
      'vision_status': visionStatus,
      'hearing_status': hearingStatus,
      'mental_status': mentalStatus,
      'adl_score': int.tryParse(adlScoreController.text),
      'iadl_score': int.tryParse(iadlScoreController.text),
      'living_arrangement': livingArrangement,
      'caregiver': caregiverController.text,
      'has_philhealth': hasPhilHealth,
      'has_senior_id': hasSeniorId,
      'last_checkup': lastCheckupController.text,
      'next_checkup': nextCheckupController.text,
      'flu_vaccine': fluVaccine,
      'pneumonia_vaccine': pneumoniaVaccine,
      'covid_vaccine': covidVaccine,
      'covid_doses': int.tryParse(covidDosesController.text),
      'nutrition_assessment': nutritionAssessmentController.text,
      'notes': notesController.text,
    };

    try {
      final response = editingRecord == null
          ? await ApiService.instance.post('/senior-citizen-records', data: data)
          : await ApiService.instance.put('/senior-citizen-records/${editingRecord!['id']}', data: data);

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
        final response = await ApiService.instance.delete('/senior-citizen-records/$id');
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
        
        // Fix field mappings for backend validation
        // Remove nested objects that backend doesn't expect
        if (recordData['barangay'] is Map) {
          recordData['barangay_id'] = recordData['barangay']['id'];
          recordData.remove('barangay');
        }
        
        // Remove timestamps and other fields backend doesn't need
        recordData.remove('created_at');
        recordData.remove('updated_at');
        recordData.remove('id');
        
        // Add status field to archive
        recordData['status'] = 'archived';
        
        // Use PUT with complete record data
        final response = await ApiService.instance.put(
          '/senior-citizen-records/$id',
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
              _buildViewField('Age', record['age']?.toString() ?? 'N/A'),
              _buildViewField('Gender', record['gender'] ?? 'N/A'),
              _buildViewField('Barangay', record['barangay'] is Map ? record['barangay']['name'] ?? 'N/A' : record['barangay']?.toString() ?? 'N/A'),
              _buildViewField('Contact', record['contact_number'] ?? 'N/A'),
              _buildViewField('Blood Type', record['blood_type'] ?? 'N/A'),
              _buildViewField('Mobility', record['mobility_status'] ?? 'N/A'),
              _buildViewField('Mental Status', record['mental_status'] ?? 'N/A'),
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
      final response = await ApiService.instance.get('/senior-citizen-records/export/excel');
      if (response.statusCode == 200) {
        _showSuccess('Excel file downloaded');
      }
    } catch (e) {
      _showError('Export failed');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final response = await ApiService.instance.get('/senior-citizen-records/export/pdf');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Senior Citizen Records',
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
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Age')),
                          DataColumn(label: Text('Gender')),
                          DataColumn(label: Text('Barangay')),
                          DataColumn(label: Text('Contact')),
                          DataColumn(label: Text('Health Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: records.map((record) {
                          // Safety checks for record data
                          if (record == null || record is! Map) {
                            return DataRow(cells: [
                              DataCell(Text('Invalid data')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                            ]);
                          }
                          
                          // Cast to proper type
                          final recordData = Map<String, dynamic>.from(record as Map);
                          
                          return DataRow(cells: [
                            DataCell(Text('${recordData['first_name'] ?? ''} ${recordData['last_name'] ?? ''}')),
                            DataCell(Text(recordData['age']?.toString() ?? '')),
                            DataCell(Text(recordData['gender']?.toString() ?? '')),
                            DataCell(Text(
                              recordData['barangay'] is Map 
                                ? (recordData['barangay']['name']?.toString() ?? '') 
                                : (recordData['barangay']?.toString() ?? '')
                            )),
                            DataCell(Text(recordData['contact_number']?.toString() ?? '')),
                            DataCell(_buildHealthBadge(recordData['chronic_conditions']?.toString())),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                                  onPressed: () => _viewRecord(recordData),
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                  onPressed: () => _showForm(record: recordData),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.archive, size: 20, color: Colors.purple),
                                  onPressed: () => _archiveRecord(recordData['id']),
                                  tooltip: 'Archive',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteRecord(recordData['id']),
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
            decoration: const InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => searchQuery = value);
              fetchRecords();
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Record'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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

  Widget _buildHealthBadge(String? conditions) {
    final hasConditions = conditions != null && conditions.isNotEmpty;
    final color = hasConditions ? Colors.orange : Colors.green;
    final text = hasConditions ? 'Has Conditions' : 'Healthy';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                editingRecord == null ? 'Add Senior Citizen Record' : 'Edit Record',
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
                color: isCompleted || isActive ? Colors.orange : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                ['Personal Info', 'Health', 'Functional', 'Screenings'][index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.orange : Colors.grey,
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

  Widget _buildStep1() {
    return Column(
      children: [
        _buildTextField('First Name', firstNameController, required: true),
        _buildTextField('Middle Name', middleNameController),
        _buildTextField('Last Name', lastNameController, required: true),
        _buildDateField('Date of Birth', dateOfBirthController),
        _buildTextField('Age', ageController, keyboardType: TextInputType.number, required: true),
        _buildDropdown('Gender', gender, ['Male', 'Female'], (val) => setState(() => gender = val!)),
        _buildDropdown('Civil Status', civilStatus, ['Single', 'Married', 'Widowed', 'Separated'], (val) => setState(() => civilStatus = val!)),
        _buildTextField('Address', addressController, required: true),
        _buildBarangayDropdown(),
        _buildTextField('Contact Number', contactController, keyboardType: TextInputType.phone),
        _buildTextField('Emergency Contact Name', emergencyNameController),
        _buildTextField('Emergency Contact Number', emergencyContactController, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildTextField('Weight (kg)', weightController, keyboardType: TextInputType.number),
        _buildTextField('Height (cm)', heightController, keyboardType: TextInputType.number),
        _buildTextField('Blood Pressure', bpController),
        _buildTextField('Blood Sugar (mg/dL)', bloodSugarController, keyboardType: TextInputType.number),
        _buildTextField('Cholesterol (mg/dL)', cholesterolController, keyboardType: TextInputType.number),
        _buildDropdown('Blood Type', bloodType, ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (val) => setState(() => bloodType = val!)),
        _buildTextField('Chronic Conditions', chronicConditionsController, maxLines: 3),
        _buildTextField('Current Medications', medicationsController, maxLines: 3),
        _buildTextField('Allergies', allergiesController, maxLines: 2),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildDropdown('Mobility Status', mobilityStatus, ['Independent', 'Assisted', 'Wheelchair', 'Bedridden'], (val) => setState(() => mobilityStatus = val!)),
        _buildDropdown('Vision Status', visionStatus, ['Normal', 'Impaired', 'Blind'], (val) => setState(() => visionStatus = val!)),
        _buildDropdown('Hearing Status', hearingStatus, ['Normal', 'Impaired', 'Deaf'], (val) => setState(() => hearingStatus = val!)),
        _buildDropdown('Mental Status', mentalStatus, ['Alert', 'Confused', 'Disoriented', 'Dementia'], (val) => setState(() => mentalStatus = val!)),
        _buildTextField('ADL Score (0-100)', adlScoreController, keyboardType: TextInputType.number),
        _buildTextField('IADL Score (0-100)', iadlScoreController, keyboardType: TextInputType.number),
        _buildDropdown('Living Arrangement', livingArrangement, ['With Family', 'Alone', 'Care Facility', 'With Spouse'], (val) => setState(() => livingArrangement = val!)),
        _buildTextField('Caregiver Name', caregiverController),
        CheckboxListTile(
          title: const Text('Has PhilHealth'),
          value: hasPhilHealth,
          onChanged: (val) => setState(() => hasPhilHealth = val!),
        ),
        CheckboxListTile(
          title: const Text('Has Senior Citizen ID'),
          value: hasSeniorId,
          onChanged: (val) => setState(() => hasSeniorId = val!),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        _buildDateField('Last Checkup Date', lastCheckupController),
        _buildDateField('Next Checkup Date', nextCheckupController),
        CheckboxListTile(
          title: const Text('Flu Vaccine'),
          value: fluVaccine,
          onChanged: (val) => setState(() => fluVaccine = val!),
        ),
        CheckboxListTile(
          title: const Text('Pneumonia Vaccine'),
          value: pneumoniaVaccine,
          onChanged: (val) => setState(() => pneumoniaVaccine = val!),
        ),
        CheckboxListTile(
          title: const Text('COVID-19 Vaccine'),
          value: covidVaccine,
          onChanged: (val) => setState(() => covidVaccine = val!),
        ),
        if (covidVaccine)
          _buildTextField('COVID-19 Doses', covidDosesController, keyboardType: TextInputType.number),
        _buildTextField('Nutrition Assessment', nutritionAssessmentController, maxLines: 3),
        _buildTextField('Additional Notes', notesController, maxLines: 4),
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
            child: Text(barangay['name']),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedBarangayId = value),
        validator: (value) => value == null ? 'Required' : null,
      ),
    );
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Save Record'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
