import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// GDS (Grupuri de Suport / Support Groups) model
/// These are support groups managed by BEX for organizing student activities
class GDSModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? focus; // Area of focus (e.g., "Environment", "Education", "Culture")
  final String leaderId; // User ID of the group leader
  final String leaderName;
  final List<String> memberIds;
  final List<GDSMember> members;
  final bool isActive;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GDSModel({
    required this.id,
    required this.name,
    this.description,
    this.focus,
    required this.leaderId,
    required this.leaderName,
    this.memberIds = const [],
    this.members = const [],
    this.isActive = true,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get member count
  int get memberCount => memberIds.length;

  /// Check if a user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if a user is the leader
  bool isLeader(String userId) => leaderId == userId;

  factory GDSModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GDSModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      focus: data['focus'] as String?,
      leaderId: data['leaderId'] as String? ?? '',
      leaderName: data['leaderName'] as String? ?? '',
      memberIds: (data['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      members: (data['members'] as List<dynamic>?)
              ?.map((m) => GDSMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] as bool? ?? true,
      createdById: data['createdById'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'focus': focus,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'memberIds': memberIds,
      'members': members.map((m) => m.toMap()).toList(),
      'isActive': isActive,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GDSModel copyWith({
    String? id,
    String? name,
    String? description,
    String? focus,
    String? leaderId,
    String? leaderName,
    List<String>? memberIds,
    List<GDSMember>? members,
    bool? isActive,
    String? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GDSModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      focus: focus ?? this.focus,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      memberIds: memberIds ?? this.memberIds,
      members: members ?? this.members,
      isActive: isActive ?? this.isActive,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        focus,
        leaderId,
        leaderName,
        memberIds,
        members,
        isActive,
        createdById,
        createdByName,
        createdAt,
        updatedAt,
      ];
}

/// Member information stored within GDS
class GDSMember extends Equatable {
  final String id;
  final String name;
  final String? role; // Optional role within the group
  final DateTime joinedAt;

  const GDSMember({
    required this.id,
    required this.name,
    this.role,
    required this.joinedAt,
  });

  factory GDSMember.fromMap(Map<String, dynamic> map) {
    return GDSMember(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String?,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  GDSMember copyWith({
    String? id,
    String? name,
    String? role,
    DateTime? joinedAt,
  }) {
    return GDSMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, role, joinedAt];
}
