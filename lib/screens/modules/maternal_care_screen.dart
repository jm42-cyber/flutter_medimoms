import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class MaternalCareScreen extends StatefulWidget {
  const MaternalCareScreen({Key? key}) : super(key: key);

  @override
  State<MaternalCareScreen> createState() => _MaternalCareScreenState();
}

class _MaternalCareScreenState extends State<MaternalCareScreen> {
  List<dynamic> records = [];
  bool isLoading = true;
  bool showForm = false;
  Map<String, dynamic>? editingRecord;
  int currentPage = 1;
  int totalPages = 1;
  String searchQuery = '';
  String filterBarangay = 'all';
  String filterStatus = 'all';

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
  
  // Step 2: Pregnancy Details
  final lmpController = TextEditingController();
  final eddController = TextEditingController();
  final gravidaController = TextEditingController();
  final parityController = TextEditingController();
  final abortionController = TextEditingController();
  final livingChildrenController = TextEditingController();
  String bloodType = 'Unknown';
  String riskLevel = 'Low';
  
  // Step 3: Prenatal Visits
  final prenatalVisitsController = TextEditingController();
  final lastVisitDateController = TextEditingController();
  final nextVisitDateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final bpController = TextEditingController();
  final fundalHeightController = TextEditingController();
  final fetalHeartRateController = TextEditingController();
  
