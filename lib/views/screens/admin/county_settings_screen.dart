import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// County Settings Screen - Visible to superadmin and BEX
/// Allows editing contact information displayed in Help & Support
/// - Superadmin can edit any county
/// - BEX can only edit their own county
class CountySettingsScreen extends ConsumerStatefulWidget {
  const CountySettingsScreen({super.key});

  @override
  ConsumerState<CountySettingsScreen> createState() => _CountySettingsScreenState();
}

class _CountySettingsScreenState extends ConsumerState<CountySettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

  String _selectedCounty = 'Alba';
  bool _isLoading = false;
  bool _isBexUser = false;
  String? _bexUserCounty;
  bool _fieldsPopulated = false;
  String? _lastPopulatedCounty;

  final List<String> _counties = [
    'Alba',
    'Arad',
    'Argeș',
    'Bacău',
    'Bihor',
    'Bistrița-Năsăud',
    'Botoșani',
    'Brașov',
    'Brăila',
    'București',
    'Buzău',
    'Caraș-Severin',
    'Călărași',
    'Cluj',
    'Constanța',
    'Covasna',
    'Dâmbovița',
    'Dolj',
    'Galați',
    'Giurgiu',
    'Gorj',
    'Harghita',
    'Hunedoara',
    'Ialomița',
    'Iași',
    'Ilfov',
    'Maramureș',
    'Mehedinți',
    'Mureș',
    'Neamț',
    'Olt',
    'Prahova',
    'Satu Mare',
    'Sălaj',
    'Sibiu',
    'Suceava',
    'Teleorman',
    'Timiș',
    'Tulcea',
    'Vaslui',
    'Vâlcea',
    'Vrancea',
    'Default',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();

    // Check if current user is BEX (not superadmin)
    // BEX users can only edit their own county
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && currentUser.role == UserRole.bex) {
        setState(() {
          _isBexUser = true;
          _bexUserCounty = currentUser.city;
          _selectedCounty = currentUser.city ?? 'Default';
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _populateFields(CountyContactInfo info) {
    // Only populate if not already done for this county
    if (_fieldsPopulated && _lastPopulatedCounty == _selectedCounty) {
      return;
    }
    _phoneController.text = info.phone;
    _emailController.text = info.email;
    _websiteController.text = info.website;
    _instagramController.text = info.instagram;
    _facebookController.text = info.facebook;
    _fieldsPopulated = true;
    _lastPopulatedCounty = _selectedCounty;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final settingsAsync = ref.read(countySettingsProvider);
    if (!settingsAsync.hasValue) {
      setState(() => _isLoading = false);
      return;
    }

    final currentSettings = settingsAsync.value!;
    final updatedCounties = Map<String, CountyContactInfo>.from(currentSettings.counties);

    updatedCounties[_selectedCounty] = CountyContactInfo(
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      instagram: _instagramController.text.trim(),
      facebook: _facebookController.text.trim(),
    );

    final updatedSettings = currentSettings.copyWith(
      counties: updatedCounties,
      updatedAt: DateTime.now(),
    );

    final repository = ref.read(countySettingsRepositoryProvider);
    final success = await repository.updateSettings(updatedSettings);

    setState(() => _isLoading = false);

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('settings_saved')
              : l10n.translate('error_saving_settings')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(countySettingsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: TextStyle(color: context.textPrimary),
            ),
          ),
          data: (settings) {
            final countyInfo = settings.getCountyInfo(_selectedCounty);
            _populateFields(countyInfo);
            return _buildContent(context, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('county_settings'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.translate('county_settings_description'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Form
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // County Selector
                  _buildSectionHeader(
                    context,
                    icon: Icons.location_city_rounded,
                    title: l10n.translate('select_county'),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(context, [
                    if (_isBexUser && _bexUserCounty != null)
                      // BEX users can only edit their own county - show read-only field
                      Builder(builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue: _bexUserCounty,
                              enabled: false,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.translate('bex_county_restriction'),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        );
                      })
                    else
                      // Superadmin can select any county
                      Builder(builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return DropdownButtonFormField<String>(
                          value: _selectedCounty,
                          dropdownColor: context.cardColor,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.location_on, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.gold, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: _counties.map((county) {
                            return DropdownMenuItem(
                              value: county,
                              child: Text(county),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _selectedCounty) {
                              setState(() {
                                _selectedCounty = value;
                                _fieldsPopulated = false; // Reset to repopulate fields
                              });
                            }
                          },
                        );
                      }),
                  ]),

                  const SizedBox(height: 24),

                  // Contact Info Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.contact_phone_rounded,
                    title: l10n.translate('contact_info'),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(context, [
                    _buildTextField(
                      context,
                      controller: _phoneController,
                      label: l10n.translate('phone_number'),
                      hint: '+40 123 456 789',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 24),
                    _buildTextField(
                      context,
                      controller: _emailController,
                      label: l10n.translate('email'),
                      hint: 'contact@cje-county.ro',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 24),
                    _buildTextField(
                      context,
                      controller: _websiteController,
                      label: l10n.translate('website'),
                      hint: 'https://www.cje-county.ro',
                      icon: Icons.language_rounded,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Social Media Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.share_rounded,
                    title: l10n.translate('social_media'),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(context, [
                    _buildTextField(
                      context,
                      controller: _facebookController,
                      label: l10n.translate('facebook_url'),
                      hint: 'https://www.facebook.com/CJECounty',
                      icon: Icons.facebook_rounded,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 24),
                    _buildTextField(
                      context,
                      controller: _instagramController,
                      label: l10n.translate('instagram_url'),
                      hint: 'https://www.instagram.com/cje.county',
                      icon: Icons.camera_alt_rounded,
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.translate('save_changes'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info text
                  Center(
                    child: Text(
                      l10n.translate('settings_info'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required IconData icon, required String title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.gold : AppColors.navy),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textSecondary.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
