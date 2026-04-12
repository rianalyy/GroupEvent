class ChatMessageModel {
  final int? id;
  final int eventId;
  final int userId;
  final String userName;
  final String message;
  final DateTime sentAt;

  ChatMessageModel({
    this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
    'event_id': eventId,
    'user_id': userId,
    'user_name': userName,
    'message': message,
    'sent_at': sentAt.toIso8601String(),
  };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
    id: map['id'],
    eventId: map['event_id'],
    userId: map['user_id'],
    userName: map['user_name'],
    message: map['message'],
    sentAt: DateTime.parse(map['sent_at']),
  );
}
