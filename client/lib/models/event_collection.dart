class EventCollection {
  final String id;
  final String userId;
  final String name;
  final String description;
  final int itemCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.itemCount,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory EventCollection.fromJson(Map<String, dynamic> json) {
    return EventCollection(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'description': description,
    'itemCount': itemCount,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
