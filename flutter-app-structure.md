# Estructura de la App Flutter - Plataforma IoT Campus

## Información General
- **Framework:** Flutter 3.16+
- **Lenguaje:** Dart 3.0+
- **Estado:** Provider / Riverpod (a definir)
- **Navegación:** GoRouter / Navigator 2.0

---

## Estructura de Carpetas
```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart
│   ├── routes.dart
│   └── constants.dart
├── models/
│   ├── device.dart
│   ├── telemetry.dart
│   ├── rule.dart
│   └── alert.dart
├── services/
│   ├── api_service.dart
│   ├── mqtt_service.dart
│   ├── auth_service.dart
│   └── storage_service.dart
├── providers/
│   ├── device_provider.dart
│   ├── telemetry_provider.dart
│   ├── alert_provider.dart
│   └── auth_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── devices/
│   │   ├── device_list_screen.dart
│   │   ├── device_detail_screen.dart
│   │   └── add_device_screen.dart
│   ├── telemetry/
│   │   └── telemetry_chart_screen.dart
│   ├── rules/
│   │   ├── rules_list_screen.dart
│   │   └── add_rule_screen.dart
│   └── alerts/
│       ├── alerts_list_screen.dart
│       └── alert_detail_screen.dart
├── widgets/
│   ├── device_card.dart
│   ├── alert_badge.dart
│   ├── telemetry_chart.dart
│   ├── status_indicator.dart
│   └── custom_app_bar.dart
└── utils/
    ├── validators.dart
    ├── formatters.dart
    └── constants.dart
```

---

## Modelos de Datos

### `models/device.dart`
```dart
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
      deviceId: json['deviceId'],
      name: json['name'],
      type: json['type'],
      location: json['location'],
      building: json['building'],
      floor: json['floor'],
      protocol: json['protocol'],
      status: json['status'],
      lastSeen: json['lastSeen'] != null 
        ? DateTime.parse(json['lastSeen'])
        : null,
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
        return Icons.thermostat;
      case 'occupancy':
        return Icons.people;
      case 'humidity':
        return Icons.water_drop;
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
```

### `models/telemetry.dart`
```dart
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
```

### `models/alert.dart`
```dart
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
```

---

## Servicio de API

