class TaskModel {
  final int? id;
  final int eventId;
  final String title;
  final bool isDone;
  final int? assignedToGuestId;

  TaskModel({
    this.id,
    required this.eventId,
    required this.title,
    this.isDone = false,
    this.assignedToGuestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'title': title.trim(),
      'is_done': isDone ? 1 : 0,
      'assigned_to_guest_id': assignedToGuestId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      eventId: map['event_id'],
      title: map['title'],
      isDone: map['is_done'] == 1,
      assignedToGuestId: map['assigned_to_guest_id'],
    );
  }

  TaskModel copyWith({int? id, bool? isDone, int? assignedToGuestId}) {
    return TaskModel(
      id: id ?? this.id,
      eventId: eventId,
      title: title,
      isDone: isDone ?? this.isDone,
      assignedToGuestId: assignedToGuestId ?? this.assignedToGuestId,
    );
  }
}
