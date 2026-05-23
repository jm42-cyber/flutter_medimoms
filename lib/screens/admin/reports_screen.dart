import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedProgram = 'all';
  List<int> _selectedBarangays = [];
  List<int> _selectedMidwives = [];
  List<int> _selectedPatients = [];
  String _dateFrom = '';
  String _dateTo = '';

  List<dynamic> _barangays = [];
  List<dynamic> _midwives = [];
  List<dynamic> _patients = [];

  bool _loading = true;
  bool _downloading = false;
  bool _loadingPatients = false;
  bool _showFilters = true;

  String _searchBarangay = '';
  String _searchMidwife = '';
  String _searchPatient = '';

  @override
  void initState() {
    super.initState();
    _fetchBarangays();
  }

  Future<void> _fetchBarangays() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.instance.get('/admin/barangays');
      setState(() => _barangays = response.data is List ? response.data : []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load barangays: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMidwives() async {
    if (_selectedBarangays.isEmpty) {
      setState(() {
        _midwives = [];
        _selectedMidwives = [];
      });
      return;
    }

    try {
      final response = await ApiService.instance.get('/admin/midwives', queryParameters: {
        'barangay_ids': _selectedBarangays.join(','),
      });
      setState(() => _midwives = response.data is List ? response.data : []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load midwives: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchPatients() async {
    if (_selectedProgram == 'all' && _selectedBarangays.isEmpty && _selectedMidwives.isEmpty) {
      setState(() {
        _patients = [];
        _selectedPatients = [];
      });
      return;
    }

    setState(() => _loadingPatients = true);
    try {
      final params = <String, String>{};
      if (_selectedProgram != 'all') params['program'] = _selectedProgram;
      if (_selectedMidwives.isNotEmpty) params['midwife_ids'] = _selectedMidwives.join(',');
      if (_selectedBarangays.isNotEmpty) params['barangay_ids'] = _selectedBarangays.join(',');

      final response = await ApiService.instance.get('/admin/patients', queryParameters: params);
      setState(() => _patients = response.data is List ? response.data : []);
    } catch (e) {
      setState(() => _patients = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loadingPatients = false);
    }
  }

  Future<void> _downloadReport(String format) async {
    if (_selectedBarangays.isEmpty && _selectedMidwives.isEmpty && _selectedPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one filter option'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      final params = {
        'format': format,
        'program': _selectedProgram,
        'barangay_ids': _selectedBarangays.join(','),
        'midwife_ids': _selectedMidwives.join(','),
        'patient_ids': _selectedPatients.join(','),
        'date_from': _dateFrom,
        'date_to': _dateTo,
      };

      final response = await ApiService.instance.dio.get(
        '/admin/reports/download',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.${format == 'pdf' ? 'pdf' : 'xlsx'}');
      await file.writeAsBytes(response.data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${format.toUpperCase()} report downloaded!'), backgroundColor: Colors.green),
        );
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _downloading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedProgram = 'all';
      _selectedBarangays = [];
      _selectedMidwives = [];
      _selectedPatients = [];
      _dateFrom = '';
      _dateTo = '';
      _midwives = [];
      _patients = [];
    });
  }

  List<dynamic> get _filteredBarangays {
    return _barangays.where((b) => (b['name'] ?? '').toLowerCase().contains(_searchBarangay.toLowerCase())).toList();
  }

  List<dynamic> get _filteredMidwives {
    return _midwives.where((m) {
      final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.toLowerCase();
      return name.contains(_searchMidwife.toLowerCase());
    }).toList();
  }

  List<dynamic> get _filteredPatients {
    return _patients.where((p) => (p['name'] ?? '').toLowerCase().contains(_searchPatient.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list, color: Color(0xFF10B981)),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showFilters) ...[
                    _buildProgramSelector(),
                    SizedBox(height: 16),
                    _buildDateRange(),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear),
                      label: Text('Clear All Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  _buildBarangaySelector(),
                  if (_selectedBarangays.isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildMidwifeSelector(),
                  ],
                  if (_selectedProgram != 'all' || _selectedBarangays.isNotEmpty || _selectedMidwives.isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildPatientSelector(),
                  ],
                  SizedBox(height: 16),
                  _buildDownloadSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgramSelector() {
    final programs = [
      {'id': 'all', 'name': 'All Programs', 'icon': Icons.description},
      {'id': 'immunization', 'name': 'Immunization', 'icon': Icons.child_care},
      {'id': 'maternal_care', 'name': 'Maternal Care', 'icon': Icons.favorite},
      {'id': 'family_planning', 'name': 'Family Planning', 'icon': Icons.people},
      {'id': 'senior_citizen', 'name': 'Senior Citizen', 'icon': Icons.elderly},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Select Program', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          ...programs.map((program) {
            final isSelected = _selectedProgram == program['id'];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedProgram = program['id'] as String);
                    _fetchPatients();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)]) : null,
                      color: isSelected ? null : Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(program['icon'] as IconData, color: isSelected ? Colors.white : Color(0xFF6B7280), size: 20),
                        SizedBox(width: 12),
                        Text(
                          program['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDateRange() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Date Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'From',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _dateFrom = date.toIso8601String().split('T')[0]);
              }
            },
            controller: TextEditingController(text: _dateFrom),
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'To',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _dateTo = date.toIso8601String().split('T')[0]);
              }
            },
            controller: TextEditingController(text: _dateTo),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangaySelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text('Select Barangays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_selectedBarangays.length} selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search barangays...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchBarangay = value),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filteredBarangays.length,
              itemBuilder: (context, index) {
                final barangay = _filteredBarangays[index];
                final isSelected = _selectedBarangays.contains(barangay['id']);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedBarangays.remove(barangay['id']);
                        } else {
                          _selectedBarangays.add(barangay['id']);
                        }
                      });
                      _fetchMidwives();
                      _fetchPatients();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF10B981) : Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          barangay['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidwifeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services, color: Color(0xFF14B8A6)),
                  SizedBox(width: 8),
                  Text('Select Midwives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_selectedMidwives.length} selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6))),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search midwives...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchMidwife = value),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: _filteredMidwives.length,
              itemBuilder: (context, index) {
                final midwife = _filteredMidwives[index];
                final isSelected = _selectedMidwives.contains(midwife['id']);
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMidwives.remove(midwife['id']);
                          } else {
                            _selectedMidwives.add(midwife['id']);
                          }
                        });
                        _fetchPatients();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFF14B8A6) : Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${midwife['first_name']} ${midwife['last_name']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              midwife['barangay_name'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text('Select Patients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_selectedPatients.length} selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchPatient = value),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: _loadingPatients
                ? Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : _filteredPatients.isEmpty
                    ? Center(child: Text('No patients found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          final isSelected = _selectedPatients.contains(patient['id']);
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPatients.remove(patient['id']);
                                    } else {
                                      _selectedPatients.add(patient['id']);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Color(0xFF3B82F6) : Color(0xFFF9FAFB),
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
                                              patient['name'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? Colors.white : Color(0xFF1F2937),
                                              ),
                                            ),
                                            Text(
                                              patient['program'] ?? '',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            patient['midwife_name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                                            ),
                                          ),
                                          Text(
                                            patient['barangay_name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected ? Colors.white70 : Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    final programs = [
      {'id': 'all', 'name': 'All Programs'},
      {'id': 'immunization', 'name': 'Immunization'},
      {'id': 'maternal_care', 'name': 'Maternal Care'},
      {'id': 'family_planning', 'name': 'Family Planning'},
      {'id': 'senior_citizen', 'name': 'Senior Citizen'},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF10B981), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Download Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : () => _downloadReport('excel'),
                  icon: _downloading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.table_chart),
                  label: Text(_downloading ? 'Generating...' : 'Download Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : () => _downloadReport('pdf'),
                  icon: _downloading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.picture_as_pdf),
                  label: Text(_downloading ? 'Generating...' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                _buildSummaryRow('Program', programs.firstWhere((p) => p['id'] == _selectedProgram)['name']!),
                _buildSummaryRow('Barangays', _selectedBarangays.isEmpty ? 'All' : '${_selectedBarangays.length}'),
                _buildSummaryRow('Midwives', _selectedMidwives.isEmpty ? 'All' : '${_selectedMidwives.length}'),
                _buildSummaryRow('Patients', _selectedPatients.isEmpty ? 'All' : '${_selectedPatients.length}'),
                if (_dateFrom.isNotEmpty && _dateTo.isNotEmpty)
                  _buildSummaryRow('Date Range', '$_dateFrom to $_dateTo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
