import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DirectionsService {
  static String get _accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN']!;

  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mapbox.com/directions/v5/mapbox/walking/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$_accessToken',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
        }
      }

      // Fallback to direct line if no route found
      return [start, end];
    } catch (e) {
      // Fallback to direct line on error
      return [start, end];
    }
  }
}
