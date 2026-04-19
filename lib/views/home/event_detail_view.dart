import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/session_service.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../../viewmodels/guest_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'event_detail_builders.dart';
import 'tabs/guests_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/rsvp_tab.dart';
import 'tabs/jourj_tab.dart';
import 'tabs/chat_tab.dart';

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
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final eventId     = ModalRoute.of(context)!.settings.arguments as int;
    final eventState  = ref.watch(eventProvider);
    final currentUser = SessionService.currentUser;

    EventModel? event;
    try { event = eventState.myEvents.firstWhere((e) => e.id == eventId); }
    catch (_) {
      try { event = eventState.invitedEvents.firstWhere((e) => e.id == eventId); }
      catch (_) { event = null; }
    }

    if (event == null) {
      return Scaffold(body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))));
    }

    final guestState = ref.watch(guestProvider(eventId));
    final taskState  = ref.watch(taskProvider(eventId));
    final chatState  = ref.watch(chatProvider(eventId));
    final totalP     = guestState.guests.length + 1;
    final budgetP    = totalP > 0 && event.budget > 0 ? event.budget / totalP : 0.0;
    final localEvent = event;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            buildEventHeader(context, localEvent, () => showShareSheet(context, localEvent)),
            buildInfoCard(context, localEvent, budgetP, totalP),
            const SizedBox(height: 10),
            buildTabBar(_tabs, localEvent, ref),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(controller: _tabs, children: [
                GuestsTab(
                  guestState: guestState, eventId: eventId,
                  isOwner: localEvent.creatorId == currentUser?.id, ref: ref,
                ),
                TasksTab(
                  taskState: taskState, guestState: guestState, eventId: eventId,
                  isOwner: localEvent.creatorId == currentUser?.id,
                  currentUser: currentUser, ref: ref, budget: localEvent.budget,
                ),
                RsvpTab(
                  eventId: eventId, currentUserId: currentUser?.id,
                  guestState: guestState, ref: ref,
                ),
                JourJTab(
                  event: localEvent, taskState: taskState,
                  guestState: guestState, ref: ref,
                ),
                ChatTab(
                  chatState: chatState, eventId: eventId,
                  currentUser: currentUser, ref: ref,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
