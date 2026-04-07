import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

class EventViewModel extends ChangeNotifier {
  List<EventModel> events = [];
  bool isLoading = false;

  Future<void> loadEvents() async {
    final user = SessionService.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    events = await DatabaseService.getEventsByUser(user.id!);

    isLoading = false;
    notifyListeners();
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
