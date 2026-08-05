import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String password;
  final String createdBy;
  final String creatorName;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final int memberCount;
  final int taadiaCount;

  Organization({
    required this.id,
    required this.name,
    this.password = '',
    required this.createdBy,
    required this.creatorName,
    this.status = 'pending',
    required this.createdAt,
    this.approvedAt,
    this.memberCount = 0,
    this.taadiaCount = 0,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      password: data['password'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as dynamic)?.toDate(),
      memberCount: data['memberCount'] ?? 0,
      taadiaCount: data['taadiaCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedAt': approvedAt != null ? FieldValue.serverTimestamp() : null,
      'memberCount': memberCount,
      'taadiaCount': taadiaCount,
    };
  }

  Organization copyWith({
    String? name,
    String? password,
    String? status,
    DateTime? approvedAt,
    int? memberCount,
    int? taadiaCount,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      password: password ?? this.password,
      createdBy: createdBy,
      creatorName: creatorName,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      memberCount: memberCount ?? this.memberCount,
      taadiaCount: taadiaCount ?? this.taadiaCount,
    );
  }
}