### `services/api_service.dart`
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Headers comunes
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    // Agregar token JWT si existe
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  // ========== DEVICES ==========

  Future<List<Device>> getDevices({
    String? status,
    String? type,
    String? location,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (type != null) queryParams['type'] = type;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('$baseUrl/devices').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Device.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar dispositivos: ${response.statusCode}');
    }
  }

  Future<Device> getDeviceById(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Device.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Dispositivo no encontrado');
    } else {
      throw Exception('Error al cargar dispositivo');
    }
  }

  Future<Device> createDevice(Device device) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices'),
      headers: headers,
      body: json.encode(device.toJson()),
    );

    if (response.statusCode == 201) {
      return Device.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear dispositivo');
    }
  }

  Future<Device> updateDevice(String deviceId, Map<String, dynamic> updates) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: headers,
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar dispositivo');
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar dispositivo');
    }
  }

  // ========== TELEMETRY ==========

  Future<List<Telemetry>> getTelemetry({
    required String deviceId,
    String? metric,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'deviceId': deviceId,
      if (metric != null) 'metric': metric,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/telemetry').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List jsonList = data['data'];
      return jsonList.map((json) => Telemetry.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar telemetría');
    }
  }

  // ========== ALERTS ==========

  Future<List<Alert>> getAlerts({
    String? status,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (severity != null) queryParams['severity'] = severity;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/alerts').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar alertas');
    }
  }

  Future<Alert> acknowledgeAlert(String alertId, String acknowledgedBy, {String? notes}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/alerts/$alertId'),
      headers: headers,
      body: json.encode({
        'status': 'acknowledged',
        'acknowledgedBy': acknowledgedBy,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return Alert.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al reconocer alerta');
    }
  }
}
```

---

## Pantallas Principales

### `screens/home/dashboard_screen.dart`
```dart
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  List<Device> _devices = [];
  List<Alert> _activeAlerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final devices = await _apiService.getDevices();
      final alerts = await _apiService.getAlerts(status: 'active');
      
      setState(() {
        _devices = devices;
        _activeAlerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus IoT'),
        actions: [
          // Badge de alertas
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/alerts');
                },
              ),
              if (_activeAlerts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_activeAlerts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Resumen de estadísticas
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      
                      // Alertas recientes
                      if (_activeAlerts.isNotEmpty) ...[
                        _buildSectionHeader('Alertas Activas', () {
                          Navigator.pushNamed(context, '/alerts');
                        }),
                        const SizedBox(height: 12),
                        ..._activeAlerts.take(3).map((alert) => AlertCard(alert: alert)),
                        const SizedBox(height: 24),
                      ],
                      
                      // Lista de dispositivos
                      _buildSectionHeader('Dispositivos', () {
                        Navigator.pushNamed(context, '/devices');
                      }),
                      const SizedBox(height: 12),
                      ..._devices.map((device) => DeviceCard(
                        device: device,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/device-detail',
                            arguments: device,
                          );
                        },
                      )),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-device').then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCards() {
    final activeDevices = _devices.where((d) => d.status == 'active').length;
    final inactiveDevices = _devices.where((d) => d.status == 'inactive').length;
    final criticalAlerts = _activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Activos',
            value: activeDevices.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Inactivos',
            value: inactiveDevices.toString(),
            icon: Icons.cancel,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Alertas',
            value: criticalAlerts.toString(),
            icon: Icons.warning,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('Ver todos'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Widgets Reutilizables

### `widgets/device_card.dart`
```dart
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({
    Key? key,
    required this.device,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.statusColor.withOpacity(0.2),
          child: Icon(device.icon, color: device.statusColor),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.location ?? 'Sin ubicación'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: device.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  device.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (device.lastSeen != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    _formatLastSeen(device.lastSeen!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}
```

---

## Dependencias Necesarias (`pubspec.yaml`)
```yaml
name: campus_iot_app
description: Plataforma IoT para campus universitario

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  http: ^1.1.0
  
  # State Management
  provider: ^6.1.1
  # O: riverpod: ^2.4.9
  
  # Charts
  fl_chart: ^0.65.0
  
  # MQTT (opcional para tiempo real)
  mqtt_client: ^10.0.0
  
  # Storage local
  shared_preferences: ^2.2.2
  
  # UI
  intl: ^0.18.1
  timeago: ^3.6.0
  
  # Icons
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

---

## Configuración de Rutas (`config/routes.dart`)
```dart
import 'package:flutter/material.dart';

class AppRoutes {
  static const String

login = '/';
static const String dashboard = '/dashboard';
static const String devices = '/devices';
static const String deviceDetail = '/device-detail';
static const String addDevice = '/add-device';
static const String telemetry = '/telemetry';
static const String rules = '/rules';
static const String alerts = '/alerts';
static Route<dynamic> generateRoute(RouteSettings settings) {
switch (settings.name) {
case login:
return MaterialPageRoute(builder: (_) => const LoginScreen());
  case dashboard:
    return MaterialPageRoute(builder: (_) => const DashboardScreen());
  
  case devices:
    return MaterialPageRoute(builder: (_) => const DeviceListScreen());
  
  case deviceDetail:
    final device = settings.arguments as Device;
    return MaterialPageRoute(
      builder: (_) => DeviceDetailScreen(device: device),
    );
  
  case addDevice:
    return MaterialPageRoute(builder: (_) => const AddDeviceScreen());
  
  case alerts:
    return MaterialPageRoute(builder: (_) => const AlertsListScreen());
  
  default:
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
      ),
    );
}
}
}