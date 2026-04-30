import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/event_model.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'tabs/send_emails_section.dart';

Widget buildEventHeader(BuildContext context, EventModel event, VoidCallback onShare) {
  final isOwner = event.creatorId == SessionService.currentUser?.id;
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
            overflow: TextOverflow.ellipsis),
        if (!isOwner)
          const Text('Vous êtes invité(e)', style: TextStyle(color: AppColors.warning, fontSize: 12)),
      ])),
      if (isOwner)
        IconButton(
          icon: const Icon(Icons.ios_share_rounded, color: AppColors.secondaryLight, size: 22),
          onPressed: onShare,
        ),
    ]),
  );
}

Widget buildInfoCard(BuildContext context, EventModel event, double budgetP, int totalP) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(child: Text(event.date, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        ]),
        if (event.location.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: event.hasCoordinates
                ? () => Navigator.pushNamed(context, AppRoutes.map, arguments: {
                      'location': event.location, 'title': event.title,
                      'latitude': event.latitude, 'longitude': event.longitude,
                    })
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: AppColors.error, size: 15),
                const SizedBox(width: 6),
                Expanded(child: Text(event.location,
                    style: const TextStyle(color: AppColors.error, fontSize: 13,
                        decoration: TextDecoration.underline, decorationColor: AppColors.error),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (event.hasCoordinates) const Icon(Icons.map_outlined, color: AppColors.error, size: 14),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondaryLight.withOpacity(0.18)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Budget total', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('${event.budget.toStringAsFixed(0)} Ar',
                  style: const TextStyle(color: AppColors.secondaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
            ])),
            Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
            Expanded(child: Padding(padding: const EdgeInsets.only(left: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Par confirmé (÷ $totalP)', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                Text(budgetP > 0 ? '${budgetP.toStringAsFixed(0)} Ar' : '— Ar',
                    style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
              ]))),
          ]),
        ),
        if (event.description?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Text(event.description!, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        ],
      ]),
    ),
  );
}

Widget buildTabBar(TabController tabs, EventModel event, WidgetRef ref) {
  final chatState = ref.watch(chatProvider(event.id!));
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: tabs,
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppColors.primaryGradient),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white, unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent, isScrollable: false,
        tabs: [
          const Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Invités'),
          const Tab(icon: Icon(Icons.task_alt_rounded, size: 20), text: 'Tâches'),
          const Tab(icon: Icon(Icons.how_to_vote_rounded, size: 20), text: 'RSVP'),
          Tab(icon: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            const Icon(Icons.alarm_rounded, size: 20),
            if (NotificationService.isToday(event.date))
              Positioned(top: -2, right: -4, child: Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle))),
          ]), text: 'Jour J'),
          Tab(icon: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            if (chatState.messages.isNotEmpty)
              Positioned(top: -4, right: -6, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('${chatState.messages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
          ]), text: 'Chat'),
        ],
      ),
    ),
  );
}

void showShareSheet(BuildContext context, EventModel event) {
  final link = 'groupevent://invite/${event.inviteCode ?? event.id}';
  showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Partager le lien',
            style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Ce lien permet aux invités d'accéder à l'événement après connexion.",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.link_rounded, color: AppColors.secondaryLight, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(link, style: const TextStyle(color: Colors.white70, fontSize: 13))),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Lien copié !'), backgroundColor: AppColors.success,
                    duration: Duration(seconds: 2)));
              },
              child: const Icon(Icons.copy_rounded, color: AppColors.secondaryLight, size: 20)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Envoyer par email',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        SendEmailsSection(event: event, link: link),
      ]),
    ),
  );
}
