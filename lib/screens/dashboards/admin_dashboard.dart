import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_drawer.dart';
import '../../routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final responses = await Future.wait([
        ApiService.instance.get('/admin/dashboard/stats'),
        ApiService.instance.get('/admin/dashboard/pending-approvals'),
        ApiService.instance.get('/admin/dashboard/activities'),
      ]);

      setState(() {
        if (responses[0].statusCode == 200) {
          _stats = responses[0].data;
        }
        if (responses[1].statusCode == 200) {
          _pendingApprovals = List<Map<String, dynamic>>.from(responses[1].data);
        }
        if (responses[2].statusCode == 200) {
          _recentActivities = List<Map<String, dynamic>>.from(responses[2].data);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleApprove(int userId) async {
    try {
      await ApiService.instance.post('/users/$userId/approve');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Midwife approved successfully!'), backgroundColor: Colors.green),
        );
      }
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(int userId) async {
    try {
      await ApiService.instance.post('/users/$userId/reject');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Midwife rejected'), backgroundColor: Colors.orange),
        );
      }
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'System Overview',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _buildStatCard(
                          'Active Midwives',
                          _stats['total_midwives']?.toString() ?? '0',
                          Icons.people_rounded,
                          const Color(0xFF10B981),
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          _stats['pending_midwives']?.toString() ?? '0',
                          Icons.pending_actions_rounded,
                          const Color(0xFFF59E0B),
                        ),
                        _buildStatCard(
                          'Total Barangays',
                          _stats['total_barangays']?.toString() ?? '0',
                          Icons.location_on_rounded,
                          const Color(0xFF3B82F6),
                        ),
                        _buildStatCard(
                          'Total Records',
                          _stats['total_records']?.toString() ?? '0',
                          Icons.description_rounded,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pending Approvals Section
                    if (_pendingApprovals.isNotEmpty) ...[
                      _buildSectionHeader('Pending Approvals', Icons.pending_actions_rounded),
                      const SizedBox(height: 12),
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
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pendingApprovals.length > 5 ? 5 : _pendingApprovals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final approval = _pendingApprovals[index];
                            return _buildPendingApprovalTile(approval);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Recent Activity Section
                    _buildSectionHeader('Recent Activity', Icons.history_rounded),
                    const SizedBox(height: 12),
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
                      child: _recentActivities.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.history_rounded, size: 48, color: Color(0xFF9CA3AF)),
                                    SizedBox(height: 8),
                                    Text('No recent activity', style: TextStyle(color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentActivities.length > 8 ? 8 : _recentActivities.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                              itemBuilder: (context, index) {
                                final activity = _recentActivities[index];
                                return _buildActivityTile(activity);
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildQuickAction('Midwives', Icons.medical_services_rounded, const Color(0xFF14B8A6), Routes.manageMidwives),
                        _buildQuickAction('Pending', Icons.pending_actions_rounded, const Color(0xFFF59E0B), Routes.pendingAccounts),
                        _buildQuickAction('Barangays', Icons.location_on_rounded, const Color(0xFF3B82F6), Routes.manageBarangays),
                        _buildQuickAction('Reports', Icons.assessment_rounded, const Color(0xFF8B5CF6), Routes.reportsPage),
                        _buildQuickAction('Alerts', Icons.notifications_active_rounded, const Color(0xFF10B981), Routes.adminAlerts),
                        _buildQuickAction('Audit Logs', Icons.history_rounded, const Color(0xFFF97316), Routes.auditLogs),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalTile(Map<String, dynamic> approval) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.person_add_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approval['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      approval['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(approval['id']),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReject(approval['id']),
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.history_rounded, color: Color(0xFF10B981), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['action'] ?? 'Unknown action',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity['user_name'] ?? 'Unknown user',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['timestamp'] ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
