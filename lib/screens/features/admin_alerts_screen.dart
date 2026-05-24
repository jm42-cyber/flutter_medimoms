import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/storage_service.dart';
import '../../config/app_config.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _alerts = [];
  bool _loading = true;
  bool _sending = false;
  
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'info';
  String _selectedPriority = 'medium';
  String _selectedRecipientType = 'all';
  List<int> _selectedRecipientIds = [];
  List<dynamic> _barangays = [];
  List<dynamic> _midwives = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _loading = true);
    try {
      final token = await StorageService.instance.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/alerts'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => _alerts = json.decode(response.body));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load alerts')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchBarangays() async {
    try {
      final token = await StorageService.instance.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/barangays'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both direct array and {data: []} response
        final barangaysList = data is List ? data : (data['data'] ?? []);
        setState(() => _barangays = barangaysList);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _fetchMidwives() async {
    try {
      final token = await StorageService.instance.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/users?role=midwife'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both direct array and {data: []} response
        final midwifesList = data is List ? data : (data['data'] ?? []);
        setState(() => _midwives = midwifesList);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Map<String, int> get _stats {
    final fromMidwives = _alerts.where((a) => a['sender_role'] == 'midwife').toList();
    final sentByAdmin = _alerts.where((a) => a['sender_role'] == 'admin').toList();
    final needsReply = fromMidwives.where((a) => a['reply'] == null).length;
    return {'fromMidwives': fromMidwives.length, 'needsReply': needsReply, 'sent': sentByAdmin.length};
  }

  List<dynamic> get _filteredAlerts {
    final isInbox = _tabController.index == 0;
    return _alerts.where((a) => isInbox ? a['sender_role'] == 'midwife' : a['sender_role'] == 'admin').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Admin Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
            onPressed: () => _showSendAnnouncementModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('From Midwives', _stats['fromMidwives']!, Icons.inbox, Color(0xFF3B82F6)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Needs Reply', _stats['needsReply']!, Icons.reply, Color(0xFFF59E0B)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Sent', _stats['sent']!, Icons.send, Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Color(0xFF6B7280),
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('From Midwives'),
                  if (_stats['needsReply']! > 0) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_stats['needsReply']}', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Sent'),
                ])),
              ],
              onTap: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading 
                ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _filteredAlerts.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text('No messages found', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                      ]))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredAlerts.length,
                        itemBuilder: (context, index) => _buildAlertCard(_filteredAlerts[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
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
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final isInbox = _tabController.index == 0;
    final hasReply = alert['reply'] != null && alert['reply_at'] != null;
    final needsReply = isInbox && !hasReply;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: needsReply ? Color(0xFFFEF3C7) : Colors.white,
        border: Border.all(color: needsReply ? Color(0xFFF59E0B).withOpacity(0.3) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(alert['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getTypeIcon(alert['type']), color: _getTypeColor(alert['type']), size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isInbox && alert['sender_name'] != null)
                      Text('From: ${alert['sender_name']}', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              _buildBadge(alert['type'], _getTypeColor(alert['type'])),
              SizedBox(width: 8),
              _buildBadge(alert['priority'], _getPriorityColor(alert['priority'])),
            ],
          ),
          SizedBox(height: 12),
          Text(alert['message'], style: TextStyle(color: Colors.grey.shade700)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(_formatDate(alert['created_at']), style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (needsReply) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReplyModal(alert),
                icon: Icon(Icons.reply, size: 18),
                label: Text('Reply to Midwife'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          if (hasReply) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.05),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('You replied ${_formatDate(alert['reply_at'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(alert['reply'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'error': return Icons.error;
      default: return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error': return Colors.red;
      default: return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showReplyModal(dynamic alert) {
    final replyController = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
                    Icon(Icons.reply, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reply to Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('From: ${alert['sender_name'] ?? 'Midwife'}', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Original Message:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text(alert['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(alert['message'], style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: replyController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Your Reply *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: sending ? null : () async {
                            if (replyController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a reply')));
                              return;
                            }
                            setModalState(() => sending = true);
                            await _sendReply(alert['id'], replyController.text);
                            setModalState(() => sending = false);
                            Navigator.pop(context);
                          },
                          icon: sending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.send),
                          label: Text(sending ? 'Sending...' : 'Send Reply'),
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

  Future<void> _sendReply(int alertId, String reply) async {
    try {
      final token = await StorageService.instance.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/alerts/$alertId/reply'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({'reply': reply}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reply sent successfully'), backgroundColor: Colors.green));
        _fetchAlerts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reply')));
    }
  }

  void _showSendAnnouncementModal() {
    // Fetch barangays and midwives when modal opens
    _fetchBarangays();
    _fetchMidwives();
    
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
                    Icon(Icons.campaign, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text('Send Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Subject *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Message *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: [
                          DropdownMenuItem(value: 'info', child: Text('Info')),
                          DropdownMenuItem(value: 'warning', child: Text('Warning')),
                          DropdownMenuItem(value: 'success', child: Text('Success')),
                          DropdownMenuItem(value: 'error', child: Text('Error')),
                        ],
                        onChanged: (v) => setModalState(() => _selectedType = v!),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (v) => setModalState(() => _selectedPriority = v!),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRecipientType,
                        decoration: InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Midwives')),
                          DropdownMenuItem(value: 'barangay', child: Text('Specific Barangay')),
                          DropdownMenuItem(value: 'specific', child: Text('Specific Midwife')),
                        ],
                        onChanged: (v) => setModalState(() {
                          _selectedRecipientType = v!;
                          _selectedRecipientIds = [];
                        }),
                      ),
                      SizedBox(height: 16),
                      // Show barangay selector if barangay is selected
                      if (_selectedRecipientType == 'barangay') ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Barangays:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 8),
                              ..._barangays.map((barangay) => CheckboxListTile(
                                title: Text(barangay['name'], style: TextStyle(fontSize: 14)),
                                value: _selectedRecipientIds.contains(barangay['id']),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      _selectedRecipientIds.add(barangay['id']);
                                    } else {
                                      _selectedRecipientIds.remove(barangay['id']);
                                    }
                                  });
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                      // Show midwife selector if specific is selected
                      if (_selectedRecipientType == 'specific') ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Midwives:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 8),
                              ..._midwives.map((midwife) => CheckboxListTile(
                                title: Text(midwife['full_name'], style: TextStyle(fontSize: 14)),
                                subtitle: Text(midwife['barangay_name'] ?? '', style: TextStyle(fontSize: 11)),
                                value: _selectedRecipientIds.contains(midwife['id']),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      _selectedRecipientIds.add(midwife['id']);
                                    } else {
                                      _selectedRecipientIds.remove(midwife['id']);
                                    }
                                  });
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : () {
                            _sendAnnouncement();
                            Navigator.pop(context);
                          },
                          icon: _sending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.send),
                          label: Text(_sending ? 'Sending...' : 'Send Announcement'),
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

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    // Validate recipient selection
    if ((_selectedRecipientType == 'barangay' || _selectedRecipientType == 'specific') && _selectedRecipientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select at least one recipient')));
      return;
    }

    setState(() => _sending = true);
    try {
      final token = await StorageService.instance.getToken();
      final Map<String, dynamic> body = {
        'title': _titleController.text,
        'message': _messageController.text,
        'type': _selectedType,
        'priority': _selectedPriority,
        'recipient_type': _selectedRecipientType,
      };
      
      // Add recipient_ids only if not 'all'
      if (_selectedRecipientType != 'all') {
        body['recipient_ids'] = _selectedRecipientIds;
      }
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/alerts'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedType = 'info';
          _selectedPriority = 'medium';
          _selectedRecipientType = 'all';
          _selectedRecipientIds = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement sent successfully'), backgroundColor: Colors.green));
        _fetchAlerts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send announcement')));
    } finally {
      setState(() => _sending = false);
    }
  }
}
