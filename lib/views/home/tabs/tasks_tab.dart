import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guest_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';
import '../../../viewmodels/task_viewmodel.dart';
import 'event_widgets.dart';
import 'task_card_widget.dart';

class TasksTab extends StatelessWidget {
  final TaskState taskState;
  final GuestState guestState;
  final int eventId;
  final bool isOwner;
  final UserModel? currentUser;
  final WidgetRef ref;
  final double budget;

  const TasksTab({super.key, required this.taskState, required this.guestState,
      required this.eventId, required this.isOwner, required this.currentUser,
      required this.ref, required this.budget});

  bool _canToggle(TaskModel task) {
    if (currentUser == null) return false;
    if (task.assignedToUserId == currentUser!.id) return true;
    if (task.assignedToGuestId != null) {
      final myGuest = guestState.guests.firstWhere(
        (g) => g.userId == currentUser!.id,
        orElse: () => GuestModel(eventId: eventId, name: ''),
      );
      if (myGuest.id != null && task.assignedToGuestId == myGuest.id) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final total = taskState.totalTasks;
    final done  = taskState.doneTasks;
    final nbGuests = guestState.guests.length;
    final totalP = nbGuests + 1;
    final budgetP = totalP > 0 && budget > 0 ? budget / totalP : 0.0;
    final tasksP  = total > 0 && nbGuests > 0 ? (total / totalP).ceil() : total;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Row(children: [
              DashIcon(icon: Icons.account_balance_wallet_outlined, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Budget par participant', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(budgetP > 0 ? '${budgetP.toStringAsFixed(0)} Ar  ×  $totalP pers.' : 'Budget non défini',
                    style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold)),
              ])),
            ]),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),
            Row(children: [
              DashIcon(icon: Icons.checklist_rounded, color: AppColors.secondaryLight),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(total > 0 ? '$total tâche(s) • $done terminée(s)' : 'Aucune tâche',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                if (total > 0 && nbGuests > 0)
                  Text('≈ $tasksP tâche(s) par participant',
                      style: const TextStyle(color: AppColors.secondaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
            ]),
            if (total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: taskState.progressPercent, minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success))),
            ],
          ]),
        ),
      ),
      if (isOwner) _buildButtons(context),
      Expanded(
        child: taskState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
            : taskState.tasks.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.checklist_rtl_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    const Text('Aucune tâche', style: TextStyle(color: Colors.white38, fontSize: 15)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: taskState.tasks.length,
                    itemBuilder: (ctx, i) {
                      final task = taskState.tasks[i];
                      return TaskCard(task: task, guests: guestState.guests, eventId: eventId,
                          isOwner: isOwner, canToggle: _canToggle(task), ref: ref);
                    }),
      ),
    ]);
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => _showAddTask(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_task_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: taskState.isDistributing ? null : () async {
            if (guestState.guests.isEmpty || currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Invitez d'abord des participants."), backgroundColor: AppColors.warning));
              return;
            }
            final msg = await ref.read(taskProvider(eventId).notifier).autoDistribute(
                guests: guestState.guests, creator: currentUser!, eventId: eventId);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: AppColors.success, duration: const Duration(seconds: 3)));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondaryLight.withOpacity(0.35))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              taskState.isDistributing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.secondaryLight, strokeWidth: 2))
                  : const Icon(Icons.shuffle_rounded, color: AppColors.secondaryLight, size: 16),
              const SizedBox(width: 6),
              Text(taskState.isDistributing ? 'Répartition...' : 'Auto-répartir',
                  style: TextStyle(color: taskState.isDistributing ? Colors.white38 : AppColors.secondaryLight,
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        )),
      ]),
    );
  }

  void _showAddTask(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nouvelle tâche', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(hintText: 'Description', hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.task_outlined, color: Colors.white38),
                  filled: true, fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)))),
          const SizedBox(height: 18),
          Container(width: double.infinity, height: 50,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(30)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () async {
                await ref.read(taskProvider(eventId).notifier).addTask(ctrl.text, eventId);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )),
        ]),
      ),
    );
  }
}

