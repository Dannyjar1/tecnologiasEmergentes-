
import 'package:flutter/material.dart';
enum AlertSeverity { info, warning, critical }
enum AlertStatus { active, acknowledged, closed }

class Alert {
  final String alertId;
  final String? ruleId;
  final String deviceId;
  final String metric;
  final AlertSeverity severity;
  final String message;
  final double value;
  final double? threshold;
  final AlertStatus status;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? notes;
  final DateTime timestamp;

  Alert({
    required this.alertId,
    this.ruleId,
    required this.deviceId,
    required this.metric,
    required this.severity,
    required this.message,
    required this.value,
    this.threshold,
    required this.status,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.notes,
    required this.timestamp,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alertId'],
      ruleId: json['ruleId'],
      deviceId: json['deviceId'],
      metric: json['metric'],
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      message: json['message'],
      value: (json['value'] as num).toDouble(),
      threshold: json['threshold'] != null 
        ? (json['threshold'] as num).toDouble()
        : null,
      status: AlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      acknowledgedBy: json['acknowledgedBy'],
      acknowledgedAt: json['acknowledgedAt'] != null
        ? DateTime.parse(json['acknowledgedAt'])
        : null,
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.critical:
        return Icons.error_outline;
    }
  }
}
