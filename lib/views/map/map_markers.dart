import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

List<Marker> buildMapMarkers({LatLng? user, required LatLng event, required String title}) {
  return [
    if (user != null)
      Marker(
        point: user, width: 44, height: 44,
        child: Container(
          decoration: BoxDecoration(color: AppColors.info, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: AppColors.info.withOpacity(0.5), blurRadius: 10)]),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20)),
      ),
    Marker(
      point: event, width: 90, height: 80,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8)]),
          child: Text(title.length > 12 ? '${title.substring(0, 12)}…' : title,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
        CustomPaint(size: const Size(12, 6), painter: _TrianglePainter(color: AppColors.primary)),
        Container(width: 38, height: 38,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)]),
          child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 20)),
      ]),
    ),
  ];
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width / 2, size.height); path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

class MapActionBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const MapActionBtn({super.key, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: AppColors.background.withOpacity(0.9), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]),
      child: Icon(icon, size: 20, color: Colors.white)),
  );
}
