import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// School model representing a high school in the county
class SchoolModel extends Equatable {
  final String id;
  final String name;
  final String shortName; // e.g., "CNMB" for "Colegiul National Mircea cel Batran"
  final String? address;
  final String? city;
  final String? logoUrl;
  final String? schoolRepId; // Current school representative user ID
  final String? schoolRepName;
  final int studentCount; // Number of registered students
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.shortName,
    this.address,
    this.city,
    this.logoUrl,
    this.schoolRepId,
    this.schoolRepName,
    this.studentCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty school
  factory SchoolModel.empty() {
    return SchoolModel(
      id: '',
      name: '',
      shortName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Create from Firestore document
  factory SchoolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      shortName: data['shortName'] as String? ?? '',
      address: data['address'] as String?,
      city: data['city'] as String?,
      logoUrl: data['logoUrl'] as String?,
      schoolRepId: data['schoolRepId'] as String?,
      schoolRepName: data['schoolRepName'] as String?,
      studentCount: data['studentCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shortName': shortName,
      'address': address,
      'city': city,
      'logoUrl': logoUrl,
      'schoolRepId': schoolRepId,
      'schoolRepName': schoolRepName,
      'studentCount': studentCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  SchoolModel copyWith({
    String? id,
    String? name,
    String? shortName,
    String? address,
    String? city,
    String? logoUrl,
    String? schoolRepId,
    String? schoolRepName,
    int? studentCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      address: address ?? this.address,
      city: city ?? this.city,
      logoUrl: logoUrl ?? this.logoUrl,
      schoolRepId: schoolRepId ?? this.schoolRepId,
      schoolRepName: schoolRepName ?? this.schoolRepName,
      studentCount: studentCount ?? this.studentCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        shortName,
        address,
        city,
        logoUrl,
        schoolRepId,
        schoolRepName,
        studentCount,
        isActive,
        createdAt,
        updatedAt,
      ];
}
