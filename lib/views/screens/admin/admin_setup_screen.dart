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

extension _AdminSetupL10n on AppLocalizations {
  String get adminSetup => translate('admin_setup');
  String get adminSetupWarning => translate('admin_setup_warning');
  String get currentSuperAdmins => translate('current_super_admins');
  String get addSuperAdmin => translate('add_super_admin');
  String get addSuperAdminDesc => translate('add_super_admin_desc');
  String get userEmail => translate('user_email');
  String get emailHint => translate('admin_email_hint');
  String get pleaseEnterEmail => translate('please_enter_email');
  String get pleaseEnterValidEmail => translate('please_enter_valid_email');
  String get setAsSuperAdmin => translate('set_as_super_admin');
  String get superAdminSetSuccess => translate('super_admin_set_success');
  String get superAdminSetFailed => translate('super_admin_set_failed');
  String get superAdminCapabilities => translate('super_admin_capabilities');
  String get capViewManageUsers => translate('cap_view_manage_users');
  String get capApproveUsers => translate('cap_approve_users');
  String get capChangeRoles => translate('cap_change_roles');
  String get capCreateContent => translate('cap_create_content');
  String get capUploadDocs => translate('cap_upload_docs');
  String get capFullAccess => translate('cap_full_access');
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

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = false;
      _isSuccess = success;
      _message = success
          ? l10n.superAdminSetSuccess
          : l10n.superAdminSetFailed;
    });

    if (success) {
      _emailController.clear();
      _checkExistingAdmins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.adminSetup),
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
                      l10n.adminSetupWarning,
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
              Text(
                l10n.currentSuperAdmins,
                style: const TextStyle(
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
                        child: Text(
                          l10n.translate('super_admin'),
                          style: const TextStyle(
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
            Text(
              l10n.addSuperAdmin,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addSuperAdminDesc,
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
                        labelText: l10n.userEmail,
                        hintText: l10n.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterEmail;
                        }
                        if (!value.contains('@')) {
                          return l10n.pleaseEnterValidEmail;
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
                            : Text(
                                l10n.setAsSuperAdmin,
                                style: const TextStyle(
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
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: context.textPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.superAdminCapabilities,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCapability(l10n.capViewManageUsers),
                  _buildCapability(l10n.capApproveUsers),
                  _buildCapability(l10n.capChangeRoles),
                  _buildCapability(l10n.capCreateContent),
                  _buildCapability(l10n.capUploadDocs),
                  _buildCapability(l10n.capFullAccess),
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