  // Step 4: Additional Info
  final notesController = TextEditingController();
  final complicationsController = TextEditingController();
  final medicationsController = TextEditingController();
  bool ttImmunized = false;
  bool ironSupplementation = false;
  String deliveryPlan = 'Hospital';

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
    emergencyContactController.dispose();
    emergencyNameController.dispose();
    lmpController.dispose();
    eddController.dispose();
    gravidaController.dispose();
    parityController.dispose();
    abortionController.dispose();
    livingChildrenController.dispose();
    prenatalVisitsController.dispose();
    lastVisitDateController.dispose();
    nextVisitDateController.dispose();
    weightController.dispose();
    heightController.dispose();
    bpController.dispose();
    fundalHeightController.dispose();
    fetalHeartRateController.dispose();
    notesController.dispose();
    complicationsController.dispose();
    medicationsController.dispose();
    super.dispose();
  }

  Future<void> fetchRecords() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.instance.get(
        '/maternal-care-records?page=$currentPage&search=$searchQuery&barangay=$filterBarangay&status=active'
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
      print('Maternal Care fetch error: $e');
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
    emergencyContactController.text = record['emergency_contact'] ?? '';
    emergencyNameController.text = record['emergency_name'] ?? '';
    lmpController.text = record['lmp'] ?? '';
    eddController.text = record['edd'] ?? '';
    gravidaController.text = record['gravida']?.toString() ?? '';
    parityController.text = record['parity']?.toString() ?? '';
    abortionController.text = record['abortion']?.toString() ?? '';
    livingChildrenController.text = record['living_children']?.toString() ?? '';
    
    // Handle blood type with proper capitalization
    final bloodTypeValue = record['blood_type'];
    if (bloodTypeValue != null && ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodTypeValue)) {
      bloodType = bloodTypeValue;
    } else {
      bloodType = 'Unknown';
    }
    
    // Handle risk level with proper capitalization
    final riskValue = record['risk_level'];
    if (riskValue != null && ['Low', 'Medium', 'High'].contains(riskValue)) {
      riskLevel = riskValue;
    } else {
      riskLevel = 'Low';
    }
    
    // Handle delivery plan with proper capitalization
    final deliveryValue = record['delivery_plan'];
    if (deliveryValue != null && ['Hospital', 'Birthing Center', 'Home'].contains(deliveryValue)) {
      deliveryPlan = deliveryValue;
    } else {
      deliveryPlan = 'Hospital';
    }
    
    prenatalVisitsController.text = record['prenatal_visits']?.toString() ?? '';
    lastVisitDateController.text = record['last_visit_date'] ?? '';
    nextVisitDateController.text = record['next_visit_date'] ?? '';
    weightController.text = record['weight']?.toString() ?? '';
    heightController.text = record['height']?.toString() ?? '';
    bpController.text = record['blood_pressure'] ?? '';
    fundalHeightController.text = record['fundal_height']?.toString() ?? '';
    fetalHeartRateController.text = record['fetal_heart_rate']?.toString() ?? '';
    notesController.text = record['notes'] ?? '';
    complicationsController.text = record['complications'] ?? '';
    medicationsController.text = record['medications'] ?? '';
    ttImmunized = record['tt_immunized'] == 1 || record['tt_immunized'] == true;
    ironSupplementation = record['iron_supplementation'] == 1 || record['iron_supplementation'] == true;
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
    emergencyContactController.clear();
    emergencyNameController.clear();
    lmpController.clear();
    eddController.clear();
    gravidaController.clear();
    parityController.clear();
    abortionController.clear();
    livingChildrenController.clear();
    prenatalVisitsController.clear();
    lastVisitDateController.clear();
    nextVisitDateController.clear();
    weightController.clear();
    heightController.clear();
    bpController.clear();
    fundalHeightController.clear();
    fetalHeartRateController.clear();
    notesController.clear();
    complicationsController.clear();
    medicationsController.clear();
    bloodType = 'Unknown';
    riskLevel = 'Low';
    ttImmunized = false;
    ironSupplementation = false;
    deliveryPlan = 'Hospital';
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
      'emergency_contact': emergencyContactController.text,
      'emergency_name': emergencyNameController.text,
      'lmp': lmpController.text,
      'edd': eddController.text,
      'gravida': int.tryParse(gravidaController.text),
      'parity': int.tryParse(parityController.text),
      'abortion': int.tryParse(abortionController.text),
      'living_children': int.tryParse(livingChildrenController.text),
      'blood_type': bloodType,
      'risk_level': riskLevel,
      'prenatal_visits': int.tryParse(prenatalVisitsController.text),
      'last_visit_date': lastVisitDateController.text,
      'next_visit_date': nextVisitDateController.text,
      'weight': double.tryParse(weightController.text),
      'height': double.tryParse(heightController.text),
      'blood_pressure': bpController.text,
      'fundal_height': double.tryParse(fundalHeightController.text),
      'fetal_heart_rate': int.tryParse(fetalHeartRateController.text),
      'notes': notesController.text,
      'complications': complicationsController.text,
      'medications': medicationsController.text,
      'tt_immunized': ttImmunized,
      'iron_supplementation': ironSupplementation,
      'delivery_plan': deliveryPlan,
    };

    try {
      final response = editingRecord == null
          ? await ApiService.instance.post('/maternal-care-records', data: data)
          : await ApiService.instance.put('/maternal-care-records/${editingRecord!['id']}', data: data);

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
        final response = await ApiService.instance.delete('/maternal-care-records/$id');
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
          '/maternal-care-records/$id',
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
              _buildViewField('LMP', record['lmp'] ?? 'N/A'),
              _buildViewField('EDD', record['edd'] ?? 'N/A'),
              _buildViewField('Blood Type', record['blood_type'] ?? 'N/A'),
              _buildViewField('Risk Level', record['risk_level'] ?? 'N/A'),
              _buildViewField('Gravida', record['gravida']?.toString() ?? 'N/A'),
              _buildViewField('Parity', record['parity']?.toString() ?? 'N/A'),
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
      final response = await ApiService.instance.get('/maternal-care-records/export/excel');
      if (response.statusCode == 200) {
        _showSuccess('Excel file downloaded');
      }
    } catch (e) {
      _showError('Export failed');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final response = await ApiService.instance.get('/maternal-care-records/export/pdf');
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
      title: 'Maternal Care Records',
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
                          DataColumn(label: Text('LMP')),
                          DataColumn(label: Text('EDD')),
                          DataColumn(label: Text('Risk Level')),
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
                            DataCell(Text(
                              recordData['barangay'] is Map 
                                ? (recordData['barangay']['name']?.toString() ?? '') 
                                : (recordData['barangay']?.toString() ?? '')
                            )),
                            DataCell(Text(recordData['lmp']?.toString() ?? '')),
                            DataCell(Text(recordData['edd']?.toString() ?? '')),
                            DataCell(_buildRiskBadge(recordData['risk_level']?.toString())),
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
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

  Widget _buildRiskBadge(String? risk) {
    final color = risk == 'High' ? Colors.red : risk == 'Medium' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(risk ?? 'Low', style: TextStyle(color: color, fontSize: 12)),
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
                editingRecord == null ? 'Add Maternal Care Record' : 'Edit Record',
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
                color: isCompleted || isActive ? const Color(0xFFEC4899) : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                ['Personal Info', 'Pregnancy', 'Prenatal', 'Additional'][index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFFEC4899) : Colors.grey,
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
        _buildTextField('Age', ageController, keyboardType: TextInputType.number),
        _buildTextField('Address', addressController, required: true),
        _buildTextField('Barangay', barangayController, required: true),
        _buildTextField('Contact Number', contactController, keyboardType: TextInputType.phone),
        _buildTextField('Emergency Contact Name', emergencyNameController),
        _buildTextField('Emergency Contact Number', emergencyContactController, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildDateField('Last Menstrual Period (LMP)', lmpController),
        _buildDateField('Expected Date of Delivery (EDD)', eddController),
        _buildTextField('Gravida', gravidaController, keyboardType: TextInputType.number),
        _buildTextField('Parity', parityController, keyboardType: TextInputType.number),
        _buildTextField('Abortion', abortionController, keyboardType: TextInputType.number),
        _buildTextField('Living Children', livingChildrenController, keyboardType: TextInputType.number),
        _buildDropdown('Blood Type', bloodType, ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (val) => setState(() => bloodType = val!)),
        _buildDropdown('Risk Level', riskLevel, ['Low', 'Medium', 'High'], (val) => setState(() => riskLevel = val!)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildTextField('Number of Prenatal Visits', prenatalVisitsController, keyboardType: TextInputType.number),
        _buildDateField('Last Visit Date', lastVisitDateController),
        _buildDateField('Next Visit Date', nextVisitDateController),
        _buildTextField('Weight (kg)', weightController, keyboardType: TextInputType.number),
        _buildTextField('Height (cm)', heightController, keyboardType: TextInputType.number),
        _buildTextField('Blood Pressure', bpController),
        _buildTextField('Fundal Height (cm)', fundalHeightController, keyboardType: TextInputType.number),
        _buildTextField('Fetal Heart Rate (bpm)', fetalHeartRateController, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('TT Immunized'),
          value: ttImmunized,
          onChanged: (val) => setState(() => ttImmunized = val!),
        ),
        CheckboxListTile(
          title: const Text('Iron Supplementation'),
          value: ironSupplementation,
          onChanged: (val) => setState(() => ironSupplementation = val!),
        ),
        _buildDropdown('Delivery Plan', deliveryPlan, ['Hospital', 'Birthing Center', 'Home'], (val) => setState(() => deliveryPlan = val!)),
        _buildTextField('Complications', complicationsController, maxLines: 3),
        _buildTextField('Medications', medicationsController, maxLines: 3),
        _buildTextField('Notes', notesController, maxLines: 4),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
                  child: const Text('Save Record'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
