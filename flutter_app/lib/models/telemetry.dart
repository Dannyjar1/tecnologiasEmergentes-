class Telemetry {
  final int? id;
  final String deviceId;
  final String metric;
  final double value;
  final String? unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Telemetry({
    this.id,
    required this.deviceId,
    required this.metric,
    required this.value,
    this.unit,
    required this.timestamp,
    this.metadata,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      id: json['id'],
      deviceId: json['deviceId'],
      metric: json['metric'],
      value: (json['value'] as num).toDouble(),
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  String get formattedValue {
    if (unit != null) {
      return '${value.toStringAsFixed(1)} $unit';
    }
    return value.toStringAsFixed(1);
  }
}
