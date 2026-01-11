import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/county_settings_repository.dart';
import '../../models/models.dart';

/// Provider for county settings repository
final countySettingsRepositoryProvider = Provider<CountySettingsRepository>((ref) {
  return CountySettingsRepository();
});

/// Provider for county settings - uses Future for reliable initial load
final countySettingsProvider = FutureProvider<CountySettingsModel>((ref) async {
  final repository = ref.watch(countySettingsRepositoryProvider);
  try {
    return await repository.getSettings().timeout(
      const Duration(seconds: 10),
      onTimeout: () => CountySettingsModel.defaults(),
    );
  } catch (e) {
    // Return defaults on any error
    return CountySettingsModel.defaults();
  }
});

/// Provider for county settings stream (for real-time updates)
final countySettingsStreamProvider = StreamProvider<CountySettingsModel>((ref) {
  final repository = ref.watch(countySettingsRepositoryProvider);
  return repository.getSettingsStream();
});

/// Provider to get contact info for a specific county
final countyContactInfoProvider = Provider.family<CountyContactInfo, String>((ref, countyName) {
  final settings = ref.watch(countySettingsProvider).value;
  if (settings == null) {
    return CountyContactInfo.defaults();
  }
  return settings.getCountyInfo(countyName);
});
