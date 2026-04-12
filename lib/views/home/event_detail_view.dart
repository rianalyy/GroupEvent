import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../models/guest_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/session_service.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../../viewmodels/guest_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';

class EventDetailView extends ConsumerStatefulWidget {
  const EventDetailView({super.key});

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventId    = ModalRoute.of(context)!.settings.arguments as int;
    final eventState = ref.watch(eventProvider);
    final currentUser = SessionService.currentUser;

    EventModel? event;
    try { event = eventState.myEvents.firstWhere((e) => e.id == eventId); }
    catch (_) {
      try { event = eventState.invitedEvents.firstWhere((e) => e.id == eventId); }
      catch (_) { event = null; }
    }

    if (event == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight)),
        ),
      );
    }

    final isOwner   = event.creatorId == currentUser?.id;
    final guestState = ref.watch(guestProvider(eventId));
    final taskState  = ref.watch(taskProvider(eventId));

    final totalParticipants = guestState.guests.length + 1;
    final budgetPerPerson   = totalParticipants > 0 && event.budget > 0
        ? event.budget / totalParticipants
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
                              overflow: TextOverflow.ellipsis),
                          if (!isOwner)
                            const Text('Vous êtes invité(e)',
                                style: TextStyle(color: AppColors.warning, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.ios_share_rounded, color: AppColors.secondaryLight, size: 22),
                        onPressed: () => _showShareSheet(context, event!),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(icon: Icons.calendar_today_rounded, text: event.date),
                          ),
                          if (event.location.isNotEmpty)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.map,
                                  arguments: {
                                    'location':  event!.location,
                                    'title':     event.title,
                                    'latitude':  event.latitude,
                                    'longitude': event.longitude,
                                  },
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.location_on_rounded, color: AppColors.error, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.error,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.map_outlined, color: AppColors.error, size: 12),
                                  ]),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondaryLight.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('Budget total', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${event.budget.toStringAsFixed(0)} Ar',
                                  style: const TextStyle(color: AppColors.secondaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ]),
                            ),
                            Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    'Par pers. (÷ $totalParticipants)',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    budgetPerPerson > 0
                                        ? '${budgetPerPerson.toStringAsFixed(0)} Ar'
                                        : '— Ar',
                                    style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(event.description!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Onglets ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: AppColors.primaryGradient),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: [
                      const Tab(text: 'Invités'),
                      const Tab(text: 'Tâches'),
                      const Tab(text: 'Mon RSVP'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Jour J', style: TextStyle(fontSize: 12)),
                            if (NotificationService.isToday(event.date)) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 7, height: 7,
                                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _GuestsTab(guestState: guestState, eventId: eventId, isOwner: isOwner, ref: ref),
                    _TasksTab(
                      taskState: taskState,
                      guestState: guestState,
                      eventId: eventId,
                      isOwner: isOwner,
                      currentUser: currentUser,
                      creatorId: event.creatorId,
                      ref: ref,
                      budget: event.budget,
                    ),
                    _MyRsvpTab(eventId: eventId, currentUserId: currentUser?.id, guestState: guestState, ref: ref),
                    _JourJTab(event: event, taskState: taskState, guestState: guestState, ref: ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, EventModel event) {
    final link = 'groupevent://invite/${event.inviteCode ?? event.id}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partager le lien d\'invitation',
                style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Ce lien permet aux invités d'accéder à l'événement après connexion.",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.link_rounded, color: AppColors.secondaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(link, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Lien copié !'), backgroundColor: AppColors.success, duration: Duration(seconds: 2)));
                  },
                  child: const Icon(Icons.copy_rounded, color: AppColors.secondaryLight, size: 20),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const Text('Envoyer par email', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            _SendEmailsSection(event: event, link: link),
          ],
        ),
      ),
    );
  }
}

