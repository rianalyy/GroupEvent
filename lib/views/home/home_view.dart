import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/session_service.dart';
import '../../services/geocoding_service.dart';
import '../../models/event_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventProvider.notifier).loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final user = SessionService.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${user?.name ?? 'vous'} 👋',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'GroupEvent',
                            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await ref.read(authProvider.notifier).logout();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (r) => false);
                          }
                        }
                      },
                      color: const Color(0xFF3A0860),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(children: [
                            Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                            SizedBox(width: 10),
                            Text('Se déconnecter', style: TextStyle(color: AppColors.white)),
                          ]),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.glassWhite,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: AppColors.primaryGradient,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.event_rounded, size: 16),
                          const SizedBox(width: 6),
                          const Text('Mes événements'),
                          if (eventState.myEvents.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _Badge(count: eventState.myEvents.length),
                          ],
                        ]),
                      ),
                      Tab(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.mail_rounded, size: 16),
                          const SizedBox(width: 6),
                          const Text('Invitations'),
                          if (eventState.invitedEvents.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _Badge(count: eventState.invitedEvents.length, color: AppColors.warning),
                          ],
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: eventState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _MyEventsTab(events: eventState.myEvents, ref: ref),
                          _InvitedEventsTab(events: eventState.invitedEvents),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateEventSheet(context, ref),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  final List<EventModel> events;
  final WidgetRef ref;
  const _MyEventsTab({required this.events, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_note_rounded, size: 72, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Aucun événement créé', style: TextStyle(color: Colors.white38, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Appuyez sur + pour créer votre premier événement',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: events[i].id),
        child: _EventCard(event: events[i], isOwner: true, ref: ref),
      ),
    );
  }
}

class _InvitedEventsTab extends StatelessWidget {
  final List<EventModel> events;
  const _InvitedEventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mail_outline_rounded, size: 72, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Aucune invitation reçue', style: TextStyle(color: Colors.white38, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Les événements auxquels vous êtes invité apparaîtront ici',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: events[i].id),
        child: _EventCard(event: events[i], isOwner: false, ref: null),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final WidgetRef? ref;
  const _EventCard({required this.event, required this.isOwner, this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOwner ? Colors.white.withOpacity(0.12) : AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isOwner)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: const Text('Invité', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: Text(event.title, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              if (isOwner && ref != null)
                GestureDetector(
                  onTap: () async {
                    if (event.id != null) await ref!.read(eventProvider.notifier).deleteEvent(event.id!);
                  },
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.calendar_today_rounded, text: event.date),
          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.location_on_outlined, text: event.location),
          ],
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.group_outlined,
              text: '${event.participants} participant${event.participants > 1 ? 's' : ''}'),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.account_balance_wallet_outlined,
              text: '${event.budget.toStringAsFixed(0)} Ar', color: AppColors.secondaryLight),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Text(event.description!, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color ?? Colors.white54),
    const SizedBox(width: 7),
    Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white60, fontSize: 13))),
  ]);
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, this.color = AppColors.secondaryLight});

  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(color: color.withOpacity(0.25), shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5))),
    child: Center(child: Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
  );
}

Future<(double?, double?)> _geocodeLocation(String address) =>
    GeocodingService.geocode(address);

