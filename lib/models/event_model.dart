class EventModel {
  final int? id;
  final String title;
  final String date;
  final String location;
  final int participants;
  final double budget;
  final String? description;
  final int? creatorId;

  EventModel({
    this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.participants,
    required this.budget,
    this.description,
    this.creatorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'participants': participants,
      'budget': budget,
      'description': description ?? '',
      'creator_id': creatorId,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      location: map['location'] ?? '',
      participants: map['participants'],
      budget: (map['budget'] as num).toDouble(),
      description: map['description'],
      creatorId: map['creator_id'],
    );
  }
}
