import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/event_model.dart';
import '../../../services/session_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../viewmodels/event_viewmodel.dart';

Future<(double?, double?)> geocodeLocation(String address) =>
    GeocodingService.geocode(address);

void showCreateEventSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl        = TextEditingController();
  final locationCtrl     = TextEditingController();
  final participantsCtrl = TextEditingController();
  final budgetCtrl       = TextEditingController();
  final descriptionCtrl  = TextEditingController();
  final taskCtrl         = TextEditingController();
  final taskTitles       = <String>[];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final dateLabel = selectedDate != null
            ? DateFormat('EEE d MMM yyyy', 'fr_FR').format(selectedDate!)
            : 'Choisir une date *';
        final timeLabel = selectedTime != null
            ? '${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}'
            : 'Heure';

        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Text('Nouvel événement', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 20),
            _SheetField(controller: titleCtrl, hint: "Titre de l'événement *", icon: Icons.celebration_rounded),
            const SizedBox(height: 12),
            const Text('Date & Heure *', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(flex: 3, child: _DateBtn(label: dateLabel, hasValue: selectedDate != null, onTap: () async {
                final p = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)),
                    builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(
                        primary: AppColors.primaryLight, onPrimary: Colors.white, surface: AppColors.primaryDark, onSurface: Colors.white),
                        dialogBackgroundColor: AppColors.background), child: child!));
                if (p != null) set(() => selectedDate = p);
              })),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _DateBtn(label: timeLabel, hasValue: selectedTime != null, icon: Icons.access_time_rounded, onTap: () async {
                final p = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 18, minute: 0),
                    builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(
                        primary: AppColors.primaryLight, onPrimary: Colors.white, surface: AppColors.primaryDark, onSurface: Colors.white),
                        dialogBackgroundColor: AppColors.background), child: child!));
                if (p != null) set(() => selectedTime = p);
              })),
            ]),
            const SizedBox(height: 12),
            _SheetField(controller: locationCtrl, hint: 'Lieu (adresse ou nom)', icon: Icons.location_on_outlined),
            const SizedBox(height: 4),
            const Text('  La position sera localisée automatiquement', style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            _SheetField(controller: participantsCtrl, hint: 'Nombre de participants', icon: Icons.group_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _SheetField(controller: budgetCtrl, hint: 'Budget total (en Ar)', icon: Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: descriptionCtrl, style: const TextStyle(color: AppColors.white, fontSize: 14), maxLines: 2, minLines: 2,
                decoration: _deco('Description (optionnel)', Icons.description_outlined)),
            const SizedBox(height: 20),
            const Text('Tâches à faire', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Ajoutez les tâches à répartir', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: taskCtrl, style: const TextStyle(color: AppColors.white, fontSize: 14),
                  decoration: _deco('Nouvelle tâche', Icons.check_circle_outline_rounded))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { final t = taskCtrl.text.trim(); if (t.isNotEmpty) set(() { taskTitles.add(t); taskCtrl.clear(); }); },
                child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add, color: Colors.white, size: 22))),
            ]),
            if (taskTitles.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...taskTitles.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.drag_handle_rounded, color: Colors.white38, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  GestureDetector(onTap: () => set(() => taskTitles.removeAt(e.key)), child: const Icon(Icons.close, color: Colors.white30, size: 18)),
                ]),
              )),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  if (selectedDate == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Veuillez choisir une date.'), backgroundColor: AppColors.error)); return; }
                  final h = selectedTime?.hour ?? 18; final m = selectedTime?.minute ?? 0;
                  final dt = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, h, m);
                  final dateStr = DateFormat('EEE d MMM yyyy · HH:mm', 'fr_FR').format(dt);
                  final location = locationCtrl.text.trim();
                  double? lat, lng;
                  if (location.isNotEmpty) { final c = await geocodeLocation(location); lat = c.$1; lng = c.$2; }
                  final user = SessionService.currentUser;
                  await ref.read(eventProvider.notifier).addEvent(
                    EventModel(title: title, date: dateStr, location: location, latitude: lat, longitude: lng,
                        participants: int.tryParse(participantsCtrl.text) ?? 1, budget: double.tryParse(budgetCtrl.text) ?? 0,
                        description: descriptionCtrl.text.trim(), creatorId: user?.id),
                    taskTitles,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text("Créer l'événement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
              ),
            ),
          ])),
        );
      },
    ),
  );
}

InputDecoration _deco(String hint, IconData icon) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
  prefixIcon: Icon(icon, color: Colors.white38, size: 18), filled: true, fillColor: Colors.white.withOpacity(0.08),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
);

class _SheetField extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon; final TextInputType? keyboardType;
  const _SheetField({required this.controller, required this.hint, required this.icon, this.keyboardType});
  @override
  Widget build(BuildContext context) => TextField(controller: controller, style: const TextStyle(color: AppColors.white, fontSize: 14), keyboardType: keyboardType, decoration: _deco(hint, icon));
}

class _DateBtn extends StatelessWidget {
  final String label; final bool hasValue; final VoidCallback onTap; final IconData icon;
  const _DateBtn({required this.label, required this.hasValue, required this.onTap, this.icon = Icons.calendar_today_rounded});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(hasValue ? 0.12 : 0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasValue ? AppColors.secondaryLight.withOpacity(0.6) : Colors.transparent, width: 1.5)),
      child: Row(children: [
        Icon(icon, size: 16, color: hasValue ? AppColors.secondaryLight : Colors.white38),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: hasValue ? AppColors.white : Colors.white38, fontSize: 13, fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}
