import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  GeocodingService._();

  static Future<(double?, double?)> geocode(String address) async {
    if (address.trim().isEmpty) return (null, null);

    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      try {
        final locations = await locationFromAddress(address.trim());
        if (locations.isNotEmpty) {
          return (locations.first.latitude, locations.first.longitude);
        }
      } catch (_) {}
    }

    return await _nominatim(address.trim());
  }

  static Future<(double?, double?)> _nominatim(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'GroupEvent/1.0 (Flutter App)',
        'Accept-Language': 'fr',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return (null, null);
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return (null, null);

      final lat = double.tryParse(data[0]['lat'] as String);
      final lng = double.tryParse(data[0]['lon'] as String);
      return (lat, lng);
    } catch (_) {
      return (null, null);
    }
  }
}
