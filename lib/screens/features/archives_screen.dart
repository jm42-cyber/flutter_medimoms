import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_layout.dart';

class ArchivesScreen extends StatefulWidget {
  const ArchivesScreen({Key? key}) : super(key: key);

  @override
  State<ArchivesScreen> createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<ArchivesScreen> {
  List<dynamic> records = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedProgram = 'immunization';
  int currentPage = 1;
  int totalPages = 1;
  
  // Stats
  Map<String, int> stats = {
    'total': 0,
    'immunization': 0,
    'maternal': 0,
    'family_planning': 0,
    'senior': 0,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    fetchStats();
    fetchRecords();
  }

  Future<void> fetchStats() async {
    try {
      int immunizationCount = 0;
      int maternalCount = 0;
      int familyPlanningCount = 0;
      int seniorCount = 0;

      try {
        final immunizationRes = await ApiService.instance.get('/immunization-records?status=archived&per_page=1');
        if (immunizationRes.statusCode == 200 && immunizationRes.data != null) {
          final data = immunizationRes.data;
          immunizationCount = data['total'] ?? 0;
        }
      } catch (e) {
        print('Error fetching immunization stats: $e');
      }

      try {
        final maternalRes = await ApiService.instance.get('/maternal-care-records?status=archived&per_page=1');
        if (maternalRes.statusCode == 200 && maternalRes.data != null) {
          final data = maternalRes.data;
          maternalCount = data['total'] ?? 0;
        }
      } catch (e) {
        print('Error fetching maternal stats: $e');
      }

      try {
        final familyPlanningRes = await ApiService.instance.get('/family-planning-records?status=archived&per_page=1');
        if (familyPlanningRes.statusCode == 200 && familyPlanningRes.data != null) {
          final data = familyPlanningRes.data;
          familyPlanningCount = data['total'] ?? 0;
        }
      } catch (e) {
        print('Error fetching family planning stats: $e');
      }

      try {
        final seniorRes = await ApiService.instance.get('/senior-citizen-records?status=archived&per_page=1');
        if (seniorRes.statusCode == 200 && seniorRes.data != null) {
          final data = seniorRes.data;
          seniorCount = data['total'] ?? 0;
        }
      } catch (e) {
        print('Error fetching senior stats: $e');
      }

      if (mounted) {
        setState(() {
          stats['immunization'] = immunizationCount;
          stats['maternal'] = maternalCount;
          stats['family_planning'] = familyPlanningCount;
          stats['senior'] = seniorCount;
          stats['total'] = immunizationCount + maternalCount + familyPlanningCount + seniorCount;
        });
      }
    } catch (e) {
      print('Error in fetchStats: $e');
      if (mounted) {
        _showError('Failed to load stats');
      }
    }
  }

  Future<void> fetchRecords() async {
    setState(() => isLoading = true);
    try {
      String endpoint = '';
      switch (selectedProgram) {
        case 'immunization':
          endpoint = '/immunization-records';
          break;
        case 'maternal':
          endpoint = '/maternal-care-records';
          break;
        case 'family_planning':
          endpoint = '/family-planning-records';
          break;
        case 'senior':
          endpoint = '/senior-citizen-records';
          break;
      }

      final response = await ApiService.instance.get('$endpoint?status=archived&page=$currentPage&search=$searchQuery');
      
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          records = data['data'] ?? [];
          totalPages = data['last_page'] ?? 1;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load records');
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

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Archived Records',
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([fetchStats(), fetchRecords()]);
        },
        child: Column(
          children: [
            _buildStatsCards(),
            const SizedBox(height: 16),
            _buildProgramTabs(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', stats['total']!, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Immunization', stats['immunization']!, Colors.cyan)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Maternal', stats['maternal']!, Colors.pink)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Family Planning', stats['family_planning']!, Colors.purple)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Senior', stats['senior']!, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgramTabs() {
    final programs = [
      {'value': 'immunization', 'label': 'Immunization', 'icon': Icons.vaccines, 'color': Colors.cyan},
      {'value': 'maternal', 'label': 'Maternal Care', 'icon': Icons.pregnant_woman, 'color': Colors.pink},
      {'value': 'family_planning', 'label': 'Family Planning', 'icon': Icons.family_restroom, 'color': Colors.purple},
      {'value': 'senior', 'label': 'Senior Citizen', 'icon': Icons.elderly, 'color': Colors.orange},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: programs.map((program) {
          final isSelected = selectedProgram == program['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedProgram = program['value'] as String;
                  currentPage = 1;
                });
                fetchRecords();
              },
              icon: Icon(program['icon'] as IconData, size: 20),
              label: Text(program['label'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? program['color'] as Color : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                elevation: isSelected ? 4 : 0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search by name...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() => searchQuery = value);
        fetchRecords();
      },
    );
  }

  Widget _buildTable() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return const Center(child: Text('No archived records found'));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Sex')),
                DataColumn(label: Text('Barangay')),
                DataColumn(label: Text('Archive Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: records.map((record) {
                return DataRow(cells: [
                  DataCell(Text('${record['first_name']} ${record['last_name']}')),
                  DataCell(Text(record['sex'] ?? '')),
                  DataCell(Text(record['barangay']?['name'] ?? '')),
                  DataCell(Text(record['updated_at'] != null 
                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(record['updated_at']))
                    : 'N/A')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, size: 20, color: Colors.green),
                        onPressed: () => _restoreRecord(record['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                        onPressed: () => _deleteRecord(record['id']),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
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
              fetchRecords();
            } : null,
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () {
              setState(() => currentPage++);
              fetchRecords();
            } : null,
          ),
        ],
      ),
    );
  }

  Future<void> _restoreRecord(int id) async {
    try {
      String endpoint = '';
      switch (selectedProgram) {
        case 'immunization':
          endpoint = '/immunization-records/$id/toggle-status';
          break;
        case 'maternal':
          endpoint = '/maternal-care-records/$id/toggle-status';
          break;
        case 'family_planning':
          endpoint = '/family-planning-records/$id/toggle-status';
          break;
        case 'senior':
          endpoint = '/senior-citizen-records/$id/toggle-status';
          break;
      }

      final response = await ApiService.instance.post(endpoint);
      if (response.statusCode == 200) {
        _showSuccess('Record restored successfully');
        fetchRecords();
        fetchStats();
      }
    } catch (e) {
      _showError('Failed to restore record');
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: const Text('Are you sure you want to permanently delete this record? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        String endpoint = '';
        switch (selectedProgram) {
          case 'immunization':
            endpoint = '/immunization-records/$id';
            break;
          case 'maternal':
            endpoint = '/maternal-care-records/$id';
            break;
          case 'family_planning':
            endpoint = '/family-planning-records/$id';
            break;
          case 'senior':
            endpoint = '/senior-citizen-records/$id';
            break;
        }

        final response = await ApiService.instance.delete(endpoint);
        if (response.statusCode == 200) {
          _showSuccess('Record permanently deleted');
          fetchRecords();
          fetchStats();
        }
      } catch (e) {
        _showError('Failed to delete record');
      }
    }
  }
}
