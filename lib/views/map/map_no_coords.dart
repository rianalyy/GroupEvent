import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MapNoCoordsView extends StatelessWidget {
  final String title;
  final String location;
  final VoidCallback onOpenBrowser;
  const MapNoCoordsView({super.key, required this.title, required this.location, required this.onOpenBrowser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(child: Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.wrong_location_rounded, size: 80, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 20),
                const Text('Coordonnées non disponibles',
                    style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  location.isNotEmpty
                      ? 'Le lieu "$location" n\'a pas pu être localisé lors de la création.\n\nRecréez l\'événement avec une adresse plus précise.'
                      : 'Aucun lieu n\'a été défini pour cet événement.',
                  style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onOpenBrowser,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
                        Text('Rechercher dans le navigateur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ]),
            ))),
          ]),
        ),
      ),
    );
  }
}
