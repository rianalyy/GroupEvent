import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guest_model.dart';
import '../services/database_service.dart';

class GuestState {
  final List<GuestModel> guests;
  final bool isLoading;
  final String? error;

  const GuestState({this.guests = const [], this.isLoading = false, this.error});

  GuestState copyWith({List<GuestModel>? guests, bool? isLoading, String? error}) {
    return GuestState(guests: guests ?? this.guests, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class GuestNotifier extends FamilyNotifier<GuestState, int> {
  @override
  GuestState build(int eventId) {
    loadGuests(eventId);
    return const GuestState(isLoading: true);
  }

  Future<void> loadGuests(int eventId) async {
    state = state.copyWith(isLoading: true, error: null);
    final guests = await DatabaseService.getGuestsForEvent(eventId);
    state = state.copyWith(guests: guests, isLoading: false);
  }

  Future<String?> inviteByEmail(String email, int eventId) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Veuillez entrer un email.';

    final user = await DatabaseService.getUserByEmail(trimmed);
    if (user == null) return 'Aucun compte trouvé avec cet email.';

    final alreadyInvited = await DatabaseService.isAlreadyInvited(trimmed, eventId);
    if (alreadyInvited) return 'Cet utilisateur est déjà invité.';

    await DatabaseService.addGuest(GuestModel(
      eventId: eventId,
      name: user.name,
      email: user.email,
      userId: user.id,
    ));
    await loadGuests(eventId);
    return null;
  }

  Future<void> updateRsvp(int guestId, RsvpStatus status, int eventId) async {
    await DatabaseService.updateGuestRsvp(guestId, status);
    await loadGuests(eventId);
  }

  Future<void> deleteGuest(int guestId, int eventId) async {
    await DatabaseService.deleteGuest(guestId);
    await loadGuests(eventId);
  }
}

final guestProvider = NotifierProviderFamily<GuestNotifier, GuestState, int>(GuestNotifier.new);
