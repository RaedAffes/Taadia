class QuestionItem {
  final int number;
  int ichaarat;
  int taalakin;
  String note;
  String questionText;
  bool isComplete;
  List<bool> topCubes;
  List<bool> bottomCubes;

  int get tSetCount => bottomCubes.length;

  QuestionItem({
    required this.number,
    this.ichaarat = 0,
    this.taalakin = 0,
    this.note = '',
    this.questionText = '',
    this.isComplete = false,
    List<bool>? topCubes,
    List<bool>? bottomCubes,
  }) : topCubes = topCubes ?? [false, false],
       bottomCubes = bottomCubes ?? [false];

  void syncFromCubes() {
    ichaarat = 0;
    taalakin = 0;
    for (int i = 0; i < tSetCount; i++) {
      final top1 = topCubes[i * 2];
      final top2 = topCubes[i * 2 + 1];
      final bottom = bottomCubes[i];
      if (bottom) {
        taalakin++;
      } else {
        if (top1) ichaarat++;
        if (top2) ichaarat++;
      }
    }
  }

  double get weightedScore => 0.25 * ichaarat + 1.0 * taalakin;
  bool get isOverWeight => weightedScore > 2;

  int countRemovableIchaarat({int? skipTSet}) {
    int count = 0;
    for (int i = 0; i < tSetCount; i++) {
      if (i == skipTSet) continue;
      if (!bottomCubes[i]) {
        if (topCubes[i * 2]) count++;
        if (topCubes[i * 2 + 1]) count++;
      }
    }
    return count;
  }

  int deselectIchaarat(int count, {int? skipTSet}) {
    int removed = 0;
    for (int i = 0; i < tSetCount && removed < count; i++) {
      if (i == skipTSet) continue;
      if (!bottomCubes[i]) {
        if (topCubes[i * 2] && removed < count) {
          topCubes[i * 2] = false;
          removed++;
        }
        if (topCubes[i * 2 + 1] && removed < count) {
          topCubes[i * 2 + 1] = false;
          removed++;
        }
      }
    }
    return removed;
  }

  bool addTSet() {
    topCubes.addAll([false, false]);
    bottomCubes.add(false);
    return true;
  }

  void removeTSet() {
    if (tSetCount <= 1) return;
    topCubes.removeRange(topCubes.length - 2, topCubes.length);
    bottomCubes.removeLast();
  }

  factory QuestionItem.fromMap(Map<String, dynamic> data) {
    final topCubesRaw = data['topCubes'] as List<dynamic>?;
    final bottomCubesRaw = data['bottomCubes'] as List<dynamic>?;
    final ich = data['ichaarat'] ?? 0;
    final tal = data['taalakin'] ?? 0;

    final isComplete = data['isComplete'] == true;

    if (topCubesRaw != null && bottomCubesRaw != null) {
      return QuestionItem(
        number: data['number'] ?? 0,
        ichaarat: ich,
        taalakin: tal,
        note: data['note'] ?? '',
        questionText: data['questionText'] as String? ?? '',
        isComplete: isComplete,
        topCubes: topCubesRaw.map((c) => c == true).toList(),
        bottomCubes: bottomCubesRaw.map((c) => c == true).toList(),
      );
    }

    final List<bool> top = [];
    final List<bool> bottom = [];
    final int ichCount = ich as int;
    final int talCount = tal as int;

    for (int i = 0; i < talCount; i++) {
      top.addAll([false, false]);
      bottom.add(true);
    }
    int remaining = ichCount;
    while (remaining > 0) {
      top.add(remaining > 0);
      top.add(remaining > 1);
      bottom.add(false);
      remaining -= 2;
    }
    if (top.isEmpty) {
      top.addAll([false, false]);
      bottom.add(false);
    }
    return QuestionItem(
      number: data['number'] ?? 0,
      ichaarat: ichCount,
      taalakin: talCount,
      note: data['note'] ?? '',
      questionText: data['questionText'] as String? ?? '',
      isComplete: isComplete,
      topCubes: top,
      bottomCubes: bottom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'ichaarat': ichaarat,
      'taalakin': taalakin,
      'note': note,
      'questionText': questionText,
      'isComplete': isComplete,
      'topCubes': topCubes,
      'bottomCubes': bottomCubes,
    };
  }
}

class Evaluation {
  final String id;
  final String taadiaId;
  final String userId;
  final String evaluatorName;
  final String studentName;
  final List<String> categories;
  final Map<String, String> classificationValues;
  final int numQuestions;
  final int numAhzab;
  final String specialAhzab;
  final List<Map<String, dynamic>> rangeCriteria;
  final List<QuestionItem> questions;
  final String note;
  final DateTime createdAt;

  Evaluation({
    required this.id,
    required this.taadiaId,
    required this.userId,
    this.evaluatorName = '',
    required this.studentName,
    this.categories = const [],
    this.classificationValues = const {},
    this.numQuestions = 0,
    this.numAhzab = 0,
    this.specialAhzab = '',
    this.rangeCriteria = const [],
    this.questions = const [],
    this.note = '',
    required this.createdAt,
  });

  factory Evaluation.fromFirestore(String id, Map<String, dynamic> data) {
    final questionsRaw = data['questions'] as List<dynamic>? ?? [];
    final dynamic catsRaw = data['categories'] ?? data['category'] ?? '';
    final List<String> cats;
    if (catsRaw is List) {
      cats = catsRaw.cast<String>();
    } else if (catsRaw is String && catsRaw.isNotEmpty) {
      cats = [catsRaw];
    } else {
      cats = [];
    }
    final classValuesRaw = (data['classificationValues'] as Map?)?.cast<String, dynamic>();
    final Map<String, String> classValues = classValuesRaw != null
        ? classValuesRaw.map((k, v) => MapEntry(k, v.toString()))
        : {};
    return Evaluation(
      id: id,
      taadiaId: data['taadiaId'] ?? '',
      userId: data['userId'] ?? '',
      evaluatorName: data['evaluatorName'] ?? '',
      studentName: data['studentName'] ?? '',
      categories: cats,
      classificationValues: classValues,
      numQuestions: data['numQuestions'] ?? 0,
      numAhzab: data['numAhzab'] ?? 0,
      specialAhzab: data['specialAhzab'] ?? '',
      rangeCriteria: (data['rangeCriteria'] as List<dynamic>?)
              ?.map((m) => Map<String, dynamic>.from(m as Map))
              .toList() ??
          [],
      questions: questionsRaw
          .map((q) => QuestionItem.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
      note: data['note'] ?? '',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : data['createdAt'] is String
              ? DateTime.parse(data['createdAt'] as String)
              : (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taadiaId': taadiaId,
      'userId': userId,
      'evaluatorName': evaluatorName,
      'studentName': studentName,
      'categories': categories,
      'classificationValues': classificationValues,
      'numQuestions': numQuestions,
      'numAhzab': numAhzab,
      'specialAhzab': specialAhzab,
      'rangeCriteria': rangeCriteria,
      'questions': questions.map((q) => q.toMap()).toList(),
      'note': note,
      'createdAt': DateTime.now(),
    };
  }

  int get totalIchaarat => questions.fold(0, (sum, q) => sum + q.ichaarat);

  int get totalTaalakin => questions.fold(0, (sum, q) => sum + q.taalakin);
}
