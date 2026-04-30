import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/session_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'tabs/home_cards.dart';
import 'tabs/home_sheet.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});
  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
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
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final user = SessionService.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bonjour, ${user?.name ?? 'vous'} 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 2),
                  const Text('GroupEvent', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ])),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'logout') {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (r) => false);
                    }
                  },
                  color: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (_) => [const PopupMenuItem(value: 'logout', child: Row(children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 18), SizedBox(width: 10),
                    Text('Se déconnecter', style: TextStyle(color: AppColors.white)),
                  ]))],
                  child: CircleAvatar(
                    radius: 22, backgroundColor: AppColors.glassWhite,
                    child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppColors.primaryGradient),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white, unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.event_rounded, size: 16), const SizedBox(width: 6),
                      const Flexible(child: Text('Mes événements', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      if (eventState.myEvents.isNotEmpty) ...[const SizedBox(width: 6), HomeBadge(count: eventState.myEvents.length)],
                    ])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.mail_rounded, size: 16), const SizedBox(width: 6),
                      const Flexible(child: Text('Invitations', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      if (eventState.invitedEvents.isNotEmpty) ...[const SizedBox(width: 6), HomeBadge(count: eventState.invitedEvents.length, color: AppColors.warning)],
                    ])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: eventState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
                  : TabBarView(controller: _tabController, children: [
                      MyEventsTab(events: eventState.myEvents, ref: ref),
                      InvitedEventsTab(events: eventState.invitedEvents),
                    ]),
            ),
          ]),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]),
        child: FloatingActionButton(
          onPressed: () => showCreateEventSheet(context, ref),
          backgroundColor: Colors.transparent, elevation: 0,
          child: const Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
    );
  }
}
