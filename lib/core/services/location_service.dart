import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String?> getWardFromLocation(double lat, double lng) async {
    try {
      final String response = await rootBundle.loadString('assets/data/wards.json');
      final List<dynamic> wards = json.decode(response);

      for (var ward in wards) {
        final List<dynamic> polygon = ward['polygon'];
        if (_isPointInPolygon(lng, lat, polygon)) {
          return ward['ward'].toString();
        }
      }
    } catch (e) {
      print("Error detecting ward: $e");
    }
    return null;
  }

  static bool _isPointInPolygon(double lng, double lat, List<dynamic> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      double xi = polygon[i][0].toDouble();
      double yi = polygon[i][1].toDouble();
      double xj = polygon[j][0].toDouble();
      double yj = polygon[j][1].toDouble();

      bool intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}