class _SendEmailsSection extends ConsumerWidget {
  final EventModel event;
  final String link;
  const _SendEmailsSection({required this.event, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestState = ref.watch(guestProvider(event.id!));
    final guestsWithEmail = guestState.guests.where((g) => g.email != null && g.email!.isNotEmpty).toList();

    if (guestsWithEmail.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: const Text("Ajoutez des invités avec email pour leur envoyer le lien.",
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      );
    }
    return Column(children: [
      ...guestsWithEmail.map((g) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                child: Text(g.name[0].toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(g.email!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              GestureDetector(
                onTap: () => _sendEmail(context, g.email!, g.name, event, link),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          )),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.secondaryLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.send_rounded, color: AppColors.secondaryLight, size: 18),
        label: const Text('Envoyer à tous', style: TextStyle(color: AppColors.secondaryLight)),
        onPressed: () { for (final g in guestsWithEmail) _sendEmail(context, g.email!, g.name, event, link); },
      ),
    ]);
  }

  Future<void> _sendEmail(BuildContext context, String email, String name, EventModel event, String link) async {
    final subject = Uri.encodeComponent('Invitation – ${event.title}');
    final body = Uri.encodeComponent(
      'Bonjour $name,\n\nVous êtes invité(e) à "${event.title}" sur GroupEvent.\n\n'
      '📅 ${event.date}\n📍 ${event.location.isNotEmpty ? event.location : "Non précisé"}\n\n'
      'Lien : $link\n\nÀ bientôt !',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Impossible d'ouvrir le client email."), backgroundColor: AppColors.error));
    }
  }
}

class _GuestsTab extends StatelessWidget {
  final GuestState guestState;
  final int eventId;
  final bool isOwner;
  final WidgetRef ref;
  const _GuestsTab({required this.guestState, required this.eventId, required this.isOwner, required this.ref});

