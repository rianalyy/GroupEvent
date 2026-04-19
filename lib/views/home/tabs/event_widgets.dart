import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guest_model.dart';
import '../../../models/task_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/task_viewmodel.dart';

class EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const EventInfoRow({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color ?? Colors.white54),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white60, fontSize: 13))),
  ]);
}

class RsvpStatWidget extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const RsvpStatWidget({super.key, required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
  ]);
}

class GuestCard extends StatelessWidget {
  final GuestModel guest;
  final bool isOwner;
  final int eventId;
  final WidgetRef ref;
  const GuestCard({super.key, required this.guest, required this.isOwner, required this.eventId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: guest.rsvpStatus.color.withOpacity(0.2)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: guest.rsvpStatus.color.withOpacity(0.15),
          child: Text(guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
              style: TextStyle(color: guest.rsvpStatus.color, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(guest.name, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          if (guest.email != null)
            Text(guest.email!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: guest.rsvpStatus.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: guest.rsvpStatus.color.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(guest.rsvpStatus.icon, color: guest.rsvpStatus.color, size: 12),
            const SizedBox(width: 4),
            Text(guest.rsvpStatus.label,
                style: TextStyle(color: guest.rsvpStatus.color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (isOwner) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(guestProvider(eventId).notifier).deleteGuest(guest.id!, eventId),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
          ),
        ],
      ]),
    );
  }
}

class DashIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const DashIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: color, size: 18),
  );
}

class CheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDone;
  final bool isWarning;
  final bool isOptional;
  final VoidCallback? onTap;
  final IconData? actionIcon;

  const CheckItem({
    super.key, required this.icon, required this.label, required this.value, required this.isDone,
    this.isWarning = false, this.isOptional = false, this.onTap, this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Color sc = isDone ? AppColors.success : isWarning ? AppColors.warning : isOptional ? Colors.white24 : AppColors.error;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDone ? AppColors.success.withOpacity(0.2) : isWarning ? AppColors.warning.withOpacity(0.25) : Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: sc, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: isDone ? AppColors.white : isWarning ? AppColors.warning : Colors.white38, fontSize: 13, fontWeight: isDone ? FontWeight.w500 : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          actionIcon != null
              ? Icon(actionIcon, color: AppColors.secondaryLight, size: 16)
              : Container(width: 22, height: 22, decoration: BoxDecoration(color: sc.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(isDone ? Icons.check_rounded : isWarning ? Icons.warning_amber_rounded : isOptional ? Icons.remove_rounded : Icons.close_rounded, color: sc, size: 14)),
        ]),
      ),
    );
  }
}

