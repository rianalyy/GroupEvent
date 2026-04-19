import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/event_model.dart';
import '../../../viewmodels/event_viewmodel.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final WidgetRef? ref;
  const EventCard({super.key, required this.event, required this.isOwner, this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isOwner ? Colors.white.withOpacity(0.12) : AppColors.warning.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (!isOwner)
              Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4))),
                  child: const Text('Invité', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
            Expanded(child: Text(event.title, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            if (isOwner && ref != null)
              GestureDetector(
                onTap: () async { if (event.id != null) await ref!.read(eventProvider.notifier).deleteEvent(event.id!); },
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20)),
          ]),
          const SizedBox(height: 12),
          _Row(icon: Icons.calendar_today_rounded, text: event.date),
          if (event.location.isNotEmpty) ...[const SizedBox(height: 6), _Row(icon: Icons.location_on_outlined, text: event.location)],
          const SizedBox(height: 6),
          _Row(icon: Icons.group_outlined, text: '${event.participants} participant${event.participants > 1 ? 's' : ''}'),
          const SizedBox(height: 6),
          _Row(icon: Icons.account_balance_wallet_outlined, text: '${event.budget.toStringAsFixed(0)} Ar', color: AppColors.secondaryLight),
          if (event.description?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Text(event.description!, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4))),
          ],
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon; final String text; final Color? color;
  const _Row({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color ?? Colors.white54),
    const SizedBox(width: 7),
    Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white60, fontSize: 13))),
  ]);
}

class HomeBadge extends StatelessWidget {
  final int count; final Color color;
  const HomeBadge({super.key, required this.count, this.color = AppColors.secondaryLight});
  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(color: color.withOpacity(0.25), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))),
    child: Center(child: Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
  );
}

class MyEventsTab extends StatelessWidget {
  final List<EventModel> events; final WidgetRef ref;
  const MyEventsTab({super.key, required this.events, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_note_rounded, size: 72, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text('Aucun événement créé', style: TextStyle(color: Colors.white38, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Appuyez sur + pour créer votre premier événement', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (_, i) => EventCard(event: events[i], isOwner: true, ref: ref),
    );
  }
}

class InvitedEventsTab extends StatelessWidget {
  final List<EventModel> events;
  const InvitedEventsTab({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.mail_outline_rounded, size: 72, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 16),
        const Text('Aucune invitation reçue', style: TextStyle(color: Colors.white38, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Les événements auxquels vous êtes invité apparaîtront ici', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (_, i) => EventCard(event: events[i], isOwner: false),
    );
  }
}
