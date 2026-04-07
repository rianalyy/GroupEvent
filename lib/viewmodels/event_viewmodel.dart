import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

class EventState {
  final List<EventModel> events;
  final bool isLoading;

  const EventState({
    this.events = const [],
    this.isLoading = false,
  });

  EventState copyWith({
    List<EventModel>? events,
    bool? isLoading,
  }) {
    return EventState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EventNotifier extends Notifier<EventState> {
  @override
  EventState build() {
    loadEvents();
    return const EventState(isLoading: true);
  }

  Future<void> loadEvents() async {
    final user = SessionService.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    final events = await DatabaseService.getEventsByUser(user.id!);
    state = state.copyWith(events: events, isLoading: false);
  }

  Future<void> addEvent(EventModel event) async {
    await DatabaseService.insertEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(int eventId) async {
    await DatabaseService.deleteEvent(eventId);
    await loadEvents();
  }
}

final eventProvider = NotifierProvider<EventNotifier, EventState>(
  EventNotifier.new,
);
