import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

class EventState {
  final List<EventModel> myEvents;
  final List<EventModel> invitedEvents;
  final bool isLoading;

  const EventState({
    this.myEvents = const [],
    this.invitedEvents = const [],
    this.isLoading = false,
  });

  EventState copyWith({
    List<EventModel>? myEvents,
    List<EventModel>? invitedEvents,
    bool? isLoading,
  }) {
    return EventState(
      myEvents: myEvents ?? this.myEvents,
      invitedEvents: invitedEvents ?? this.invitedEvents,
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
    if (user == null) {
      state = const EventState();
      return;
    }
    state = state.copyWith(isLoading: true);
    final myEvents = await DatabaseService.getEventsByUser(user.id!);
    final invitedEvents = await DatabaseService.getInvitedEvents(user.id!);
    state = state.copyWith(
      myEvents: myEvents,
      invitedEvents: invitedEvents,
      isLoading: false,
    );
  }

  void resetState() {
    state = const EventState();
  }

  String _generateInviteCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<EventModel> addEvent(EventModel event, List<String> taskTitles) async {
    final code = _generateInviteCode();
    final newEvent = EventModel(
      title: event.title,
      date: event.date,
      location: event.location,
      participants: event.participants,
      budget: event.budget,
      description: event.description,
      creatorId: event.creatorId,
      inviteCode: code,
    );
    final id = await DatabaseService.insertEvent(newEvent);
    for (final title in taskTitles) {
      if (title.trim().isNotEmpty) {
        await DatabaseService.insertTask(TaskModel(eventId: id, title: title.trim()));
      }
    }
    await loadEvents();
    return EventModel(
      id: id,
      title: newEvent.title,
      date: newEvent.date,
      location: newEvent.location,
      participants: newEvent.participants,
      budget: newEvent.budget,
      description: newEvent.description,
      creatorId: newEvent.creatorId,
      inviteCode: code,
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await DatabaseService.deleteEvent(eventId);
    await loadEvents();
  }
}

final eventProvider = NotifierProvider<EventNotifier, EventState>(
  EventNotifier.new,
);
