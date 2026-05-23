import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class PendingAccountsScreen extends StatefulWidget {
  const PendingAccountsScreen({Key? key}) : super(key: key);

  @override
  State<PendingAccountsScreen> createState() => _PendingAccountsScreenState();
}

class _PendingAccountsScreenState extends State<PendingAccountsScreen> {
  List<dynamic> _accounts = [];
  List<dynamic> _barangays = [];
  bool _loading = true;
  String _searchQuery = '';
  int? _processingId;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final accountsResponse = await ApiService.instance.get('/admin/dashboard/pending-approvals');
      final barangaysResponse = await ApiService.instance.get('/barangays');
      
      final barangaysData = barangaysResponse.data is Map && barangaysResponse.data.containsKey('data')
          ? barangaysResponse.data['data']
          : (barangaysResponse.data is List ? barangaysResponse.data : []);
      
      setState(() {
        _accounts = accountsResponse.data is List ? accountsResponse.data : [];
        _barangays = barangaysData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredAccounts {
    var filtered = _accounts.where((account) {
      final name = '${account['first_name'] ?? ''} ${account['last_name'] ?? ''}'.toLowerCase();
      final email = (account['email'] ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'newest':
          return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
        case 'oldest':
          return DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']));
        case 'name-asc':
          return '${a['first_name']} ${a['last_name']}'.compareTo('${b['first_name']} ${b['last_name']}');
        case 'name-desc':
          return '${b['first_name']} ${b['last_name']}'.compareTo('${a['first_name']} ${a['last_name']}');
        default:
          return 0;
      }
    });

    return filtered;
  }

  String _getWaitingTime(String createdAt) {
    final created = DateTime.parse(createdAt);
    final now = DateTime.now();
    final diffDays = now.difference(created).inDays;
    
    if (diffDays == 0) return 'Today';
    if (diffDays >= 1 && diffDays <= 6) return '${diffDays}d ago';
    return '${diffDays}d ago';
  }

  Color _getWaitingColor(String createdAt) {
    final created = DateTime.parse(createdAt);
    final now = DateTime.now();
    final diffDays = now.difference(created).inDays;
    
    if (diffDays == 0) return Color(0xFF10B981);
    if (diffDays >= 1 && diffDays <= 6) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  void _showApprovalModal(dynamic account) {
    List<int> selectedBarangays = [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business, color: Color(0xFF10B981), size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assign Barangays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${account['first_name']} ${account['last_name']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select up to 3 barangays to assign to this midwife before approving.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _barangays.length,
                  itemBuilder: (context, index) {
                    final barangay = _barangays[index];
                    final isSelected = selectedBarangays.contains(barangay['id']);
                    final isDisabled = !isSelected && selectedBarangays.length >= 3;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled ? null : () {
                          setModalState(() {
                            if (isSelected) {
                              selectedBarangays.remove(barangay['id']);
                            } else {
                              selectedBarangays.add(barangay['id']);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF10B981).withOpacity(0.1) : Colors.white,
                            border: Border.all(
                              color: isSelected ? Color(0xFF10B981) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              barangay['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Color(0xFF10B981) : (isDisabled ? Colors.grey : Color(0xFF1F2937)),
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Text(
                      selectedBarangays.isEmpty 
                          ? 'At least 1 barangay is required' 
                          : '${selectedBarangays.length}/3 barangays selected',
                      style: TextStyle(
                        fontSize: 11,
                        color: selectedBarangays.isEmpty ? Colors.red : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectedBarangays.isEmpty ? null : () {
                              Navigator.pop(context);
                              _handleApprove(account['id'], selectedBarangays);
                            },
                            icon: Icon(Icons.check_circle, size: 18),
                            label: Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _handleApprove(int accountId, List<int> barangays) async {
    setState(() => _processingId = accountId);
    try {
      await ApiService.instance.post('/users/$accountId/approve', data: {'barangays': barangays});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account approved successfully!'), backgroundColor: Colors.green),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _processingId = null);
    }
  }

  Future<void> _handleReject(int accountId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Application'),
        content: Text('Are you sure you want to reject $name\'s application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _processingId = accountId);
      try {
        await ApiService.instance.post('/users/$accountId/reject', data: {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account rejected'), backgroundColor: Colors.orange),
        );
        _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _processingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _filteredAccounts;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Pending Accounts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Pending', _accounts.length, Color(0xFF10B981), Icons.people),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Today', _accounts.where((a) => _getWaitingTime(a['created_at']) == 'Today').length, Color(0xFF3B82F6), Icons.today),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Overdue', _accounts.where((a) => _getWaitingColor(a['created_at']) == Color(0xFFEF4444)).length, Color(0xFFEF4444), Icons.warning),
                ),
              ],
            ),
          ),
          // Search and Sort
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF9FAFB),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                    DropdownMenuItem(value: 'name-asc', child: Text('Name A-Z')),
                    DropdownMenuItem(value: 'name-desc', child: Text('Name Z-A')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v!),
                ),
              ],
            ),
          ),
          // Accounts List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : filteredAccounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 16),
                            Text('No pending accounts', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredAccounts.length,
                        itemBuilder: (context, index) => _buildAccountCard(filteredAccounts[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAccountCard(dynamic account) {
    final firstName = account['first_name'] ?? '';
    final lastName = account['last_name'] ?? '';
    final email = account['email'] ?? '';
    final contactNumber = account['contact_number'] ?? '';
    final createdAt = account['created_at'] ?? '';
    final waitingTime = _getWaitingTime(createdAt);
    final waitingColor = _getWaitingColor(createdAt);
    final initials = _getInitials(firstName, lastName);
    final isProcessing = _processingId == account['id'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF10B981),
                  child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$firstName $lastName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      SizedBox(height: 2),
                      Text(email, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: waitingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(waitingTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: waitingColor)),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text(contactNumber, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text('Applied ${DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAt))}', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => _showApprovalModal(account),
                    icon: isProcessing ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.check_circle, size: 16),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : () => _handleReject(account['id'], '$firstName $lastName'),
                    icon: Icon(Icons.cancel, size: 16),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFEF4444),
                      side: BorderSide(color: Color(0xFFEF4444)),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
