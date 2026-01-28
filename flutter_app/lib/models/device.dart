import 'package:flutter/material.dart';

class Device {
  final String deviceId;
  final String name;
  final String type;
  final String? location;
  final String? building;
  final int? floor;
  final String protocol;
  final String status;
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  Device({
    required this.deviceId,
    required this.name,
    required this.type,
    this.location,
    this.building,
    this.floor,
    required this.protocol,
    required this.status,
    this.lastSeen,
    this.metadata,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['device_id'] ?? json['deviceId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      location: json['location'],
      building: json['building'],
      floor: json['floor'],
      protocol: json['protocol'] ?? 'MQTT',
      status: json['status'] ?? 'active',
      lastSeen: json['last_seen'] != null 
        ? DateTime.parse(json['last_seen'])
        : (json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'])
          : null),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'type': type,
      'location': location,
      'building': building,
      'floor': floor,
      'protocol': protocol,
      'status': status,
      'lastSeen': lastSeen?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Helper para obtener icono según tipo
  IconData get icon {
    switch (type) {
      case 'temperature':
        return Icons.thermostat_outlined;
      case 'occupancy':
        return Icons.people_alt;
      case 'humidity':
        return Icons.water_drop;
      case 'light':
        return Icons.wb_incandescent;
      case 'energy':
        return Icons.flash_on;
      default:
        return Icons.sensors;
    }
  }

  // Helper para color de estado
  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