  @override
  Widget build(BuildContext context) {
    final confirmedCount = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.oui).length;
    final pendingCount   = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.pending).length;
    final maybeCount     = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.peutEtre).length;
    final noCount        = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.non).length;

    return Column(children: [
      if (guestState.guests.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _RsvpStat(count: confirmedCount, label: 'Oui',        color: AppColors.success),
              _RsvpStat(count: maybeCount,     label: 'Peut-être',  color: AppColors.warning),
              _RsvpStat(count: noCount,        label: 'Non',        color: AppColors.error),
              _RsvpStat(count: pendingCount,   label: 'En attente', color: Colors.white38),
            ]),
          ),
        ),
      if (isOwner)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () => _showInviteSheet(context, eventId, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
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
                    itemBuilder: (ctx, i) => _GuestCard(
                      guest: guestState.guests[i], isOwner: isOwner, eventId: eventId, ref: ref),
                  ),
      ),
    ]);
  }

  void _showInviteSheet(BuildContext context, int eventId, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    String? errorMsg;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              controller: emailCtrl,
              style: const TextStyle(color: AppColors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email de l\'invité',
                hintStyle: const TextStyle(color: Colors.white38),
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
                  final err = await ref.read(guestProvider(eventId).notifier).inviteByEmail(emailCtrl.text, eventId);
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

class _RsvpStat extends StatelessWidget {
  final int count; final String label; final Color color;
  const _RsvpStat({required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
  ]);
}

class _GuestCard extends StatelessWidget {
  final GuestModel guest; final bool isOwner; final int eventId; final WidgetRef ref;
  const _GuestCard({required this.guest, required this.isOwner, required this.eventId, required this.ref});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: guest.rsvpStatus.color.withOpacity(0.2)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: guest.rsvpStatus.color.withOpacity(0.15),
          child: Text(guest.name[0].toUpperCase(),
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
            color: guest.rsvpStatus.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: guest.rsvpStatus.color.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(guest.rsvpStatus.icon, color: guest.rsvpStatus.color, size: 12),
            const SizedBox(width: 4),
            Text(guest.rsvpStatus.label, style: TextStyle(color: guest.rsvpStatus.color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (isOwner) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(guestProvider(eventId).notifier).deleteGuest(guest.id!, eventId),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
          ),
        ],
      ]),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final TaskState taskState;
  final GuestState guestState;
  final int eventId;
  final bool isOwner;
  final UserModel? currentUser;
  final int? creatorId;
  final WidgetRef ref;
  final double budget;

  const _TasksTab({
    required this.taskState,
    required this.guestState,
    required this.eventId,
    required this.isOwner,
    required this.currentUser,
    required this.creatorId,
    required this.ref,
    required this.budget,
  });

  bool _canToggle(TaskModel task) {
    if (currentUser == null) return false;
    if (task.assignedToUserId != null && task.assignedToUserId == currentUser!.id) return true;
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
    final totalParticipants = nbGuests + 1;
    final budgetPerPerson = totalParticipants > 0 && budget > 0 ? budget / totalParticipants : 0.0;
    final tasksPerPerson  = total > 0 && nbGuests > 0 ? (total / (nbGuests + 1)).ceil() : total;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Row(children: [
              _DashIcon(icon: Icons.account_balance_wallet_outlined, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Budget par participant', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  budgetPerPerson > 0
                      ? '${budgetPerPerson.toStringAsFixed(0)} Ar  ×  $totalParticipants pers.'
                      : 'Budget non défini',
                  style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ])),
            ]),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),
            Row(children: [
              _DashIcon(icon: Icons.checklist_rounded, color: AppColors.secondaryLight),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  total > 0 ? '$total tâche(s) • $done terminée(s)' : 'Aucune tâche',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (total > 0 && nbGuests > 0)
                  Text('≈ $tasksPerPerson tâche(s) par participant',
                      style: const TextStyle(color: AppColors.secondaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
              ])),
            ]),
            if (total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: taskState.progressPercent,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ],
          ]),
        ),
      ),

      if (isOwner)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showAddTaskSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_task_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: taskState.isDistributing
                    ? null
                    : () async {
                        if (guestState.guests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("Invitez d'abord des participants."), backgroundColor: AppColors.warning));
                          return;
                        }
                        if (taskState.tasks.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Ajoutez des tâches à répartir.'), backgroundColor: AppColors.warning));
                          return;
                        }
                        if (currentUser == null) return;
                        final creator = currentUser!;
                        final msg = await ref.read(taskProvider(eventId).notifier).autoDistribute(
                          guests: guestState.guests,
                          creator: creator,
                          eventId: eventId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(msg), backgroundColor: AppColors.success, duration: const Duration(seconds: 3)));
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: taskState.isDistributing
                        ? Colors.white.withOpacity(0.04)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: taskState.isDistributing
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.secondaryLight.withOpacity(0.35),
                    ),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    taskState.isDistributing
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: AppColors.secondaryLight, strokeWidth: 2))
                        : const Icon(Icons.shuffle_rounded, color: AppColors.secondaryLight, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      taskState.isDistributing ? 'Répartition...' : 'Auto-répartir',
                      style: TextStyle(
                        color: taskState.isDistributing ? Colors.white38 : AppColors.secondaryLight,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),

      Expanded(
        child: taskState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
            : taskState.tasks.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.checklist_rtl_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    const Text('Aucune tâche', style: TextStyle(color: Colors.white38, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Ajoutez des tâches à accomplir', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: taskState.tasks.length,
                    itemBuilder: (ctx, i) {
                      final task = taskState.tasks[i];
                      final canToggle = _canToggle(task);
                      return _TaskCard(
                        task: task,
                        guests: guestState.guests,
                        eventId: eventId,
                        isOwner: isOwner,
                        canToggle: canToggle,
                        ref: ref,
                      );
                    },
                  ),
      ),
    ]);
  }

  void _showAddTaskSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nouvelle tâche', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          TextField(
            controller: ctrl, autofocus: true,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Description de la tâche',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.task_outlined, color: Colors.white38),
              filled: true, fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(30)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              onPressed: () async {
                await ref.read(taskProvider(eventId).notifier).addTask(ctrl.text, eventId);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DashIcon extends StatelessWidget {
  final IconData icon; final Color color;
  const _DashIcon({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: color, size: 18),
  );
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final List<GuestModel> guests;
  final int eventId;
  final bool isOwner;
  final bool canToggle;
  final WidgetRef ref;

  const _TaskCard({
    required this.task,
    required this.guests,
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isDone
              ? AppColors.success.withOpacity(0.25)
              : canToggle
                  ? AppColors.secondaryLight.withOpacity(0.3)
                  : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canToggle
              ? () => ref.read(taskProvider(eventId).notifier).toggleTask(task.id!, !task.isDone, eventId)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vous pouvez uniquement cocher vos propres tâches.'),
                    backgroundColor: AppColors.warning,
                    duration: Duration(seconds: 2),
                  ));
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isDone ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: task.isDone
                    ? AppColors.success
                    : canToggle
                        ? AppColors.secondaryLight
                        : Colors.white24,
                width: 2,
              ),
            ),
            child: task.isDone
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : canToggle
                    ? null
                    : const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 11),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              task.title,
              style: TextStyle(
                color: task.isDone ? Colors.white38 : AppColors.white,
                fontSize: 13,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white38,
              ),
            ),
            if (hasAssignee) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.person_pin_rounded, color: AppColors.secondaryLight, size: 12),
                const SizedBox(width: 4),
                Text(
                  task.assignedToName!,
                  style: const TextStyle(color: AppColors.secondaryLight, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ]),
            ] else ...[
              const SizedBox(height: 3),
              const Text('Non assigné', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ]),
        ),
        if (isOwner) ...[
          GestureDetector(
            onTap: () => _showAssignSheet(context),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: hasAssignee ? AppColors.secondaryLight.withOpacity(0.1) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: hasAssignee ? AppColors.secondaryLight : Colors.white38,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref.read(taskProvider(eventId).notifier).deleteTask(task.id!, eventId),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
          ),
        ],
      ]),
    );
  }

  void _showAssignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Assigner "${task.title}"',
              style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_off_outlined, color: Colors.white54),
            title: const Text('Non assigné', style: TextStyle(color: Colors.white70)),
            trailing: !task.hasAssignee ? const Icon(Icons.check_circle, color: AppColors.success, size: 18) : null,
            onTap: () {
              ref.read(taskProvider(eventId).notifier).unassign(task.id!, eventId);
              Navigator.pop(ctx);
            },
          ),
          Divider(color: Colors.white.withOpacity(0.08)),
          ...guests.map((g) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.3),
                  child: Text(g.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(g.name, style: const TextStyle(color: AppColors.white)),
                trailing: task.assignedToGuestId == g.id
                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 18) : null,
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

