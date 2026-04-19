import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event_model.dart';
import '../../../viewmodels/guest_viewmodel.dart';

class SendEmailsSection extends ConsumerWidget {
  final EventModel event;
  final String link;

  const SendEmailsSection({super.key, required this.event, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestState = ref.watch(guestProvider(event.id!));
    final withEmail  = guestState.guests.where((g) => g.email?.isNotEmpty == true).toList();

    if (withEmail.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Ajoutez des invités avec email pour leur envoyer le lien.",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Column(children: [
      ...withEmail.map((g) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.3),
            child: Text(
              g.name[0].toUpperCase(),
              style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.name, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(g.email!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          GestureDetector(
            onTap: () => _sendEmail(context, g.email!, g.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Envoyer',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
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
        onPressed: () {
          for (final g in withEmail) {
            _sendEmail(context, g.email!, g.name);
          }
        },
      ),
    ]);
  }

  Future<void> _sendEmail(BuildContext context, String email, String name) async {
    final subject = Uri.encodeComponent('Invitation – ${event.title}');
    final body    = Uri.encodeComponent(
      'Bonjour $name,\n\nVous êtes invité(e) à "${event.title}" sur GroupEvent.\n\n'
      '📅 ${event.date}\n📍 ${event.location.isNotEmpty ? event.location : "Non précisé"}\n\n'
      'Lien : $link\n\nÀ bientôt !',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Impossible d'ouvrir le client email."),
        backgroundColor: AppColors.error,
      ));
    }
  }
}
