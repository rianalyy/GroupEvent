import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import 'map_markers.dart';
import 'map_no_coords.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});
  @override State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _userPosition;
  LatLng? _eventPosition;
  String _eventLocation = '';
  String _eventTitle = '';
  bool _isLoading = true;
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
      if (lat != null && lng != null) _eventPosition = LatLng(lat, lng);
      _initMap();
    });
  }

  Future<void> _initMap() async {
    setState(() => _isLoading = true);
    if (!_isLinux && _eventPosition != null) {
      final pos = await _getUserLocation();
      if (pos != null) {
        final m = const Distance().as(LengthUnit.Meter, pos, _eventPosition!);
        _distanceKm = m / 1000;
        setState(() => _userPosition = pos);
      }
    }
    setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_eventPosition != null) _mapController.move(_eventPosition!, 15);
    });
  }

  Future<LatLng?> _getUserLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) { return null; }
  }

  void _openInBrowser() async {
    final uri = _eventPosition != null
        ? Uri.parse('https://www.openstreetmap.org/?mlat=${_eventPosition!.latitude}&mlon=${_eventPosition!.longitude}#map=16/${_eventPosition!.latitude}/${_eventPosition!.longitude}')
        : Uri.parse('https://www.openstreetmap.org/search?query=${Uri.encodeComponent(_eventLocation)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Container(decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))));
    }
    if (_eventPosition == null) {
      return MapNoCoordsView(title: _eventTitle, location: _eventLocation, onOpenBrowser: _openInBrowser);
    }
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _eventPosition!, initialZoom: 15, minZoom: 3, maxZoom: 19),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.groupevent.app', maxZoom: 19),
            if (_userPosition != null && _eventPosition != null)
              PolylineLayer(polylines: [Polyline(points: [_userPosition!, _eventPosition!], strokeWidth: 3,
                  color: AppColors.primaryLight.withOpacity(0.85), pattern: const StrokePattern.dotted())]),
            MarkerLayer(markers: buildMapMarkers(user: _userPosition, event: _eventPosition!, title: _eventTitle)),
          ],
        ),
        SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          MapActionBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
          const Spacer(),
          MapActionBtn(icon: Icons.open_in_new_rounded, onTap: _openInBrowser),
        ]))),
        Positioned(right: 16, bottom: 210, child: Column(children: [
          MapActionBtn(icon: Icons.add, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
          const SizedBox(height: 8),
          MapActionBtn(icon: Icons.remove, onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
        ])),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomCard()),
      ]),
    );
  }

  Widget _buildBottomCard() {
    return SafeArea(child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2D0550), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on_rounded, color: AppColors.error, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_eventTitle, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_eventLocation, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          if (_distanceKm > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withOpacity(0.3))),
            child: Text(_distanceKm < 1 ? '${(_distanceKm * 1000).toInt()} m' : '${_distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GestureDetector(onTap: _openInBrowser, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.directions_outlined, color: AppColors.secondaryLight, size: 16), SizedBox(width: 6),
              Text('Itinéraire', style: TextStyle(color: AppColors.secondaryLight, fontSize: 13, fontWeight: FontWeight.w500)),
            ])))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(onTap: () => _mapController.move(_eventPosition!, 15), child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6)]),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.my_location_rounded, color: Colors.white, size: 16), SizedBox(width: 6),
              Text('Centrer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ])))),
        ]),
      ]),
    ));
  }
}
