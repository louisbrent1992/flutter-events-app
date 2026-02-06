import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Service for Google Maps Platform APIs with server-side caching.
///
/// Strategy:
/// 1. Query server cache first (Firestore-backed, near-zero cost)
/// 2. Fallback to direct Google API only if server unavailable
/// 3. Directions use URL scheme (always free)
///
/// This approach minimizes Google Maps API costs by:
/// - Server caches autocomplete results for 24 hours
/// - Server caches place details for 7 days
/// - Cron job pre-populates popular venues from events
class GoogleMapsService {
  // Fallback API key for direct calls (only used if server unavailable)
  static const String _apiKey = 'AIzaSyDi2u-wZqvEUNKUflPO0hPDENFZdqpHx-0';

  // Local cache for geocoded locations
  static final Map<String, LatLng> _geocodeCache = {};

  /// Search for places using server cache (preferred) or direct API.
  ///
  /// Server cache: FREE (cached Firestore data)
  /// Direct API fallback: ~$0.017 per request
  static Future<List<PlacePrediction>> searchPlaces(
    String query, {
    String? sessionToken,
    LatLng? location,
    double? radiusMeters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // 1. Try server cache first
      final serverUrl = Uri.parse(
        '${AppConfig.apiUrl}/places/autocomplete?input=${Uri.encodeComponent(query)}',
      );

      final serverResponse = await http
          .get(serverUrl)
          .timeout(const Duration(seconds: 5));

      if (serverResponse.statusCode == 200) {
        final data = jsonDecode(serverResponse.body);
        final predictions = data['predictions'] as List? ?? [];

        if (predictions.isNotEmpty) {
          debugPrint(
            'Places: Cache ${data['cached'] == true ? 'HIT' : 'MISS'} for "$query"',
          );
          return predictions
              .map((p) => PlacePrediction.fromServerJson(p))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Server places cache unavailable: $e');
    }

    // 2. Fallback to direct Google API
    try {
      final params = {
        'input': query,
        'key': _apiKey,
        if (sessionToken != null) 'sessiontoken': sessionToken,
        if (location != null)
          'location': '${location.latitude},${location.longitude}',
        if (radiusMeters != null) 'radius': radiusMeters.toString(),
      };

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      ).replace(queryParameters: params);

      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return [];

      return (data['predictions'] as List)
          .map((p) => PlacePrediction.fromJson(p))
          .toList();
    } catch (e) {
      debugPrint('Places autocomplete error: $e');
      return [];
    }
  }

  /// Get place details using server cache (preferred) or direct API.
  ///
  /// Server cache: FREE (cached Firestore data)
  /// Direct API fallback: ~$0.017 per request
  static Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      // 1. Try server cache first
      final serverUrl = Uri.parse(
        '${AppConfig.apiUrl}/places/details/$placeId',
      );

      final serverResponse = await http
          .get(serverUrl)
          .timeout(const Duration(seconds: 5));

      if (serverResponse.statusCode == 200) {
        final data = jsonDecode(serverResponse.body);
        if (data['place'] != null) {
          debugPrint(
            'PlaceDetails: Cache ${data['cached'] == true ? 'HIT' : 'MISS'} for $placeId',
          );
          return PlaceDetails.fromServerJson(data['place']);
        }
      }
    } catch (e) {
      debugPrint('Server place details unavailable: $e');
    }

    // 2. Fallback to direct Google API
    try {
      final params = {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'name,formatted_address,geometry,types,rating,photos',
        if (sessionToken != null) 'sessiontoken': sessionToken,
      };

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json',
      ).replace(queryParameters: params);

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return null;

