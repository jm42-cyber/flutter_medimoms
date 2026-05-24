import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _showFilters = false;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _perPage = 15;
  int _total = 0;
  int _from = 0;
  int _to = 0;

  // Filters
  String _searchQuery = '';
  String _selectedAction = '';
  String _selectedTable = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final List<String> _actions = [
    'created',
    'updated',
    'deleted',
    'login',
    'logout',
    'approved',
    'rejected'
  ];

  final List<String> _tables = [
    'user_sessions',
    'immunization_records',
    'maternal_care_records',
    'family_planning_records',
    'senior_citizen_records',
    'users',
    'barangays',
    'appointments',
    'alerts'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);

    try {
      final params = {
        'page': _currentPage.toString(),
        'per_page': _perPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedAction.isNotEmpty) 'action': _selectedAction,
        if (_selectedTable.isNotEmpty) 'table_name': _selectedTable,
        if (_dateFrom != null)
          'date_from': DateFormat('yyyy-MM-dd').format(_dateFrom!),
        if (_dateTo != null) 'date_to': DateFormat('yyyy-MM-dd').format(_dateTo!),
      };

      final response = await _apiService.get('/audit-logs', queryParameters: params);
      final data = response.data;

      setState(() {
        _logs = List<Map<String, dynamic>>.from(data['data'] ?? []);
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
        _perPage = data['per_page'] ?? 15;
        _total = data['total'] ?? 0;
        _from = data['from'] ?? 0;
        _to = data['to'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit logs: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() => _currentPage = 1);
    _fetchLogs();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedAction = '';
      _selectedTable = '';
      _dateFrom = null;
      _dateTo = null;
      _currentPage = 1;
      _searchController.clear();
    });
    _fetchLogs();
  }

  void _goToPage() {
    final page = int.tryParse(_pageController.text);
    if (page != null && page >= 1 && page <= _lastPage) {
      setState(() => _currentPage = page);
      _pageController.clear();
      _fetchLogs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a page between 1 and $_lastPage')),
      );
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatTableName(String tableName) {
    return tableName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Audit Log Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailField('Log ID', '#${log['id']}'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailField(
                              'Timestamp',
                              log['timestamp'] != null
                                  ? DateFormat('MMM dd, yyyy HH:mm:ss')
                                      .format(DateTime.parse(log['timestamp']))
                                  : 'N/A',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailField(
                        'User',
                        log['user']?['full_name']?.toString() ?? 'System',
                        subtitle: log['user']?['email']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Action',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getActionColor(log['action'])
                                        .withOpacity(0.1),
                                    border: Border.all(
                                      color: _getActionColor(log['action']),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    log['action']?.toString().toUpperCase() ?? 'UNKNOWN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getActionColor(log['action']?.toString() ?? ''),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailField(
                              'Table Name',
                              _formatTableName(log['table_name']?.toString() ?? 'N/A'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailField(
                        'Record ID',
                        '#${log['record_id']?.toString() ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: const Color(0xFF10B981),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Logs',
                    _total.toString(),
                    Icons.article_outlined,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Current Page',
                    '$_currentPage / $_lastPage',
                    Icons.layers_outlined,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Filters
          if (_showFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _searchQuery = value,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedAction.isEmpty ? null : _selectedAction,
                    decoration: InputDecoration(
                      labelText: 'Action',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Actions')),
                      ..._actions.map((action) => DropdownMenuItem(
                            value: action,
                            child: Text(action[0].toUpperCase() + action.substring(1)),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedAction = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedTable.isEmpty ? null : _selectedTable,
                    decoration: InputDecoration(
                      labelText: 'Table',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Tables')),
                      ..._tables.map((table) => DropdownMenuItem(
                            value: table,
                            child: Text(_formatTableName(table)),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedTable = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date From',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _dateFrom != null
                                  ? DateFormat('MMM dd, yyyy').format(_dateFrom!)
                                  : 'Select date',
                              style: TextStyle(
                                color: _dateFrom != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date To',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _dateTo != null
                                  ? DateFormat('MMM dd, yyyy').format(_dateTo!)
                                  : 'Select date',
                              style: TextStyle(
                                color: _dateTo != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_rounded),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No audit logs found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showLogDetails(log),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getActionColor(log['action']?.toString() ?? '')
                                                .withOpacity(0.1),
                                            border: Border.all(
                                              color: _getActionColor(log['action']?.toString() ?? ''),
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            log['action']?.toString().toUpperCase() ?? 'UNKNOWN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getActionColor(log['action']?.toString() ?? ''),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          log['timestamp'] != null
                                              ? DateFormat('MMM dd, HH:mm').format(
                                                  DateTime.parse(log['timestamp']),
                                                )
                                              : 'N/A',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF10B981).withOpacity(0.1),
                                          child: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log['user']?['full_name']?.toString() ?? 'System',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                log['user']?['email']?.toString() ?? 'N/A',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatTableName(log['table_name']?.toString() ?? 'N/A'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'ID: #${log['record_id']?.toString() ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Pagination
          if (!_isLoading && _logs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Showing $_from-$_to of $_total',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _fetchLogs();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_currentPage / $_lastPage',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() => _currentPage++);
                            _fetchLogs();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    height: 32,
                    child: TextField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Page',
                        hintStyle: const TextStyle(fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _goToPage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _goToPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Go', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }
}
