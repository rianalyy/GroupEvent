import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guest_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';

class RsvpTab extends StatelessWidget {
  final int eventId;
  final int? currentUserId;
  final GuestState guestState;
  final WidgetRef ref;
  const RsvpTab({super.key, required this.eventId, required this.currentUserId, required this.guestState, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) return const SizedBox();
    if (guestState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight));
    }

    GuestModel? myGuest;
    try { myGuest = guestState.guests.firstWhere((g) => g.userId == currentUserId); }
    catch (_) { myGuest = null; }

    if (myGuest == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.how_to_reg_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 12),
        const Text("Vous n'êtes pas invité(e)\nà cet événement",
            style: TextStyle(color: Colors.white38, fontSize: 14), textAlign: TextAlign.center),
      ]));
    }

    final guest = myGuest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Votre réponse',
            style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Indiquez si vous participez à cet événement',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: guest.rsvpStatus.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: guest.rsvpStatus.color.withOpacity(0.35)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: guest.rsvpStatus.color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(guest.rsvpStatus.icon, color: guest.rsvpStatus.color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Statut actuel', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(guest.rsvpStatus.label,
                  style: TextStyle(color: guest.rsvpStatus.color, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Changer ma réponse',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        ...RsvpStatus.values.where((s) => s != RsvpStatus.pending).map((status) {
          final isSelected = guest.rsvpStatus == status;
          return GestureDetector(
            onTap: () => ref.read(guestProvider(eventId).notifier).updateRsvp(guest.id!, status, eventId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? status.color.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected ? status.color : Colors.white.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(status.icon, color: status.color, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(status.label,
                    style: TextStyle(
                      color: isSelected ? status.color : Colors.white70, fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                if (isSelected) Icon(Icons.check_circle_rounded, color: status.color, size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
      ]),
    );
  }
}
