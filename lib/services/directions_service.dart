import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class DirectionsService {
  static const String _accessToken = 'pk.eyJ1Ijoic2hhcmVubGFuZ2dhIiwiYSI6ImNtYWtnczExNTE5ZDEyaW9wdTV0N3VhcXkifQ.Q0YFI9A6P6yJf01p0XbLCw';

  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final String url = 'https://api.mapbox.com/directions/v5/mapbox/walking/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?geometries=geojson&access_token=$_accessToken&overview=full';

    try {
      if (kDebugMode) {
        print('Fetching route from: ${start.latitude},${start.longitude} to: ${end.latitude},${end.longitude}');
      }

      final response = await http.get(Uri.parse(url));
      
      if (kDebugMode) {
        print('Mapbox API Response Status: ${response.statusCode}');
        print('Mapbox API Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          
          if (kDebugMode) {
            print('Route points count: ${coordinates.length}');
          }

          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        } else {
          if (kDebugMode) {
            print('No routes found in response');
          }
        }
      } else {
        if (kDebugMode) {
          print('Error response from Mapbox: ${response.body}');
        }
      }

      // Fallback to direct line if API fails
      if (kDebugMode) {
        print('Falling back to direct line');
      }
      return [start, end];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting route: $e');
      }
      return [start, end];
    }
  }
} 