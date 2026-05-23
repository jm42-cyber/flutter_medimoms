import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.userName);
    _emailController = TextEditingController(text: auth.userEmail);
    _phoneController = TextEditingController(text: auth.userPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF10B981)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit,
                color: const Color(0xFF10B981)),
            onPressed: () async {
              if (_editMode) {
                if (_formKey.currentState?.validate() ?? false) {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await authProvider.updateProfile(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                  );
                  if (success) {
                    setState(() => _editMode = false);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Profile updated')));
                  } else {
                    messenger.showSnackBar(SnackBar(
                        content: Text(
                            authProvider.errorMessage ?? 'Failed to update')));
                  }
                }
              } else {
                setState(() => _editMode = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Color(0xFF10B981)),
            onPressed: () => _showChangePasswordDialog(context, authProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.getUserInitials(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authProvider.getUserFirstName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email and phone under the name with cleaner formatting
                  Text(
                    authProvider.userEmail ?? '',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (authProvider.userPhone ?? '')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim(),
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(76),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      authProvider.userRole?.toUpperCase() ?? 'MIDWIFE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // add a little extra spacing between header and details card
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: _editMode,
                        decoration:
                            const InputDecoration(labelText: 'Full name'),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Enter a valid name'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        enabled: _editMode,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Email required';
                          final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                          return re.hasMatch(v.trim()) ? null : 'Invalid email';
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        enabled: _editMode,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          'Role', authProvider.userRole ?? 'N/A'),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          'User ID', authProvider.userId ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AuthProvider authProvider) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: currentController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password')),
            TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password')),
            TextField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(ctx);
              final ok = await authProvider.changePassword(
                currentPassword: currentController.text,
                newPassword: newController.text,
                confirmPassword: confirmController.text,
              );
              Navigator.pop(ctx);
              if (ok) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Password changed')));
              } else {
                messenger.showSnackBar(SnackBar(
                    content: Text(authProvider.errorMessage ??
                        'Failed to change password')));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
