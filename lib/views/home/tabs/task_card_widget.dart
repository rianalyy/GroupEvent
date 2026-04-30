import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guest_model.dart';
import '../../../models/task_model.dart';
import '../../../viewmodels/task_viewmodel.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final List<GuestModel> confirmedGuests;
  final int eventId;
  final bool isOwner;
  final bool canToggle;
  final WidgetRef ref;

  const TaskCard({
    required this.task,
    required this.confirmedGuests,
    required this.eventId,
    required this.isOwner,
    required this.canToggle,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hasAssignee = task.assignedToName != null && task.assignedToName!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: task.isDone ? AppColors.success.withOpacity(0.25)
            : canToggle ? AppColors.secondaryLight.withOpacity(0.3) : Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canToggle
              ? () => ref.read(taskProvider(eventId).notifier).toggleTask(task.id!, !task.isDone, eventId)
              : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Vous pouvez uniquement cocher vos propres tâches.'),
                  backgroundColor: AppColors.warning, duration: Duration(seconds: 2))),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: task.isDone ? AppColors.success : Colors.transparent,
              border: Border.all(
                  color: task.isDone ? AppColors.success : canToggle ? AppColors.secondaryLight : Colors.white24,
                  width: 2)),
            child: task.isDone
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : canToggle ? null : const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 11),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title, style: TextStyle(color: task.isDone ? Colors.white38 : AppColors.white, fontSize: 13,
              decoration: task.isDone ? TextDecoration.lineThrough : null, decorationColor: Colors.white38)),
          if (hasAssignee)
            Row(children: [
              const Icon(Icons.person_pin_rounded, color: AppColors.secondaryLight, size: 12),
              const SizedBox(width: 4),
              Text(task.assignedToName!, style: const TextStyle(color: AppColors.secondaryLight, fontSize: 11)),
            ])
          else
            const Text('Non assigné', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ])),
        if (isOwner && confirmedGuests.isNotEmpty)
          GestureDetector(
            onTap: () => _showAssign(context),
            child: Container(padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white38, size: 15)),
          ),
        if (isOwner) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(taskProvider(eventId).notifier).deleteTask(task.id!, eventId),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16)),
        ],
      ]),
    );
  }

  void _showAssign(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Assigner "${task.title}"',
              style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 13),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Seuls les invités ayant répondu "Oui" apparaissent ici.',
                style: const TextStyle(color: AppColors.success, fontSize: 11),
              )),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.person_off_outlined, color: Colors.white54),
            title: const Text('Non assigné', style: TextStyle(color: Colors.white70)),
            trailing: !task.hasAssignee
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                : null,
            onTap: () {
              ref.read(taskProvider(eventId).notifier).unassign(task.id!, eventId);
              Navigator.pop(ctx);
            },
          ),
          Divider(color: Colors.white.withOpacity(0.08)),
          ...confirmedGuests.map((g) => ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.success.withOpacity(0.2),
              child: Text(g.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text(g.name, style: const TextStyle(color: AppColors.white)),
            subtitle: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 11),
              const SizedBox(width: 3),
              const Text('Confirmé', style: TextStyle(color: AppColors.success, fontSize: 10)),
            ]),
            trailing: task.assignedToGuestId == g.id
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                : null,
            onTap: () {
              ref.read(taskProvider(eventId).notifier).assignToGuest(task.id!, g.id, eventId);
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }
}
