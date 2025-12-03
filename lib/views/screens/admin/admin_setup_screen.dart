import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../core/services/admin_setup_service.dart';

/// One-time setup screen to create the first super admin
/// Access this by navigating to /admin-setup route (only in debug mode)
class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminSetupService();

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  List<Map<String, dynamic>> _existingAdmins = [];

  @override
  void initState() {
    super.initState();
    _checkExistingAdmins();
  }

  Future<void> _checkExistingAdmins() async {
    setState(() => _isLoading = true);

    final admins = await _adminService.getSuperAdmins();

    setState(() {
      _existingAdmins = admins;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _setupAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final success = await _adminService.setUserAsSuperAdmin(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _isSuccess = success;
      _message = success
          ? 'Super Admin set successfully! The user can now manage the entire app.'
          : 'Failed to set Super Admin. Make sure the email is registered in the app.';
    });

    if (success) {
      _emailController.clear();
      _checkExistingAdmins();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Admin Setup'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This screen is for initial setup only. Super Admins have full control over the app.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Existing admins
            if (_existingAdmins.isNotEmpty) ...[
              const Text(
                'Current Super Admins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _existingAdmins.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final admin = _existingAdmins[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.gold,
                        child: Text(
                          (admin['fullName'] as String?)?.isNotEmpty == true
                              ? admin['fullName'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(admin['fullName'] ?? 'Unknown'),
                      subtitle: Text(admin['email'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Super Admin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Add new admin form
            const Text(
              'Add Super Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the email of a registered user to make them a Super Admin.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'User Email',
                        hintText: 'admin@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setupAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Set as Super Admin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Result message
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.navy, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Super Admin Capabilities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCapability('View and manage all users'),
                  _buildCapability('Approve or suspend any user'),
                  _buildCapability('Change user roles'),
                  _buildCapability('Create announcements, meetings, polls'),
                  _buildCapability('Upload documents'),
                  _buildCapability('Full access to all app features'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapability(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
