class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, bool> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.members = const {},
  });

  int get memberCount => members.length;

  factory GroupModel.fromFirestore(String id, Map<String, dynamic> data) {
    final membersRaw = (data['members'] as Map?)?.cast<String, dynamic>() ?? {};
    final members = membersRaw.map((k, v) => MapEntry(k, v as bool));
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      members: members,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'createdAt': DateTime.now(),
      'members': members,
    };
  }
}