      return PlaceDetails.fromJson(data['result']);
    } catch (e) {
      debugPrint('Place details error: $e');
      return null;
    }
  }

  /// Geocode an address using server cache (preferred) or direct API.
  ///
  /// Server cache: FREE (permanent cache)
  /// Direct API fallback: ~$0.005 per request
  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    // Check local cache first
    final cacheKey = address.toLowerCase().trim();
    if (_geocodeCache.containsKey(cacheKey)) {
      return _geocodeCache[cacheKey];
    }

    try {
      // 1. Try server cache
      final serverUrl = Uri.parse('${AppConfig.apiUrl}/places/geocode');
      final serverResponse = await http
          .post(
            serverUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'address': address}),
          )
          .timeout(const Duration(seconds: 5));

      if (serverResponse.statusCode == 200) {
        final data = jsonDecode(serverResponse.body);
        if (data['latitude'] != null && data['longitude'] != null) {
          final result = LatLng(
            data['latitude'].toDouble(),
            data['longitude'].toDouble(),
          );
          _geocodeCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Server geocode unavailable: $e');
    }

    // 2. Fallback to direct Google API
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || data['results'].isEmpty) return null;

      final location = data['results'][0]['geometry']['location'];
      final result = LatLng(
        location['lat'].toDouble(),
        location['lng'].toDouble(),
      );

      _geocodeCache[cacheKey] = result;
      return result;
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to an address.
  ///
  /// Cost: ~$0.005 per request (no caching for this)
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || data['results'].isEmpty) return null;

      return data['results'][0]['formatted_address'];
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Generate a Google Maps directions URL.
  ///
  /// Cost: FREE (uses URL scheme, not API)
  static String getDirectionsUrl({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
    double? originLat,
    double? originLng,
    String travelMode = 'driving',
  }) {
    final destination = '$destinationLat,$destinationLng';
    final destinationParam =
        destinationName != null
            ? Uri.encodeComponent(destinationName)
            : destination;

    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationParam&travelmode=$travelMode';

    if (originLat != null && originLng != null) {
      url += '&origin=$originLat,$originLng';
    }

    return url;
  }

  /// Generate a Google Maps URL for a specific location.
  ///
  /// Cost: FREE (uses URL scheme)
  static String getMapUrl({
    required double lat,
    required double lng,
    String? label,
    int zoom = 15,
  }) {
    if (label != null) {
      final encodedLabel = Uri.encodeComponent(label);
      return 'https://www.google.com/maps/search/?api=1&query=$encodedLabel';
    }
    return 'https://www.google.com/maps/@$lat,$lng,${zoom}z';
  }

  /// Clear local caches.
  static void clearCache() {
    _geocodeCache.clear();
  }
}

/// Simple lat/lng class
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Place prediction from autocomplete
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  /// Parse from direct Google API response
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structured['main_text'] ?? '',
      secondaryText: structured['secondary_text'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }

  /// Parse from server cache response
  factory PlacePrediction.fromServerJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placeId'] ?? '',
      description: json['description'] ?? '',
      mainText: json['mainText'] ?? '',
      secondaryText: json['secondaryText'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

/// Detailed place information
class PlaceDetails {
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final List<String> types;
  final List<String> photoReferences;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.rating,
    required this.types,
    required this.photoReferences,
  });

  /// Parse from direct Google API response
  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    final photos = json['photos'] as List? ?? [];

    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      latitude: location['lat']?.toDouble(),
      longitude: location['lng']?.toDouble(),
      rating: json['rating']?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      photoReferences:
          photos.map<String>((p) => p['photo_reference'] as String).toList(),
    );
  }

  /// Parse from server cache response
  factory PlaceDetails.fromServerJson(Map<String, dynamic> json) {
    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      rating: json['rating']?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      photoReferences: List<String>.from(json['photoReferences'] ?? []),
    );
  }

  /// Get a photo URL for this place.
  String? getPhotoUrl({int maxWidth = 400}) {
    if (photoReferences.isEmpty) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=${photoReferences.first}&key=AIzaSyDi2u-wZqvEUNKUflPO0hPDENFZdqpHx-0';
  }
}
