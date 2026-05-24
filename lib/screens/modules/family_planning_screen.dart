import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class FamilyPlanningScreen extends StatefulWidget {
  const FamilyPlanningScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPlanningScreen> createState() => _FamilyPlanningScreenState();
}

class _FamilyPlanningScreenState extends State<FamilyPlanningScreen> {
  List<dynamic> records = [];
  bool isLoading = true;
  bool showForm = false;
  Map<String, dynamic>? editingRecord;
  int currentPage = 1;
  int totalPages = 1;
  String searchQuery = '';
  String filterBarangay = 'all';
  String filterMethod = 'all';

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
  String civilStatus = 'Married';
  final numberOfChildrenController = TextEditingController();
  
  // Step 2: Partner & Reproductive History
  final partnerNameController = TextEditingController();
  final partnerAgeController = TextEditingController();
  final partnerOccupationController = TextEditingController();
  final gravidaController = TextEditingController();
  final parityController = TextEditingController();
  final abortionController = TextEditingController();
  final livingChildrenController = TextEditingController();
  final lastDeliveryController = TextEditingController();
  final lmpController = TextEditingController();
  String menstrualCycle = 'Regular';
  
  // Step 3: Medical History & Physical Exam
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final bpController = TextEditingController();
  String bloodType = 'Unknown';
  final medicalHistoryController = TextEditingController();
  final allergiesController = TextEditingController();
  bool smoker = false;
  bool drinker = false;
  final obstetricalHistoryController = TextEditingController();
  
  // Step 4: FP Method & Follow-up
  String fpMethod = 'Pills';
  final methodStartDateController = TextEditingController();
  final nextVisitController = TextEditingController();
  final sideEffectsController = TextEditingController();
  final suppliesGivenController = TextEditingController();
  final notesController = TextEditingController();
  bool consentSigned = false;
  String clientType = 'New Acceptor';

  @override
  void initState() {
    super.initState();
    fetchRecords();
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
    numberOfChildrenController.dispose();
    partnerNameController.dispose();
    partnerAgeController.dispose();
    partnerOccupationController.dispose();
    gravidaController.dispose();
    parityController.dispose();
    abortionController.dispose();
    livingChildrenController.dispose();
    lastDeliveryController.dispose();
    lmpController.dispose();
    weightController.dispose();
    heightController.dispose();
    bpController.dispose();
    medicalHistoryController.dispose();
    allergiesController.dispose();
    obstetricalHistoryController.dispose();
    methodStartDateController.dispose();
    nextVisitController.dispose();
    sideEffectsController.dispose();
    suppliesGivenController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> fetchRecords() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.instance.get(
        '/family-planning-records?page=$currentPage&search=$searchQuery&barangay=$filterBarangay&method=$filterMethod&status=active'
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
      print('Family Planning fetch error: $e');
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
    barangayController.text = record['barangay'] is Map ? record['barangay']['name'] ?? '' : record['barangay']?.toString() ?? '';
    contactController.text = record['contact_number'] ?? '';
    
    // Handle civil status
    final civilValue = record['civil_status'];
    if (civilValue != null && ['Single', 'Married', 'Live-in', 'Widowed', 'Separated'].contains(civilValue)) {
      civilStatus = civilValue;
    } else if (civilValue != null) {
      civilStatus = civilValue.toString().substring(0, 1).toUpperCase() + civilValue.toString().substring(1).toLowerCase();
    } else {
      civilStatus = 'Married';
    }
    
    numberOfChildrenController.text = record['number_of_children']?.toString() ?? '';
    partnerNameController.text = record['partner_name'] ?? '';
    partnerAgeController.text = record['partner_age']?.toString() ?? '';
    partnerOccupationController.text = record['partner_occupation'] ?? '';
    gravidaController.text = record['gravida']?.toString() ?? '';
    parityController.text = record['parity']?.toString() ?? '';
    abortionController.text = record['abortion']?.toString() ?? '';
    livingChildrenController.text = record['living_children']?.toString() ?? '';
    lastDeliveryController.text = record['last_delivery'] ?? '';
    lmpController.text = record['lmp'] ?? '';
    
    // Handle menstrual cycle
    final menstrualValue = record['menstrual_cycle'];
    if (menstrualValue != null && ['Regular', 'Irregular'].contains(menstrualValue)) {
      menstrualCycle = menstrualValue;
    } else if (menstrualValue != null) {
      menstrualCycle = menstrualValue.toString().substring(0, 1).toUpperCase() + menstrualValue.toString().substring(1).toLowerCase();
    } else {
      menstrualCycle = 'Regular';
    }
    
    weightController.text = record['weight']?.toString() ?? '';
    heightController.text = record['height']?.toString() ?? '';
    bpController.text = record['blood_pressure'] ?? '';
    
    // Handle blood type
    final bloodTypeValue = record['blood_type'];
    if (bloodTypeValue != null && ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodTypeValue)) {
      bloodType = bloodTypeValue;
    } else {
      bloodType = 'Unknown';
    }
    
    medicalHistoryController.text = record['medical_history'] ?? '';
    allergiesController.text = record['allergies'] ?? '';
    smoker = record['smoker'] == 1 || record['smoker'] == true;
    drinker = record['drinker'] == 1 || record['drinker'] == true;
    obstetricalHistoryController.text = record['obstetrical_history'] ?? '';
    
    // Handle FP method
    final fpValue = record['fp_method'];
    if (fpValue != null && ['Pills', 'Injectable', 'IUD', 'Implant', 'Condom', 'BTL', 'NSV', 'LAM', 'Natural'].contains(fpValue)) {
      fpMethod = fpValue;
    } else if (fpValue != null) {
      fpMethod = fpValue.toString().substring(0, 1).toUpperCase() + fpValue.toString().substring(1).toLowerCase();
    } else {
      fpMethod = 'Pills';
    }
    
    methodStartDateController.text = record['method_start_date'] ?? '';
    nextVisitController.text = record['next_visit'] ?? '';
    sideEffectsController.text = record['side_effects'] ?? '';
    suppliesGivenController.text = record['supplies_given'] ?? '';
    notesController.text = record['notes'] ?? '';
    consentSigned = record['consent_signed'] == 1 || record['consent_signed'] == true;
    
    // Handle client type
    final clientValue = record['client_type'];
    if (clientValue != null && ['New Acceptor', 'Current User', 'Changing Method', 'Dropout/Restart'].contains(clientValue)) {
      clientType = clientValue;
    } else {
      clientType = 'New Acceptor';
    }
  }