void _showCreateEventSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl       = TextEditingController();
  final locationCtrl    = TextEditingController();
  final participantsCtrl = TextEditingController();
  final budgetCtrl      = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final taskCtrl        = TextEditingController();
  final taskTitles      = <String>[];

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2D0550),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        String dateLabel = 'Choisir une date *';
        if (selectedDate != null) {
          dateLabel = DateFormat('EEE d MMM yyyy', 'fr_FR').format(selectedDate!);
        }
        String timeLabel = 'Heure';
        if (selectedTime != null) {
          final h = selectedTime!.hour.toString().padLeft(2, '0');
          final m = selectedTime!.minute.toString().padLeft(2, '0');
          timeLabel = '$h:$m';
        }

        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Nouvel événement',
                        style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _SheetField(controller: titleCtrl, hint: "Titre de l'événement *", icon: Icons.celebration_rounded),
                const SizedBox(height: 12),

                const Text('Date & Heure *',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                            builder: (c, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primaryLight,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF3A0860),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF2D0550),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(selectedDate != null ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedDate != null
                                  ? AppColors.secondaryLight.withOpacity(0.6)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 16,
                                  color: selectedDate != null ? AppColors.secondaryLight : Colors.white38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(dateLabel,
                                    style: TextStyle(
                                      color: selectedDate != null ? AppColors.white : Colors.white38,
                                      fontSize: 13,
                                      fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 18, minute: 0),
                            builder: (c, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primaryLight,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF3A0860),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF2D0550),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => selectedTime = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(selectedTime != null ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedTime != null
                                  ? AppColors.secondaryLight.withOpacity(0.6)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 16,
                                  color: selectedTime != null ? AppColors.secondaryLight : Colors.white38),
                              const SizedBox(width: 6),
                              Text(timeLabel,
                                  style: TextStyle(
                                    color: selectedTime != null ? AppColors.white : Colors.white38,
                                    fontSize: 13,
                                    fontWeight: selectedTime != null ? FontWeight.w500 : FontWeight.normal,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _SheetField(controller: locationCtrl, hint: 'Lieu (adresse ou nom du lieu)', icon: Icons.location_on_outlined),
                const SizedBox(height: 6),
                const Text(
                  '  La position sera localisée automatiquement sur la carte',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),

                _SheetField(controller: participantsCtrl, hint: 'Nombre de participants',
                    icon: Icons.group_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                _SheetField(controller: budgetCtrl, hint: 'Budget total (en Ar)',
                    icon: Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                TextField(
                  controller: descriptionCtrl,
                  style: const TextStyle(color: AppColors.white, fontSize: 14),
                  maxLines: 2, minLines: 2,
                  decoration: _sheetInputDeco('Description (optionnel)', Icons.description_outlined),
                ),
                const SizedBox(height: 20),

                const Text('Tâches à faire',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Ajoutez les tâches à répartir entre les participants',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: taskCtrl,
                        style: const TextStyle(color: AppColors.white, fontSize: 14),
                        decoration: _sheetInputDeco('Nouvelle tâche', Icons.check_circle_outline_rounded),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final t = taskCtrl.text.trim();
                        if (t.isNotEmpty) setModalState(() { taskTitles.add(t); taskCtrl.clear(); });
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                if (taskTitles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...taskTitles.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                      GestureDetector(
                        onTap: () => setModalState(() => taskTitles.removeAt(e.key)),
                        child: const Icon(Icons.close, color: Colors.white30, size: 18),
                      ),
                    ]),
                  )),
                ],

                const SizedBox(height: 24),

                Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Le titre est obligatoire.'), backgroundColor: AppColors.error));
                        return;
                      }
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Veuillez choisir une date.'), backgroundColor: AppColors.error));
                        return;
                      }

                      final h = selectedTime?.hour ?? 18;
                      final m = selectedTime?.minute ?? 0;
                      final dt = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, h, m);
                      final dateStr = DateFormat('EEE d MMM yyyy · HH:mm', 'fr_FR').format(dt);

                      double? lat, lng;
                      final location = locationCtrl.text.trim();
                      if (location.isNotEmpty) {
                        final coords = await _geocodeLocation(location);
                        lat = coords.$1;
                        lng = coords.$2;
                      }

                      final user = SessionService.currentUser;
                      await ref.read(eventProvider.notifier).addEvent(
                        EventModel(
                          title: title,
                          date: dateStr,
                          location: location,
                          latitude: lat,
                          longitude: lng,
                          participants: int.tryParse(participantsCtrl.text) ?? 1,
                          budget: double.tryParse(budgetCtrl.text) ?? 0,
                          description: descriptionCtrl.text.trim(),
                          creatorId: user?.id,
                        ),
                        taskTitles,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Créer l'événement",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

InputDecoration _sheetInputDeco(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5),
    ),
  );
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  const _SheetField({required this.controller, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(color: AppColors.white, fontSize: 14),
    keyboardType: keyboardType,
    decoration: _sheetInputDeco(hint, icon),
  );
}