class _MyRsvpTab extends StatelessWidget {
  final int eventId; final int? currentUserId; final GuestState guestState; final WidgetRef ref;
  const _MyRsvpTab({required this.eventId, required this.currentUserId, required this.guestState, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) return const SizedBox();
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Votre réponse', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Indiquez si vous participez à cet événement', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: guest.rsvpStatus.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
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
        const Text('Changer ma réponse', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
                border: Border.all(color: isSelected ? status.color : Colors.white.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(status.icon, color: status.color, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(status.label,
                    style: TextStyle(color: isSelected ? status.color : Colors.white70,
                        fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                if (isSelected) Icon(Icons.check_circle_rounded, color: status.color, size: 20),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text; final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color ?? Colors.white54),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white60, fontSize: 13))),
  ]);
}

class _JourJTab extends StatelessWidget {
  final EventModel event;
  final TaskState taskState;
  final GuestState guestState;
  final WidgetRef ref;

  const _JourJTab({
    required this.event,
    required this.taskState,
    required this.guestState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isToday   = NotificationService.isToday(event.date);
    final daysLeft  = NotificationService.daysUntil(event.date);
    final isPast    = daysLeft < 0;
    final confirmedGuests = guestState.guests.where((g) => g.rsvpStatus == RsvpStatus.oui).length;
    final totalTasks = taskState.tasks.length;
    final doneTasks  = taskState.tasks.where((t) => t.isDone).length;
    final budgetPerPerson = guestState.guests.isNotEmpty
        ? event.budget / (guestState.guests.length + 1)
        : event.budget;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday
                    ? [AppColors.warning.withOpacity(0.25), AppColors.warning.withOpacity(0.1)]
                    : isPast
                        ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.03)]
                        : [AppColors.primary.withOpacity(0.25), AppColors.primary.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday
                    ? AppColors.warning.withOpacity(0.5)
                    : isPast
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.primaryLight.withOpacity(0.3),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: (isToday ? AppColors.warning : isPast ? Colors.white24 : AppColors.primaryLight).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isToday ? Icons.celebration_rounded : isPast ? Icons.event_busy_rounded : Icons.event_rounded,
                    color: isToday ? AppColors.warning : isPast ? Colors.white38 : AppColors.secondaryLight,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? "🎉 C'est aujourd'hui !" : isPast ? 'Événement passé' : 'Compte à rebours',
                        style: TextStyle(
                          color: isToday ? AppColors.warning : isPast ? Colors.white38 : AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isToday
                            ? event.date
                            : isPast
                                ? 'Il y a ${(-daysLeft)} jour${(-daysLeft) > 1 ? 's' : ''}'
                                : daysLeft == 1
                                    ? 'Demain !'
                                    : 'Dans $daysLeft jours',
                        style: TextStyle(
                          color: isToday ? AppColors.warning.withOpacity(0.8) : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Checklist de l\'événement',
            style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toutes les informations importantes en un coup d\'œil',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 14),

          _CheckItem(
            icon: Icons.title_rounded,
            label: 'Titre',
            value: event.title,
            isDone: event.title.isNotEmpty,
          ),
          _CheckItem(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: event.date,
            isDone: event.date.isNotEmpty,
          ),
          _CheckItem(
            icon: Icons.location_on_rounded,
            label: 'Lieu',
            value: event.location.isNotEmpty ? event.location : 'Non défini',
            isDone: event.location.isNotEmpty,
            onTap: event.location.isNotEmpty && event.hasCoordinates
                ? () => Navigator.pushNamed(context, '/map', arguments: {
                      'location': event.location,
                      'title': event.title,
                      'latitude': event.latitude,
                      'longitude': event.longitude,
                    })
                : null,
            actionIcon: event.location.isNotEmpty ? Icons.map_outlined : null,
          ),
          _CheckItem(
            icon: Icons.group_rounded,
            label: 'Participants confirmés',
            value: '$confirmedGuests confirmé(s) / ${guestState.guests.length} invité(s)',
            isDone: confirmedGuests > 0,
          ),
          _CheckItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Budget',
            value: event.budget > 0
                ? '${event.budget.toStringAsFixed(0)} Ar total · ${budgetPerPerson.toStringAsFixed(0)} Ar/pers.'
                : 'Non défini',
            isDone: event.budget > 0,
          ),
          _CheckItem(
            icon: Icons.task_alt_rounded,
            label: 'Tâches',
            value: totalTasks > 0
                ? '$doneTasks / $totalTasks terminée(s)'
                : 'Aucune tâche définie',
            isDone: totalTasks > 0 && doneTasks == totalTasks,
            isWarning: totalTasks > 0 && doneTasks < totalTasks,
          ),
          _CheckItem(
            icon: Icons.description_rounded,
            label: 'Description',
            value: (event.description != null && event.description!.isNotEmpty)
                ? event.description!
                : 'Non renseignée',
            isDone: event.description != null && event.description!.isNotEmpty,
            isOptional: true,
          ),

          const SizedBox(height: 20),

          if (totalTasks > 0) ...[
            const Text('Tâches du jour', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Avancement des tâches de l\'événement', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$doneTasks / $totalTasks tâches terminées',
                        style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${totalTasks > 0 ? (doneTasks / totalTasks * 100).toInt() : 0}%',
                        style: TextStyle(
                          color: doneTasks == totalTasks ? AppColors.success : AppColors.secondaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalTasks > 0 ? doneTasks / totalTasks : 0,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        doneTasks == totalTasks ? AppColors.success : AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...taskState.tasks.map((task) {
                    final assignee = task.assignedToName;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: task.isDone ? AppColors.success : Colors.transparent,
                              border: Border.all(
                                color: task.isDone ? AppColors.success : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: task.isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: task.isDone ? Colors.white38 : AppColors.white,
                                fontSize: 13,
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.white38,
                              ),
                            ),
                          ),
                          if (assignee != null && assignee.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                assignee,
                                style: const TextStyle(color: AppColors.secondaryLight, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          if (guestState.guests.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Présence', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Statut RSVP des participants', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
            ...guestState.guests.map((g) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: g.rsvpStatus.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: g.rsvpStatus.color.withOpacity(0.15),
                    child: Text(
                      g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                      style: TextStyle(color: g.rsvpStatus.color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(g.name, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: g.rsvpStatus.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: g.rsvpStatus.color.withOpacity(0.35)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(g.rsvpStatus.icon, color: g.rsvpStatus.color, size: 12),
                      const SizedBox(width: 4),
                      Text(g.rsvpStatus.label,
                          style: TextStyle(color: g.rsvpStatus.color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDone;
  final bool isWarning;
  final bool isOptional;
  final VoidCallback? onTap;
  final IconData? actionIcon;

  const _CheckItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDone,
    this.isWarning = false,
    this.isOptional = false,
    this.onTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isDone
        ? AppColors.success
        : isWarning
            ? AppColors.warning
            : isOptional
                ? Colors.white24
                : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.success.withOpacity(0.2)
                : isWarning
                    ? AppColors.warning.withOpacity(0.25)
                    : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: statusColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isDone ? AppColors.white : isWarning ? AppColors.warning : Colors.white38,
                      fontSize: 13,
                      fontWeight: isDone ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (actionIcon != null)
              Icon(actionIcon, color: AppColors.secondaryLight, size: 16)
            else
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : isWarning ? Icons.warning_amber_rounded : isOptional ? Icons.remove_rounded : Icons.close_rounded,
                  color: statusColor,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}