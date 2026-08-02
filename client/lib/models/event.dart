/// Event domain model for EventEase.
///
/// Notes:
/// - Dates are stored as ISO-8601 strings over the wire and parsed into DateTime.
/// - Location fields are intentionally flexible (venueName/address/latLng can be partial).
class Event {
  final String id;
  final String userId;

  final String title;
  final String description;

  final DateTime? startAt;
  final DateTime? endAt;

  final String? venueName;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final double? latitude;
  final double? longitude;

  final String? ticketUrl;
  final String? ticketPrice;

  final String? imageUrl; // Flyer / poster image
  final String? sourceUrl;
  final String? sourcePlatform; // instagram/tiktok/youtube/web/camera

  final List<String> categories; // Music, Art, Tech, Nightlife...

  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    this.id = '',
    this.userId = '',
    this.title = 'Untitled Event',
    this.description = '',
    this.startAt,
    this.endAt,
    this.venueName,
    this.address,
    this.city,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
    this.ticketUrl,
    this.ticketPrice,
    this.imageUrl,
    this.sourceUrl,
    this.sourcePlatform,
    this.categories = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Event(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Event',
      description: json['description']?.toString() ?? '',
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
      venueName: json['venueName']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      ticketUrl: json['ticketUrl']?.toString(),
      ticketPrice: json['ticketPrice']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
      sourcePlatform: json['sourcePlatform']?.toString(),
      categories:
          json['categories'] is List
              ? (json['categories'] as List)
                  .map((e) => e.toString())
                  .where((s) => s.trim().isNotEmpty)
                  .toList()
              : const [],
      createdAt:
          _parseDate(json['createdAt']) ??
          DateTime.now(), // server should send this
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'startAt': startAt?.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'venueName': venueName,
    'address': address,
    'city': city,
    'region': region,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'ticketUrl': ticketUrl,
    'ticketPrice': ticketPrice,
    'imageUrl': imageUrl,
    'sourceUrl': sourceUrl,
    'sourcePlatform': sourcePlatform,
    'categories': categories,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  Event copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    String? venueName,
    String? address,
    String? city,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
    String? ticketUrl,
    String? ticketPrice,
    String? imageUrl,
    String? sourceUrl,
    String? sourcePlatform,
    List<String>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


