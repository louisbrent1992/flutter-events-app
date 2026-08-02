class GeneratedPlan {
  final String id;
  final String kind;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;

  const GeneratedPlan({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.input,
    required this.output,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) {
    return GeneratedPlan(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'itinerary',
      title: json['title']?.toString() ?? 'AI Plan',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      input:
          json['input'] is Map
              ? Map<String, dynamic>.from(json['input'])
              : const {},
      output:
          json['output'] is Map
              ? Map<String, dynamic>.from(json['output'])
              : const {},
    );
  }
}
