import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class AllPatientsScreen extends StatefulWidget {
  const AllPatientsScreen({super.key});

  @override
  State<AllPatientsScreen> createState() => _AllPatientsScreenState();
}

class _AllPatientsScreenState extends State<AllPatientsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  
  final _searchController = TextEditingController();
  String _selectedProgram = 'all';
  int? _selectedBarangayId;
  bool _showFilters = false;
  
  // Stats
  int _totalPatients = 0;
  int _immunizationCount = 0;
  int _familyPlanningCount = 0;
  int _maternalCareCount = 0;
  int _seniorCitizenCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllPatients() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch from all program endpoints with per_page=1000 to get all records
      final responses = await Future.wait([
        ApiService.instance.get('/immunization-records?status=active&per_page=1000'),
        ApiService.instance.get('/family-planning-records?status=active&per_page=1000'),
        ApiService.instance.get('/maternal-care-records?status=active&per_page=1000'),
        ApiService.instance.get('/senior-citizen-records?status=active&per_page=1000'),
      ]);

      final List<Map<String, dynamic>> allPatients = [];

      // Process immunization records
      if (responses[0].statusCode == 200) {
        final responseData = responses[0].data;
        final data = responseData is Map && responseData.containsKey('data') 
            ? responseData['data'] as List 
            : responseData as List;
        for (var record in data) {
          allPatients.add({
            ...record,
            'program': 'Immunization',
            'program_color': const Color(0xFF10B981),
          });
        }
      }

      // Process family planning records
      if (responses[1].statusCode == 200) {
        final responseData = responses[1].data;
        final data = responseData is Map && responseData.containsKey('data') 
            ? responseData['data'] as List 
            : responseData as List;
        for (var record in data) {
          allPatients.add({
            ...record,
            'program': 'Family Planning',
            'program_color': const Color(0xFF3B82F6),
          });
        }
      }

      // Process maternal care records
      if (responses[2].statusCode == 200) {
        final responseData = responses[2].data;
        final data = responseData is Map && responseData.containsKey('data') 
            ? responseData['data'] as List 
            : responseData as List;
        for (var record in data) {
          allPatients.add({
            ...record,
            'program': 'Maternal Care',
            'program_color': const Color(0xFFEC4899),
          });
        }
      }

      // Process senior citizen records
      if (responses[3].statusCode == 200) {
        final responseData = responses[3].data;
        final data = responseData is Map && responseData.containsKey('data') 
            ? responseData['data'] as List 
            : responseData as List;
        for (var record in data) {
          allPatients.add({
            ...record,
            'program': 'Senior Citizen',
            'program_color': const Color(0xFFF97316),
          });
        }
      }

      print('📊 All Patients loaded: ${allPatients.length} total');
      print('  - Immunization: ${allPatients.where((p) => p['program'] == 'Immunization').length}');
      print('  - Family Planning: ${allPatients.where((p) => p['program'] == 'Family Planning').length}');
      print('  - Maternal Care: ${allPatients.where((p) => p['program'] == 'Maternal Care').length}');
      print('  - Senior Citizen: ${allPatients.where((p) => p['program'] == 'Senior Citizen').length}');

      setState(() {
        _allPatients = allPatients;
        _filteredPatients = allPatients;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ All Patients fetch error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateStats() {
    _totalPatients = _filteredPatients.length;
    _immunizationCount = _filteredPatients.where((p) => p['program'] == 'Immunization').length;
    _familyPlanningCount = _filteredPatients.where((p) => p['program'] == 'Family Planning').length;
    _maternalCareCount = _filteredPatients.where((p) => p['program'] == 'Maternal Care').length;
    _seniorCitizenCount = _filteredPatients.where((p) => p['program'] == 'Senior Citizen').length;
  }

  void _applyFilters() {
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        // Search filter
        final searchTerm = _searchController.text.toLowerCase();
        final fullName = '${patient['first_name'] ?? ''} ${patient['middle_name'] ?? ''} ${patient['last_name'] ?? ''}'.toLowerCase();
        final matchesSearch = searchTerm.isEmpty || 
            fullName.contains(searchTerm) || 
            (patient['contact_no']?.toString().toLowerCase().contains(searchTerm) ?? false);

        // Program filter
        final matchesProgram = _selectedProgram == 'all' || patient['program'] == _selectedProgram;

        // Barangay filter
        final matchesBarangay = _selectedBarangayId == null || 
            (patient['barangay'] != null && patient['barangay']['id'] == _selectedBarangayId);

        return matchesSearch && matchesProgram && matchesBarangay;
      }).toList();
      
      _calculateStats();
    });
  }

  void _showAddRecordModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Program', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Choose a program to add a new patient record', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildProgramCard('Immunization', Icons.child_care, const Color(0xFF0EA5E9), '/immunization'),
                  _buildProgramCard('Family Planning', Icons.favorite, const Color(0xFF10B981), '/family-planning'),
                  _buildProgramCard('Maternal Care', Icons.pregnant_woman, const Color(0xFFEC4899), '/maternal-care'),
                  _buildProgramCard('Senior Citizen', Icons.elderly, const Color(0xFFF97316), '/senior-citizen'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userBarangays = authProvider.user?.barangays ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        title: const Text('All Patients', style: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
            onPressed: _showAddRecordModal,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchAllPatients,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Search patients by name or contact...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 24),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : IconButton(
                            icon: Icon(
                              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                              color: const Color(0xFF10B981),
                            ),
                            onPressed: () => setState(() => _showFilters = !_showFilters),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _buildStatCard('Total Patients', _totalPatients, Icons.people, const Color(0xFF10B981)),
                  _buildStatCard('Immunization', _immunizationCount, Icons.child_care, const Color(0xFF0EA5E9)),
                  _buildStatCard('Family Planning', _familyPlanningCount, Icons.favorite, const Color(0xFF8B5CF6)),
                  _buildStatCard('Maternal Care', _maternalCareCount, Icons.pregnant_woman, const Color(0xFFEC4899)),
                  _buildStatCard('Senior Citizen', _seniorCitizenCount, Icons.elderly, const Color(0xFFF97316)),
                ],
              ),
              const SizedBox(height: 20),

              // Filters Section (Collapsible)
              if (_showFilters)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedProgram = 'all';
                                _selectedBarangayId = null;
                              });
                              _applyFilters();
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedProgram,
                        decoration: InputDecoration(
                          labelText: 'Program',
                          prefixIcon: const Icon(Icons.medical_services_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Programs')),
                          DropdownMenuItem(value: 'Immunization', child: Text('Immunization')),
                          DropdownMenuItem(value: 'Family Planning', child: Text('Family Planning')),
                          DropdownMenuItem(value: 'Maternal Care', child: Text('Maternal Care')),
                          DropdownMenuItem(value: 'Senior Citizen', child: Text('Senior Citizen')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedProgram = value!);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _selectedBarangayId,
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Barangays')),
                          ...userBarangays.map((b) => DropdownMenuItem(
                            value: b['id'],
                            child: Text(b['name']),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedBarangayId = value);
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              if (_showFilters) const SizedBox(height: 20),

              // Patients List
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading patients...',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredPatients.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No patients found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.list_rounded, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_filteredPatients.length} Patient${_filteredPatients.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredPatients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return _buildPatientTile(patient);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
            const SizedBox(height: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(Map<String, dynamic> patient) {
    final fullName = '${patient['first_name'] ?? ''} ${patient['middle_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();
    final sex = patient['sex'] ?? 'Unknown';
    final age = patient['age']?.toString() ?? 'N/A';
    final program = patient['program'] ?? 'Unknown';
    final programColor = patient['program_color'] ?? Colors.grey;
    final barangay = patient['barangay']?['name'] ?? 'N/A';
    final contact = patient['contact_no'] ?? 'N/A';

    return InkWell(
      onTap: () => _showPatientDetails(patient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: sex == 'Male'
                      ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                      : [const Color(0xFFEC4899), const Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (sex == 'Male' ? const Color(0xFF3B82F6) : const Color(0xFFEC4899)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sex == 'Male'
                              ? const Color(0xFF3B82F6).withOpacity(0.1)
                              : const Color(0xFFEC4899).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sex,
                          style: TextStyle(
                            fontSize: 10,
                            color: sex == 'Male' ? const Color(0xFF3B82F6) : const Color(0xFFEC4899),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Age: $age',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: programColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: programColor.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getProgramIcon(program),
                          size: 12,
                          color: programColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          program,
                          style: TextStyle(
                            fontSize: 10,
                            color: programColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          barangay,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        contact,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  IconData _getProgramIcon(String program) {
    switch (program) {
      case 'Immunization':
        return Icons.child_care;
      case 'Family Planning':
        return Icons.favorite;
      case 'Maternal Care':
        return Icons.pregnant_woman;
      case 'Senior Citizen':
        return Icons.elderly;
      default:
        return Icons.person;
    }
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    final fullName = '${patient['first_name'] ?? ''} ${patient['middle_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim();
    final sex = patient['sex'] ?? 'Unknown';
    final program = patient['program'] ?? 'Unknown';
    final programColor = patient['program_color'] ?? Colors.grey;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [programColor, programColor.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailCard('Personal Information', [
                      _buildDetailItem(Icons.person_rounded, 'Full Name', fullName),
                      _buildDetailItem(
                        sex == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                        'Sex',
                        sex,
                      ),
                      _buildDetailItem(Icons.cake_rounded, 'Age', patient['age']?.toString() ?? 'N/A'),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailCard('Program & Location', [
                      _buildDetailItem(_getProgramIcon(program), 'Program', program),
                      _buildDetailItem(Icons.location_on_rounded, 'Barangay', patient['barangay']?['name'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailCard('Contact Information', [
                      _buildDetailItem(Icons.phone_rounded, 'Contact Number', patient['contact_no'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
