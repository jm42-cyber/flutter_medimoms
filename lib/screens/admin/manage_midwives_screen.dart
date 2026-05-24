import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ManageMidwivesScreen extends StatefulWidget {
  const ManageMidwivesScreen({Key? key}) : super(key: key);

  @override
  State<ManageMidwivesScreen> createState() => _ManageMidwivesScreenState();
}

class _ManageMidwivesScreenState extends State<ManageMidwivesScreen> {
  List<dynamic> _midwives = [];
  List<dynamic> _barangays = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    print('🎬 ManageMidwivesScreen initState called');
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      print('🚀 Starting to fetch data...');
      // Fetch all users with role=midwife (includes all statuses)
      final midwivesResponse = await ApiService.instance.get('/users?role=midwife');
      print('👥 Midwives Response: ${midwivesResponse.statusCode}');
      
      final barangaysResponse = await ApiService.instance.get('/barangays');
      print('🏘️ Barangays Response: ${barangaysResponse.statusCode}');
      print('🏘️ Barangays Raw Data: ${barangaysResponse.data}');
      print('🏘️ Barangays Data Type: ${barangaysResponse.data.runtimeType}');
      
      if (midwivesResponse.statusCode == 200 && barangaysResponse.statusCode == 200) {
        // Handle paginated response from /users endpoint
        final midwivesData = midwivesResponse.data is Map && midwivesResponse.data.containsKey('data')
            ? midwivesResponse.data['data']
            : (midwivesResponse.data is List ? midwivesResponse.data : []);
        
        // Barangays API returns {data: [...]} format
        final barangaysData = barangaysResponse.data is Map && barangaysResponse.data.containsKey('data')
            ? barangaysResponse.data['data']
            : (barangaysResponse.data is List ? barangaysResponse.data : []);
        
        print('📊 Midwives parsed: ${midwivesData.length}');
        print('📊 Barangays parsed: ${barangaysData.length}');
        
        // Fetch barangays for each midwife
        for (var midwife in midwivesData) {
          try {
            final barangayResponse = await ApiService.instance.get('/users/${midwife['id']}');
            if (barangayResponse.statusCode == 200 && barangayResponse.data['barangays'] != null) {
              midwife['barangays'] = barangayResponse.data['barangays'];
            }
          } catch (e) {
            print('Failed to fetch barangays for midwife ${midwife['id']}: $e');
          }
        }
        
        setState(() {
          _midwives = midwivesData;
          _barangays = barangaysData;
        });
      }
    } catch (e) {
      print('❌ Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredMidwives {
    print('🔍 Filter Status: $_filterStatus');
    print('🔍 Total Midwives: ${_midwives.length}');
    
    // Debug: print ALL fields from first midwife
    if (_midwives.isNotEmpty) {
      print('🔑 ALL FIELDS IN MIDWIFE OBJECT: ${_midwives[0].keys.toList()}');
    }
    
    final filtered = _midwives.where((midwife) {
      final matchesSearch = _searchQuery.isEmpty ||
          midwife['first_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          midwife['last_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          midwife['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final midwifeStatus = midwife['status'];
      // Map 'active' filter to 'approved' status in backend
      final filterToMatch = _filterStatus == 'active' ? 'approved' : _filterStatus;
      final matchesStatus = _filterStatus == 'all' || midwifeStatus == filterToMatch;
      
      print('👤 ${midwife['first_name']} - Status: $midwifeStatus - Matches: $matchesStatus');
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    print('📊 Filtered Count: ${filtered.length}');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Manage Midwives', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
          // Search and Filters
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Midwives')),
                          DropdownMenuItem(value: 'active', child: Text('Approved')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v!),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        print('🔘 Add Midwife button clicked');
                        print('🔘 Barangays available: ${_barangays.length}');
                        _showAddMidwifeModal();
                      },
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Add Midwife'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatChip('Total', _midwives.length, Color(0xFF3B82F6)),
                SizedBox(width: 8),
                _buildStatChip('Approved', _midwives.where((m) => m['status'] == 'approved').length, Color(0xFF10B981)),
                SizedBox(width: 8),
                _buildStatChip('Pending', _midwives.where((m) => m['status'] == 'pending').length, Color(0xFFF59E0B)),
                SizedBox(width: 8),
                _buildStatChip('Inactive', _midwives.where((m) => m['status'] == 'inactive').length, Color(0xFFEF4444)),
              ],
            ),
          ),
          // Midwives List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _filteredMidwives.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 16),
                            Text('No midwives found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredMidwives.length,
                        itemBuilder: (context, index) => _buildMidwifeCard(_filteredMidwives[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMidwifeCard(dynamic midwife) {
    final status = midwife['status'] ?? 'pending';
    
    // Handle barangays - check both 'barangays' array and single 'barangay_name'
    String barangays = 'No assignment';
    if (midwife['barangays'] != null && midwife['barangays'] is List && (midwife['barangays'] as List).isNotEmpty) {
      barangays = (midwife['barangays'] as List).map((b) => b['name']).join(', ');
    } else if (midwife['barangay_name'] != null && midwife['barangay_name'] != 'N/A') {
      barangays = midwife['barangay_name'];
    }
    
    print('📋 Midwife: ${midwife['first_name']} - Status: $status - Barangays: $barangays');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMidwifeDetails(midwife),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                      child: Text(
                        '${midwife['first_name']?[0] ?? ''}${midwife['last_name']?[0] ?? ''}',
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${midwife['first_name']} ${midwife['last_name']}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            midwife['email'] ?? '',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Color(0xFF6B7280)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        barangays,
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (midwife['contact_number'] != null) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Color(0xFF6B7280)),
                      SizedBox(width: 4),
                      Text(
                        midwife['contact_number'],
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditModal(midwife),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF3B82F6),
                          side: BorderSide(color: Color(0xFF3B82F6)),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleStatus(midwife),
                        icon: Icon(Icons.toggle_on, size: 16),
                        label: Text(status == 'approved' ? 'Deactivate' : status == 'inactive' ? 'Activate' : 'Approve'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: status == 'approved' ? Color(0xFFEF4444) : Color(0xFF10B981),
                          side: BorderSide(color: status == 'approved' ? Color(0xFFEF4444) : Color(0xFF10B981)),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
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
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'approved':
        color = Color(0xFF10B981);
        label = 'Approved';
        break;
      case 'rejected':
        color = Color(0xFFEF4444);
        label = 'Rejected';
        break;
      case 'inactive':
        color = Color(0xFFEF4444);
        label = 'Inactive';
        break;
      case 'pending':
        color = Color(0xFFF59E0B);
        label = 'Pending';
        break;
      default:
        color = Color(0xFF6B7280);
        label = status;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showMidwifeDetails(dynamic midwife) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                    child: Text(
                      '${midwife['first_name']?[0] ?? ''}${midwife['last_name']?[0] ?? ''}',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${midwife['first_name']} ${midwife['last_name']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          midwife['email'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Status', _buildStatusBadge(midwife['status'] ?? 'pending')),
                    _buildDetailRow('Email', midwife['email'] ?? 'N/A'),
                    _buildDetailRow('Contact', midwife['contact_number'] ?? 'N/A'),
                    _buildDetailRow('Barangay ID', midwife['barangay_id']?.toString() ?? 'N/A'),
                    _buildDetailRow('Joined', _formatDate(midwife['created_at'])),
                    SizedBox(height: 16),
                    Text('Assigned Barangays', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    SizedBox(height: 8),
                    if (midwife['barangay_name'] != null && midwife['barangay_name'] != 'N/A')
                      Chip(
                        label: Text(midwife['barangay_name'], style: TextStyle(fontSize: 12)),
                        backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                        side: BorderSide(color: Color(0xFF10B981).withOpacity(0.3)),
                      )
                    else if ((midwife['barangays'] as List?)?.isEmpty ?? true)
                      Text('No barangays assigned', style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (midwife['barangays'] as List).map((b) => Chip(
                          label: Text(b['name'], style: TextStyle(fontSize: 12)),
                          backgroundColor: Color(0xFF10B981).withOpacity(0.1),
                          side: BorderSide(color: Color(0xFF10B981).withOpacity(0.3)),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: value is Widget ? value : Text(value.toString(), style: TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
          ),
        ],
      ),
    );
  }

  void _showEditModal(dynamic midwife) {
    final firstNameController = TextEditingController(text: midwife['first_name']);
    final lastNameController = TextEditingController(text: midwife['last_name']);
    final emailController = TextEditingController(text: midwife['email']);
    final contactController = TextEditingController(text: midwife['contact_number']);
    
    // Parse existing barangay assignments
    List<int> selectedBarangays = [];
    if (midwife['barangays'] != null && midwife['barangays'] is List) {
      selectedBarangays = (midwife['barangays'] as List).map((b) => b['id'] as int).toList();
    } else if (midwife['barangay_id'] != null) {
      selectedBarangays = [midwife['barangay_id'] as int];
    }
    
    print('🔧 Editing midwife: ${midwife['first_name']}');
    print('🔧 Current barangay assignments: $selectedBarangays');
    print('🔧 Midwife data: $midwife');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                    Icon(Icons.edit, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text('Edit Midwife', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: contactController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),
                      Text('Assign Barangays', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Select 1-3 barangays (Currently: ${selectedBarangays.length})', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: _barangays.map((barangay) => Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              title: Text(barangay['name'], style: TextStyle(fontSize: 14)),
                              value: selectedBarangays.contains(barangay['id']),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    if (selectedBarangays.length < 3) {
                                      selectedBarangays.add(barangay['id']);
                                    }
                                  } else {
                                    if (selectedBarangays.length > 1) {
                                      selectedBarangays.remove(barangay['id']);
                                    }
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )).toList(),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateMidwife(
                            midwife['id'],
                            firstNameController.text,
                            lastNameController.text,
                            emailController.text,
                            contactController.text,
                            selectedBarangays,
                          ),
                          icon: Icon(Icons.save),
                          label: Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

  Future<void> _updateMidwife(int id, String firstName, String lastName, String email, String contact, List<int> barangays) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final response = await ApiService.instance.put('/admin/midwives/$id', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'contact_number': contact,
        'barangay_ids': barangays,
      });

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Midwife updated successfully'), backgroundColor: Colors.green),
        );
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleStatus(dynamic midwife) async {
    final currentStatus = midwife['status'];
    String newStatus;
    String action;
    
    if (currentStatus == 'approved') {
      newStatus = 'inactive';
      action = 'deactivate';
    } else if (currentStatus == 'inactive') {
      newStatus = 'approved';
      action = 'activate';
    } else if (currentStatus == 'pending') {
      // For pending, show barangay selection dialog
      final selectedBarangays = await _showBarangaySelectionForApproval();
      if (selectedBarangays == null || selectedBarangays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one barangay'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      try {
        final response = await ApiService.instance.post('/users/${midwife['id']}/approve', data: {
          'barangays': selectedBarangays,
        });
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Midwife approved successfully'), backgroundColor: Colors.green),
          );
          _fetchData();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    } else {
      newStatus = 'approved';
      action = 'activate';
    }

    print('🔄 Toggling status from $currentStatus to $newStatus for midwife ID: ${midwife['id']}');

    try {
      final response = await ApiService.instance.post('/users/${midwife['id']}/toggle-status', data: {});

      print('✅ Status toggle response: ${response.statusCode}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Midwife ${action}d successfully'), backgroundColor: Colors.green),
        );
        _fetchData();
      }
    } catch (e) {
      print('❌ Status toggle error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<List<int>?> _showBarangaySelectionForApproval() async {
    List<int> selectedBarangays = [];
    
    if (_barangays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No barangays available'), backgroundColor: Colors.red),
      );
      return null;
    }
    
    return await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Barangays'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select 1-3 barangays to assign:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _barangays.map((barangay) => CheckboxListTile(
                      title: Text(barangay['name'], style: const TextStyle(fontSize: 14)),
                      value: selectedBarangays.contains(barangay['id']),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            if (selectedBarangays.length < 3) {
                              selectedBarangays.add(barangay['id']);
                            }
                          } else {
                            selectedBarangays.remove(barangay['id']);
                          }
                        });
                      },
                      dense: true,
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedBarangays.isEmpty ? null : () => Navigator.pop(context, selectedBarangays),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showAddMidwifeModal() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final contactController = TextEditingController();
    final passwordController = TextEditingController();
    List<int> selectedBarangays = [];

    print('🔍 Opening Add Midwife Modal - Barangays count: ${_barangays.length}');
    print('🔍 Barangays data: $_barangays');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                    Icon(Icons.person_add, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text('Add New Midwife', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: contactController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),
                      Text('Assign Barangays', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: _barangays.map((barangay) => Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              title: Text(barangay['name'], style: TextStyle(fontSize: 14)),
                              value: selectedBarangays.contains(barangay['id']),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    selectedBarangays.add(barangay['id']);
                                  } else {
                                    selectedBarangays.remove(barangay['id']);
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )).toList(),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _createMidwife(
                            firstNameController.text,
                            lastNameController.text,
                            emailController.text,
                            passwordController.text,
                            contactController.text,
                            selectedBarangays,
                          ),
                          icon: Icon(Icons.add),
                          label: Text('Add Midwife'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

  Future<void> _createMidwife(String firstName, String lastName, String email, String password, String contact, List<int> barangays) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final response = await ApiService.instance.post('/users', data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'username': email.split('@')[0], // Generate username from email
        'password': password,
        'contact_number': contact,
        'role': 'midwife',
        'status': 'approved',
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Now assign barangays if any selected
        if (barangays.isNotEmpty && response.data['id'] != null) {
          await ApiService.instance.post('/users/${response.data['id']}/approve', data: {
            'barangays': barangays,
          });
        }
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Midwife added successfully'), backgroundColor: Colors.green),
        );
        _fetchData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add midwife: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
