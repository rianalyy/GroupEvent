import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/guest_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';
import 'event_widgets.dart';

class GuestsTab extends StatelessWidget {
  final GuestState guestState;
  final int eventId;
  final bool isOwner;
  final WidgetRef ref;
  const GuestsTab({super.key, required this.guestState, required this.eventId, required this.isOwner, required this.ref});

  @override
  Widget build(BuildContext context) {
    final confirmed = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.oui).length;
    final pending   = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.pending).length;
    final maybe     = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.peutEtre).length;
    final no        = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.non).length;

    return Column(children: [
      if (guestState.guests.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              RsvpStatWidget(count: confirmed, label: 'Oui',        color: AppColors.success),
              RsvpStatWidget(count: maybe,     label: 'Peut-être',  color: AppColors.warning),
              RsvpStatWidget(count: no,        label: 'Non',        color: AppColors.error),
              RsvpStatWidget(count: pending,   label: 'En attente', color: Colors.white38),
            ]),
          ),
        ),
      if (isOwner)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () => _showInviteSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Inviter par email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),
      Expanded(
        child: guestState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
            : guestState.guests.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 60, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    const Text('Aucun invité', style: TextStyle(color: Colors.white38, fontSize: 15)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: guestState.guests.length,
                    itemBuilder: (ctx, i) => GuestCard(
                      guest: guestState.guests[i], isOwner: isOwner, eventId: eventId, ref: ref),
                  ),
      ),
    ]);
  }

  void _showInviteSheet(BuildContext context) {
    final ctrl = TextEditingController();
    String? errorMsg;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inviter par email', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("L'email doit correspondre à un compte GroupEvent existant.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 18),
            TextField(
              controller: ctrl, style: const TextStyle(color: AppColors.white), keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Email de l'invité", hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 20),
                filled: true, fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
              ),
            ),
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(30)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: () async {
                  final err = await ref.read(guestProvider(eventId).notifier).inviteByEmail(ctrl.text, eventId);
                  if (err == null) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation envoyée !'), backgroundColor: AppColors.success));
                    }
                  } else { set(() => errorMsg = err); }
                },
                child: const Text('Inviter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
