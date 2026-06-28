import 'formula_config.dart';

class ClassificationConfig {
  final String name;
  final List<String> options;

  ClassificationConfig({
    required this.name,
    this.options = const [],
  });

  factory ClassificationConfig.fromMap(Map<String, dynamic> data) {
    return ClassificationConfig(
      name: data['name'] ?? '',
      options: (data['options'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() => name;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'options': options,
    };
  }
}

class Taadia {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String status;
  final String formula;
  final String visibility;
  final Map<String, bool> accessGroups;
  final Map<String, bool> accessUsers;
  final String accessCode;
  final List<String> categories;
  final List<ClassificationConfig> classifications;

  Taadia({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdBy,
    required this.createdAt,
    this.status = 'active',
    this.formula = 'mahalia',
    this.visibility = 'public',
    this.accessGroups = const {},
    this.accessUsers = const {},
    this.accessCode = '',
    this.categories = const [],
    this.classifications = const [],
  });

  FormulaConfig get formulaConfig => FormulaConfig.fromJson(formula);

  bool get isPrivate => visibility == 'private';

  bool get hasRestrictedAccess =>
      accessGroups.isNotEmpty || accessUsers.isNotEmpty || accessCode.isNotEmpty;

  bool userHasAccess(String userId, List<String> userGroupIds) {
    if (isPrivate) return createdBy == userId;
    if (!hasRestrictedAccess) return true;
    if (accessUsers.containsKey(userId)) return true;
    for (final gid in userGroupIds) {
      if (accessGroups.containsKey(gid)) return true;
    }
    return false;
  }

  factory Taadia.fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return Taadia(id: id, title: '', createdBy: '', createdAt: DateTime.now());
    }
    try {
      final accessGroupsRaw = (data['accessGroups'] as Map?)?.cast<String, dynamic>() ?? {};
      final accessUsersRaw = (data['accessUsers'] as Map?)?.cast<String, dynamic>() ?? {};
      final categoriesRaw = data['categories'] as List<dynamic>?;
      final classificationsRaw = data['classifications'] as List<dynamic>?;
      final List<ClassificationConfig> classifications;
      if (classificationsRaw != null) {
        if (classificationsRaw.isNotEmpty && classificationsRaw.first is String) {
          classifications = classificationsRaw
              .map((s) => ClassificationConfig(name: s.toString()))
              .toList();
        } else {
          classifications = classificationsRaw
              .map((e) => e is Map
                  ? ClassificationConfig.fromMap(Map<String, dynamic>.from(e))
                  : ClassificationConfig(name: e.toString()))
              .toList();
        }
      } else {
        classifications = [];
      }
      return Taadia(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        status: data['status'] ?? 'active',
        formula: data['formula'] ?? 'ichaarat+taalakin',
        visibility: data['visibility'] ?? 'public',
        accessGroups: accessGroupsRaw.map((k, v) => MapEntry(k, v == true)),
        accessUsers: accessUsersRaw.map((k, v) => MapEntry(k, v == true)),
        accessCode: data['accessCode'] ?? '',
        categories: categoriesRaw != null ? categoriesRaw.map((e) => e.toString()).toList() : [],
        classifications: classifications,
      );
    } catch (e) {
      return Taadia(id: id, title: data['title'] ?? '', createdBy: data['createdBy'] ?? '', createdAt: DateTime.now());
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': DateTime.now(),
      'status': status,
      'formula': formula,
      'visibility': visibility,
      'accessGroups': accessGroups,
      'accessUsers': accessUsers,
      'accessCode': accessCode,
      'categories': categories,
      'classifications': classifications.map((c) => c.toMap()).toList(),
    };
  }
}
