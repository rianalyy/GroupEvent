import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/session_service.dart';
import '../../models/event_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(eventProvider);
    final user = SessionService.currentUser;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Mes événements',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.welcome,
                              (route) => false,
                            );
                          }
                        }
                      },
                      color: const Color(0xFF3A0860),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: AppColors.error, size: 18),
                              SizedBox(width: 10),
                              Text('Se déconnecter',
                                  style:
                                      TextStyle(color: AppColors.white)),
                            ],
                          ),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.glassWhite,
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: eventState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.secondaryLight),
                      )
                    : eventState.events.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 72,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucun événement pour le moment',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Appuyez sur + pour créer votre premier événement',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: eventState.events.length,
                            itemBuilder: (context, index) {
                              return _EventCard(
                                event: eventState.events[index],
                                ref: ref,
                              );
                            },
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
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateEventSheet(context, ref),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child:
              const Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final participantsCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D0550),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nouvel événement',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _SheetField(
                    controller: titleCtrl,
                    hint: "Titre de l'événement *",
                    icon: Icons.celebration_rounded),
                const SizedBox(height: 14),

                _SheetField(
                    controller: dateCtrl,
                    hint: 'Date (ex: 20 Avril 2025) *',
                    icon: Icons.calendar_today_rounded),
                const SizedBox(height: 14),

                _SheetField(
                    controller: locationCtrl,
                    hint: 'Lieu',
                    icon: Icons.location_on_outlined),
                const SizedBox(height: 14),

                _SheetField(
                    controller: participantsCtrl,
                    hint: 'Nombre de participants',
                    icon: Icons.group_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),

                _SheetField(
                    controller: budgetCtrl,
                    hint: 'Budget total (en Ar)',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),

                const Text(
                  'Description',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descriptionCtrl,
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 14),
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Décrivez votre événement (thème, programme, infos pratiques…)',
                    hintStyle: const TextStyle(
                        color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.secondaryLight, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final date = dateCtrl.text.trim();
                      if (title.isEmpty || date.isEmpty) return;

                      final currentUser = SessionService.currentUser;
                      await ref.read(eventProvider.notifier).addEvent(
                            EventModel(
                              title: title,
                              date: date,
                              location: locationCtrl.text.trim(),
                              participants:
                                  int.tryParse(participantsCtrl.text) ??
                                      1,
                              budget:
                                  double.tryParse(budgetCtrl.text) ?? 0,
                              description: descriptionCtrl.text.trim(),
                              creatorId: currentUser?.id,
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      "Créer l'événement",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final WidgetRef ref;

  const _EventCard({required this.event, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (event.id != null) {
                    await ref
                        .read(eventProvider.notifier)
                        .deleteEvent(event.id!);
                  }
                },
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white30, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _InfoRow(
              icon: Icons.calendar_today_rounded, text: event.date),

          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.location_on_outlined, text: event.location),
          ],

          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.group_outlined,
            text:
                '${event.participants} participant${event.participants > 1 ? 's' : ''}',
          ),

          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            text: '${event.budget.toStringAsFixed(0)} Ar',
            color: AppColors.secondaryLight,
          ),

          if (event.description != null &&
              event.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.description!,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 13, height: 1.4),
              ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color ?? Colors.white54),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color ?? Colors.white60, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SheetField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.secondaryLight, width: 1.5),
        ),
      ),
    );
  }
}