  void _clearForm() {
    firstNameController.clear();
    middleNameController.clear();
    lastNameController.clear();
    dateOfBirthController.clear();
    ageController.clear();
    addressController.clear();
    barangayController.clear();
    contactController.clear();
    numberOfChildrenController.clear();
    partnerNameController.clear();
    partnerAgeController.clear();
    partnerOccupationController.clear();
    gravidaController.clear();
    parityController.clear();
    abortionController.clear();
    livingChildrenController.clear();
    lastDeliveryController.clear();
    lmpController.clear();
    weightController.clear();
    heightController.clear();
    bpController.clear();
    medicalHistoryController.clear();
    allergiesController.clear();
    obstetricalHistoryController.clear();
    methodStartDateController.clear();
    nextVisitController.clear();
    sideEffectsController.clear();
    suppliesGivenController.clear();
    notesController.clear();
    civilStatus = 'Married';
    menstrualCycle = 'Regular';
    bloodType = 'Unknown';
    smoker = false;
    drinker = false;
    fpMethod = 'Pills';
    consentSigned = false;
    clientType = 'New Acceptor';
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'first_name': firstNameController.text,
      'middle_name': middleNameController.text,
      'last_name': lastNameController.text,
      'date_of_birth': dateOfBirthController.text,
      'age': int.tryParse(ageController.text),
      'address': addressController.text,
      'barangay': barangayController.text,
      'contact_number': contactController.text,
      'civil_status': civilStatus,
      'number_of_children': int.tryParse(numberOfChildrenController.text),
      'partner_name': partnerNameController.text,
      'partner_age': int.tryParse(partnerAgeController.text),
      'partner_occupation': partnerOccupationController.text,
      'gravida': int.tryParse(gravidaController.text),
      'parity': int.tryParse(parityController.text),
      'abortion': int.tryParse(abortionController.text),
      'living_children': int.tryParse(livingChildrenController.text),
      'last_delivery': lastDeliveryController.text,
      'lmp': lmpController.text,
      'menstrual_cycle': menstrualCycle,
      'weight': double.tryParse(weightController.text),
      'height': double.tryParse(heightController.text),
      'blood_pressure': bpController.text,
      'blood_type': bloodType,
      'medical_history': medicalHistoryController.text,
      'allergies': allergiesController.text,
      'smoker': smoker,
      'drinker': drinker,
      'obstetrical_history': obstetricalHistoryController.text,
      'fp_method': fpMethod,
      'method_start_date': methodStartDateController.text,
      'next_visit': nextVisitController.text,
      'side_effects': sideEffectsController.text,
      'supplies_given': suppliesGivenController.text,
      'notes': notesController.text,
      'consent_signed': consentSigned,
      'client_type': clientType,
    };

