import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for county-specific settings like social media links and contact info
/// Each county can have its own Facebook, Instagram, website, email, and phone
class CountySettingsModel {
  // Map of county name to its settings
  final Map<String, CountyContactInfo> counties;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CountySettingsModel({
    required this.counties,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get contact info for a specific county
  CountyContactInfo getCountyInfo(String countyName) {
    return counties[countyName] ?? CountyContactInfo.defaults();
  }

  /// Factory constructor with default values for all Romanian counties
  factory CountySettingsModel.defaults() {
    final now = DateTime.now();
    return CountySettingsModel(
      createdAt: now,
      updatedAt: now,
      counties: {
        'Alba': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJEAlba',
          instagram: 'https://www.instagram.com/cje.alba',
          website: 'https://www.cje-alba.ro',
          email: 'contact@cje-alba.ro',
          phone: '+40 258 811 000',
        ),
        'Arad': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJEArad',
          instagram: 'https://www.instagram.com/cje.arad',
          website: 'https://www.cje-arad.ro',
          email: 'contact@cje-arad.ro',
          phone: '+40 257 280 000',
        ),
        'Arges': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJEArges',
          instagram: 'https://www.instagram.com/cje.arges',
          website: 'https://www.cje-arges.ro',
          email: 'contact@cje-arges.ro',
          phone: '+40 248 211 000',
        ),
        'Bacau': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJEBacau',
          instagram: 'https://www.instagram.com/cje.bacau',
          website: 'https://www.cje-bacau.ro',
          email: 'contact@cje-bacau.ro',
          phone: '+40 234 511 000',
        ),
        // Add more counties as needed - placeholder for now
        'Bucuresti': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJEBucuresti',
          instagram: 'https://www.instagram.com/cje.bucuresti',
          website: 'https://www.cje-bucuresti.ro',
          email: 'contact@cje-bucuresti.ro',
          phone: '+40 21 311 0000',
        ),
        'Cluj': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJECluj',
          instagram: 'https://www.instagram.com/cje.cluj',
          website: 'https://www.cje-cluj.ro',
          email: 'contact@cje-cluj.ro',
          phone: '+40 264 591 000',
        ),
        'Sibiu': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJESibiu',
          instagram: 'https://www.instagram.com/cje.sibiu',
          website: 'https://www.cje-sibiu.ro',
          email: 'contact@cje-sibiu.ro',
          phone: '+40 269 211 000',
        ),
        // Default fallback for any other county
        'Default': CountyContactInfo(
          facebook: 'https://www.facebook.com/CJERomania',
          instagram: 'https://www.instagram.com/cje.romania',
          website: 'https://www.cje.ro',
          email: 'contact@cje.ro',
          phone: '+40 21 311 0000',
        ),
      },
    );
  }

  /// From Firestore
  factory CountySettingsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final countiesData = data['counties'] as Map<String, dynamic>? ?? {};

    final counties = <String, CountyContactInfo>{};
    countiesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        counties[key] = CountyContactInfo.fromMap(value);
      }
    });

    return CountySettingsModel(
      counties: counties.isNotEmpty ? counties : CountySettingsModel.defaults().counties,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// To Firestore
  Map<String, dynamic> toFirestore() {
    final countiesMap = <String, dynamic>{};
    counties.forEach((key, value) {
      countiesMap[key] = value.toMap();
    });

    return {
      'counties': countiesMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with
  CountySettingsModel copyWith({
    Map<String, CountyContactInfo>? counties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CountySettingsModel(
      counties: counties ?? this.counties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Contact information for a specific county
class CountyContactInfo {
  final String facebook;
  final String instagram;
  final String website;
  final String email;
  final String phone;

  const CountyContactInfo({
    required this.facebook,
    required this.instagram,
    required this.website,
    required this.email,
    required this.phone,
  });

  /// Default values
  factory CountyContactInfo.defaults() {
    return const CountyContactInfo(
      facebook: 'https://www.facebook.com/CJERomania',
      instagram: 'https://www.instagram.com/cje.romania',
      website: 'https://www.cje.ro',
      email: 'contact@cje.ro',
      phone: '+40 21 311 0000',
    );
  }

  /// From map
  factory CountyContactInfo.fromMap(Map<String, dynamic> map) {
    return CountyContactInfo(
      facebook: map['facebook'] as String? ?? '',
      instagram: map['instagram'] as String? ?? '',
      website: map['website'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  /// To map
  Map<String, dynamic> toMap() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'website': website,
      'email': email,
      'phone': phone,
    };
  }
}
