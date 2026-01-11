import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/models/alert.dart';
import 'package:campus_iot_app/config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  
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
