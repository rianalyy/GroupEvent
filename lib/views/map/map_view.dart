import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  LatLng? _userPosition;
  LatLng? _eventPosition;
  String  _eventLocation = '';
  String  _eventTitle    = '';

  bool _isLoading  = true;
  double _distanceKm = 0;

  bool get _isLinux => Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _eventLocation = args['location'] as String? ?? '';
      _eventTitle    = args['title']    as String? ?? '';
      final lat = args['latitude']  as double?;
      final lng = args['longitude'] as double?;

      if (lat != null && lng != null) {
        _eventPosition = LatLng(lat, lng);
      }
      _initMap();
    });
  }

  Future<void> _initMap() async {
    setState(() => _isLoading = true);

    if (!_isLinux && _eventPosition != null) {
      final userPos = await _getUserLocation();
      if (userPos != null) {
        final distMeters = const Distance().as(LengthUnit.Meter, userPos, _eventPosition!);
        _distanceKm = distMeters / 1000;
        setState(() => _userPosition = userPos);
      }
    }

    setState(() => _isLoading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_eventPosition != null) {
        _mapController.move(_eventPosition!, 15);
      }
    });
  }

  Future<LatLng?> _getUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void _openInBrowser() async {
    Uri uri;
    if (_eventPosition != null) {
      final lat = _eventPosition!.latitude;
      final lng = _eventPosition!.longitude;
      uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng');
    } else {
      uri = Uri.parse('https://www.openstreetmap.org/search?query=${Uri.encodeComponent(_eventLocation)}');
    }
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight)),
            )
          : _eventPosition == null
              ? _buildNoCoords()
              : _buildMap(),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _eventPosition!,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.groupevent.app',
              maxZoom: 19,
            ),

            if (_userPosition != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_userPosition!, _eventPosition!],
                    strokeWidth: 3,
                    color: AppColors.primaryLight.withOpacity(0.85),
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (_userPosition != null)
                  Marker(
                    point: _userPosition!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.info.withOpacity(0.5), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                Marker(
                  point: _eventPosition!,
                  width: 80,
                  height: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 8)],
                        ),
                        child: Text(
                          _eventTitle.length > 12 ? '${_eventTitle.substring(0, 12)}…' : _eventTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(12, 6),
                        painter: _TrianglePainter(color: AppColors.primary),
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _MapBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                const Spacer(),
                _MapBtn(icon: Icons.open_in_new_rounded, onTap: _openInBrowser),
              ],
            ),
          ),
        ),

        Positioned(
          right: 16,
          bottom: 210,
          child: Column(children: [
            _MapBtn(
              icon: Icons.add,
              onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            ),
            const SizedBox(height: 8),
            _MapBtn(
              icon: Icons.remove,
              onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            ),
          ]),
        ),

        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D0550),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.error, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_eventTitle,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(_eventLocation,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      if (_distanceKm > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: Text(
                            _distanceKm < 1
                                ? '${(_distanceKm * 1000).toInt()} m'
                                : '${_distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openInBrowser,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.directions_outlined, color: AppColors.secondaryLight, size: 16),
                            SizedBox(width: 6),
                            Text('Itinéraire', style: TextStyle(color: AppColors.secondaryLight, fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_eventPosition != null) _mapController.move(_eventPosition!, 15);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6)],
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Centrer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCoords() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(_eventTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.wrong_location_rounded, size: 80, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 20),
                    const Text('Coordonnées non disponibles',
                        style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      _eventLocation.isNotEmpty
                          ? 'Le lieu "$_eventLocation" n\'a pas pu être localisé lors de la création.\n\nRecréez l\'événement avec une adresse plus précise.'
                          : 'Aucun lieu n\'a été défini pour cet événement.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    if (_eventLocation.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _openInBrowser,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Rechercher dans le navigateur',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2D0550).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    ),
  );
}
