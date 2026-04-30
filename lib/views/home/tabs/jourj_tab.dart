import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/event_model.dart';
import '../../../models/guest_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';
import '../../../viewmodels/task_viewmodel.dart';
import '../../../services/notification_service.dart';
import 'event_widgets.dart';

class JourJTab extends StatelessWidget {
  final EventModel event;
  final TaskState taskState;
  final GuestState guestState;
  final WidgetRef ref;
  const JourJTab({super.key, required this.event, required this.taskState, required this.guestState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isToday  = NotificationService.isToday(event.date);
    final daysLeft = NotificationService.daysUntil(event.date);
    final isPast   = daysLeft < 0;
    final confirmed = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.oui).length;
    final totalP    = confirmed + 1;
    final budgetP   = totalP > 0 ? event.budget / totalP : event.budget;
    final total = taskState.tasks.length;
    final done  = taskState.tasks.where((t) => t.isDone).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildStatusBanner(isToday, isPast, daysLeft),
        const SizedBox(height: 20),
        const Text('Checklist', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Informations importantes de l\'événement', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 14),
        CheckItem(icon: Icons.title_rounded, label: 'Titre', value: event.title, isDone: event.title.isNotEmpty),
        CheckItem(icon: Icons.calendar_today_rounded, label: 'Date', value: event.date, isDone: event.date.isNotEmpty),
        CheckItem(
          icon: Icons.location_on_rounded, label: 'Lieu',
          value: event.location.isNotEmpty ? event.location : 'Non défini',
          isDone: event.location.isNotEmpty,
          actionIcon: event.location.isNotEmpty ? Icons.map_outlined : null,
          onTap: event.hasCoordinates ? () => Navigator.pushNamed(context, AppRoutes.map, arguments: {
            'location': event.location, 'title': event.title,
            'latitude': event.latitude, 'longitude': event.longitude,
          }) : null,
        ),
        CheckItem(icon: Icons.group_rounded, label: 'Participants confirmés',
            value: '$confirmed confirmé(s) / ${guestState.guests.length} invité(s)', isDone: confirmed > 0),
        CheckItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget',
            value: event.budget > 0 ? '${event.budget.toStringAsFixed(0)} Ar total · ${budgetP.toStringAsFixed(0)} Ar/confirmé' : 'Non défini',
            isDone: event.budget > 0),
        CheckItem(icon: Icons.task_alt_rounded, label: 'Tâches',
            value: total > 0 ? '$done / $total terminée(s)' : 'Aucune tâche définie',
            isDone: total > 0 && done == total, isWarning: total > 0 && done < total),
        CheckItem(icon: Icons.description_rounded, label: 'Description',
            value: (event.description?.isNotEmpty == true) ? event.description! : 'Non renseignée',
            isDone: event.description?.isNotEmpty == true, isOptional: true),
        if (total > 0) ...[
          const SizedBox(height: 20),
          const Text('Tâches du jour', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTaskProgress(total, done),
        ],
        if (guestState.guests.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Présence', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...guestState.guests.map((g) => _buildGuestPresence(g)),
        ],
      ]),
    );
  }

  Widget _buildStatusBanner(bool isToday, bool isPast, int daysLeft) {
    final Color c = isToday ? AppColors.warning : isPast ? Colors.white24 : AppColors.primaryLight;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.withOpacity(0.25), c.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withOpacity(isToday ? 0.5 : 0.3), width: isToday ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(isToday ? Icons.celebration_rounded : isPast ? Icons.event_busy_rounded : Icons.event_rounded,
              color: isToday ? AppColors.warning : isPast ? Colors.white38 : AppColors.secondaryLight, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isToday ? "🎉 C'est aujourd'hui !" : isPast ? 'Événement passé' : 'Compte à rebours',
              style: TextStyle(color: isToday ? AppColors.warning : isPast ? Colors.white38 : AppColors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(isToday ? event.date : isPast ? 'Il y a ${(-daysLeft)} jour${(-daysLeft) > 1 ? 's' : ''}'
              : daysLeft == 1 ? 'Demain !' : 'Dans $daysLeft jours',
              style: TextStyle(color: isToday ? AppColors.warning.withOpacity(0.8) : Colors.white54, fontSize: 13)),
        ])),
      ]),
    );
  }

  Widget _buildTaskProgress(int total, int done) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$done / $total tâches', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text('${total > 0 ? (done / total * 100).toInt() : 0}%',
              style: TextStyle(color: done == total ? AppColors.success : AppColors.secondaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: total > 0 ? done / total : 0, minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(done == total ? AppColors.success : AppColors.secondaryLight))),
        const SizedBox(height: 14),
        ...taskState.tasks.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 200), width: 20, height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, color: t.isDone ? AppColors.success : Colors.transparent,
                  border: Border.all(color: t.isDone ? AppColors.success : Colors.white38, width: 2)),
              child: t.isDone ? const Icon(Icons.check, color: Colors.white, size: 12) : null),
            const SizedBox(width: 10),
            Expanded(child: Text(t.title, style: TextStyle(color: t.isDone ? Colors.white38 : AppColors.white, fontSize: 13,
                decoration: t.isDone ? TextDecoration.lineThrough : null, decorationColor: Colors.white38))),
            if (t.assignedToName?.isNotEmpty == true)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.secondaryLight.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(t.assignedToName!, style: const TextStyle(color: AppColors.secondaryLight, fontSize: 10))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildGuestPresence(GuestModel g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: g.rsvpStatus.color.withOpacity(0.2))),
      child: Row(children: [
        CircleAvatar(radius: 16, backgroundColor: g.rsvpStatus.color.withOpacity(0.15),
          child: Text(g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
              style: TextStyle(color: g.rsvpStatus.color, fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(child: Text(g.name, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: g.rsvpStatus.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: g.rsvpStatus.color.withOpacity(0.35))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(g.rsvpStatus.icon, color: g.rsvpStatus.color, size: 12),
            const SizedBox(width: 4),
            Text(g.rsvpStatus.label, style: TextStyle(color: g.rsvpStatus.color, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
      ]),
    );
  }
}
