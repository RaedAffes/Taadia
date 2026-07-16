DateTime _parseCreatedAt(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  try {
    return (value as dynamic).toDate();
  } catch (_) {
    return DateTime.now();
  }
}

class FeedbackReply {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final DateTime createdAt;

  FeedbackReply({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    required this.createdAt,
  });

  factory FeedbackReply.fromFirestore(String id, Map<String, dynamic> data) {
    return FeedbackReply(
      id: id,
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }
}

class FeedbackItem {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  factory FeedbackItem.fromFirestore(String id, Map<String, dynamic> data) {
    return FeedbackItem(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      message: data['message'] ?? '',
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': DateTime.now(),
    };
  }
}