    try {
      final response = editingRecord == null
          ? await ApiService.instance.post('/family-planning-records', data: data)
          : await ApiService.instance.put('/family-planning-records/${editingRecord!['id']}', data: data);

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
        final response = await ApiService.instance.delete('/family-planning-records/$id');
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
          '/family-planning-records/$id',
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
              _buildViewField('Barangay', record['barangay'] is Map ? record['barangay']['name'] ?? 'N/A' : record['barangay']?.toString() ?? 'N/A'),
              _buildViewField('Contact', record['contact_number'] ?? 'N/A'),
              _buildViewField('FP Method', record['fp_method'] ?? 'N/A'),
              _buildViewField('Client Type', record['client_type'] ?? 'N/A'),
              _buildViewField('Partner', record['partner_name'] ?? 'N/A'),
              _buildViewField('Next Visit', record['next_visit'] ?? 'N/A'),
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
      final response = await ApiService.instance.get('/family-planning-records/export/excel');
      if (response.statusCode == 200) {
        _showSuccess('Excel file downloaded');
      }
    } catch (e) {
      _showError('Export failed');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final response = await ApiService.instance.get('/family-planning-records/export/pdf');
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
      title: 'Family Planning Records',
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
                          DataColumn(label: Text('Barangay')),
                          DataColumn(label: Text('FP Method')),
                          DataColumn(label: Text('Client Type')),
                          DataColumn(label: Text('Next Visit')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: records.map((record) {
                          return DataRow(cells: [
                            DataCell(Text('${record['first_name']} ${record['last_name']}')),
                            DataCell(Text(record['age']?.toString() ?? '')),
                            DataCell(Text(record['barangay'] is Map ? record['barangay']['name'] ?? '' : record['barangay']?.toString() ?? '')),
                            DataCell(_buildMethodBadge(record['fp_method'])),
                            DataCell(Text(record['client_type'] ?? '')),
                            DataCell(Text(record['next_visit'] ?? '')),
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
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

  Widget _buildMethodBadge(String? method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(method ?? '', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
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
                editingRecord == null ? 'Add Family Planning Record' : 'Edit Record',
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
                color: isCompleted || isActive ? const Color(0xFF3B82F6) : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                ['Personal', 'Partner', 'Medical', 'FP Method'][index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF3B82F6) : Colors.grey,
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
        _buildTextField('Address', addressController, required: true),
        _buildTextField('Barangay', barangayController, required: true),
        _buildTextField('Contact Number', contactController, keyboardType: TextInputType.phone),
        _buildDropdown('Civil Status', civilStatus, ['Single', 'Married', 'Live-in', 'Widowed', 'Separated'], (val) => setState(() => civilStatus = val!)),
        _buildTextField('Number of Children', numberOfChildrenController, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildTextField('Partner Name', partnerNameController),
        _buildTextField('Partner Age', partnerAgeController, keyboardType: TextInputType.number),
        _buildTextField('Partner Occupation', partnerOccupationController),
        _buildTextField('Gravida', gravidaController, keyboardType: TextInputType.number),
        _buildTextField('Parity', parityController, keyboardType: TextInputType.number),
        _buildTextField('Abortion', abortionController, keyboardType: TextInputType.number),
        _buildTextField('Living Children', livingChildrenController, keyboardType: TextInputType.number),
        _buildDateField('Last Delivery Date', lastDeliveryController),
        _buildDateField('Last Menstrual Period', lmpController),
        _buildDropdown('Menstrual Cycle', menstrualCycle, ['Regular', 'Irregular'], (val) => setState(() => menstrualCycle = val!)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildTextField('Weight (kg)', weightController, keyboardType: TextInputType.number),
        _buildTextField('Height (cm)', heightController, keyboardType: TextInputType.number),
        _buildTextField('Blood Pressure', bpController),
        _buildDropdown('Blood Type', bloodType, ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (val) => setState(() => bloodType = val!)),
        _buildTextField('Medical History', medicalHistoryController, maxLines: 3),
        _buildTextField('Allergies', allergiesController, maxLines: 2),
        CheckboxListTile(
          title: const Text('Smoker'),
          value: smoker,
          onChanged: (val) => setState(() => smoker = val!),
        ),
        CheckboxListTile(
          title: const Text('Drinker'),
          value: drinker,
          onChanged: (val) => setState(() => drinker = val!),
        ),
        _buildTextField('Obstetrical History', obstetricalHistoryController, maxLines: 3),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        _buildDropdown('Client Type', clientType, ['New Acceptor', 'Current User', 'Changing Method', 'Dropout/Restart'], (val) => setState(() => clientType = val!)),
        _buildDropdown('FP Method', fpMethod, ['Pills', 'Injectable', 'IUD', 'Implant', 'Condom', 'BTL', 'NSV', 'LAM', 'Natural'], (val) => setState(() => fpMethod = val!)),
        _buildDateField('Method Start Date', methodStartDateController),
        _buildDateField('Next Visit Date', nextVisitController),
        _buildTextField('Side Effects', sideEffectsController, maxLines: 3),
        _buildTextField('Supplies Given', suppliesGivenController, maxLines: 2),
        CheckboxListTile(
          title: const Text('Consent Form Signed'),
          value: consentSigned,
          onChanged: (val) => setState(() => consentSigned = val!),
        ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  child: const Text('Save Record'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
