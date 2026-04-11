class TaskModel {
  final int? id;
  final int eventId;
  final String title;
  final bool isDone;
  final int? assignedToGuestId;
  final int? assignedToUserId;
  final String? assignedToName;

  TaskModel({
    this.id,
    required this.eventId,
    required this.title,
    this.isDone = false,
    this.assignedToGuestId,
    this.assignedToUserId,
    this.assignedToName,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'title': title.trim(),
      'is_done': isDone ? 1 : 0,
      'assigned_to_guest_id': assignedToGuestId,
      'assigned_to_user_id': assignedToUserId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      eventId: map['event_id'],
      title: map['title'],
      isDone: map['is_done'] == 1,
      assignedToGuestId: map['assigned_to_guest_id'],
      assignedToUserId: map['assigned_to_user_id'],
      assignedToName: map['assigned_name'],
    );
  }

  TaskModel copyWith({
    int? id,
    bool? isDone,
    int? assignedToGuestId,
    int? assignedToUserId,
    String? assignedToName,
  }) {
    return TaskModel(
      id: id ?? this.id,
      eventId: eventId,
      title: title,
      isDone: isDone ?? this.isDone,
      assignedToGuestId: assignedToGuestId ?? this.assignedToGuestId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }

  bool isAssignedToUser(int userId) => assignedToUserId == userId;
  bool isAssignedToGuest(int guestId) => assignedToGuestId == guestId;
  bool get hasAssignee => assignedToGuestId != null || assignedToUserId != null;
}
