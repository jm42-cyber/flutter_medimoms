import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/storage_service.dart';
import '../../config/app_config.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _alerts = [];
  bool _loading = true;
  bool _sending = false;
  
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'info';
  String _selectedPriority = 'medium';
  
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _priorityFilter = 'all';
  bool _showUnreadOnly = false;

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

  Future<void> _sendMessage() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    setState(() => _sending = true);
    try {
      final token = await StorageService.instance.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/alerts'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'message': _messageController.text,
          'type': _selectedType,
          'priority': _selectedPriority,
        }),
      );
      if (response.statusCode == 201) {
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedType = 'info';
          _selectedPriority = 'medium';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message sent successfully'), backgroundColor: Colors.green));
        _fetchAlerts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message')));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final token = await StorageService.instance.getToken();
      await http.post(
        Uri.parse('${AppConfig.apiUrl}/alerts/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() {
        final index = _alerts.indexWhere((a) => a['id'] == id);
        if (index != -1) _alerts[index]['read_at'] = DateTime.now().toIso8601String();
      });
    } catch (e) {}
  }

  Future<void> _deleteAlert(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await StorageService.instance.getToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUrl}/alerts/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message deleted'), backgroundColor: Colors.green));
        _fetchAlerts();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete message')));
    }
  }

  void _showSendMessageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  Icon(Icons.send, color: Color(0xFF10B981)),
                  SizedBox(width: 12),
                  Text('Send Message to Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      onChanged: (v) => setState(() => _selectedType = v!),
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
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : () {
                          _sendMessage();
                          Navigator.pop(context);
                        },
                        icon: _sending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.send),
                        label: Text(_sending ? 'Sending...' : 'Send Message'),
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
    );
  }

  List<dynamic> get _filteredAlerts {
    final isInbox = _tabController.index == 0;
    final source = _alerts.where((a) => isInbox ? a['sender_role'] == 'admin' : a['sender_role'] == 'midwife').toList();
    
    return source.where((alert) {
      final matchesSearch = alert['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           alert['message'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _typeFilter == 'all' || alert['type'] == _typeFilter;
      final matchesPriority = _priorityFilter == 'all' || alert['priority'] == _priorityFilter;
      final matchesUnread = !_showUnreadOnly || alert['read_at'] == null;
      final isExpired = alert['expires_at'] != null && DateTime.parse(alert['expires_at']).isBefore(DateTime.now());
      
      return matchesSearch && matchesType && matchesPriority && matchesUnread && !isExpired;
    }).toList();
  }

  Map<String, int> get _stats {
    final inbox = _alerts.where((a) => a['sender_role'] == 'admin').toList();
    final sent = _alerts.where((a) => a['sender_role'] == 'midwife').toList();
    final unread = inbox.where((a) => a['read_at'] == null).length;
    return {'totalReceived': inbox.length, 'unread': unread, 'sent': sent.length};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Alerts & Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
            onPressed: () => _showSendMessageModal(),
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
                  child: _buildStatCard('Received', _stats['totalReceived']!, Icons.inbox, Color(0xFF3B82F6)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Unread', _stats['unread']!, Icons.mark_email_unread, Color(0xFF10B981)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Sent', _stats['sent']!, Icons.send, Color(0xFF8B5CF6)),
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
                  Text('Inbox'),
                  if (_stats['unread']! > 0) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_stats['unread']}', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
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
          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          // Messages List
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

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
    final isUnread = alert['read_at'] == null && isInbox;
    final hasReply = alert['reply'] != null && alert['reply_at'] != null;
    final canDelete = !isInbox && !hasReply;

    return GestureDetector(
      onTap: () {
        if (isUnread) _markAsRead(alert['id']);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Color(0xFF7CB342).withOpacity(0.05) : Colors.white,
          border: Border.all(color: isUnread ? Color(0xFF7CB342).withOpacity(0.3) : Colors.grey.shade200),
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
                      if (!isInbox && alert['sender_barangay'] != null)
                        Text('From: ${alert['sender_barangay']}', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                _buildBadge(alert['type'], _getTypeColor(alert['type'])),
                SizedBox(width: 8),
                _buildBadge(alert['priority'], _getPriorityColor(alert['priority'])),
                if (canDelete) ...[
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteAlert(alert['id']),
                  ),
                ],
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
            if (hasReply) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF7CB342).withOpacity(0.05),
                  border: Border.all(color: Color(0xFF7CB342).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Color(0xFF7CB342)),
                        SizedBox(width: 8),
                        Text('Admin replied ${_formatDate(alert['reply_at'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D5F3F))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(alert['reply'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
            if (!isInbox && !hasReply) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Awaiting reply...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ],
        ),
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
}
