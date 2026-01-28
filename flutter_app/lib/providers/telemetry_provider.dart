import 'package:flutter/foundation.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/services/api_service.dart';
import 'package:campus_iot_app/services/mqtt_service.dart';
import 'dart:async';

class TelemetryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MqttService _mqttService = MqttService();
  
  // Historical telemetry data
  final Map<String, List<Telemetry>> _telemetryData = {};
  
  // Real-time telemetry streams
  final Map<String, StreamSubscription<Telemetry>> _streamSubscriptions = {};
  
  // Latest telemetry value per device (legacy/single)
  final Map<String, Telemetry> _latestValues = {};
  
  // Latest telemetry value per device AND metric (multi-sensor support)
  final Map<String, Map<String, Telemetry>> _latestByMetric = {};
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get historical telemetry for a device
  List<Telemetry> getTelemetryHistory(String deviceId) {
    return _telemetryData[deviceId] ?? [];
  }
  
  // Get latest value for a device (generic/last received)
  Telemetry? getLatestValue(String deviceId) {
    return _latestValues[deviceId];
  }

  // Get latest value specifically for a metric
  Telemetry? getLatestValueForMetric(String deviceId, String metric) {
    return _latestByMetric[deviceId]?[metric];
  }
  
  // Load historical telemetry from API
  Future<void> loadTelemetry({
    required String deviceId,
    String? metric,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getTelemetry(
        deviceId: deviceId,
        metric: metric,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      _telemetryData[deviceId] = data;
      
      // Set latest value if available
      if (data.isNotEmpty) {
        _latestValues[deviceId] = data.first;
        
        // Populate by metric
        if (!_latestByMetric.containsKey(deviceId)) {
          _latestByMetric[deviceId] = {};
        }
        for (var t in data.reversed) { // reversed so latest overwrites earlier
             _latestByMetric[deviceId]![t.metric] = t;
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading telemetry: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Subscribe to real-time telemetry for a device
  void subscribeToRealTime(String deviceId) {
    // Cancel existing subscription if any
    _streamSubscriptions[deviceId]?.cancel();
    
    // Subscribe to MQTT stream
    final stream = _mqttService.subscribeTelemetry(deviceId);
    
    _streamSubscriptions[deviceId] = stream.listen(
      (telemetry) {
        // Update latest value (global)
        _latestValues[deviceId] = telemetry;

        // Update latest value (per metric)
        if (!_latestByMetric.containsKey(deviceId)) {
          _latestByMetric[deviceId] = {};
        }
        _latestByMetric[deviceId]![telemetry.metric] = telemetry;
        
        // Add to historical data (keep last N points)
        if (!_telemetryData.containsKey(deviceId)) {
          _telemetryData[deviceId] = [];
        }
        
        _telemetryData[deviceId]!.insert(0, telemetry);
        
        // Keep only last 100 points
        if (_telemetryData[deviceId]!.length > 100) {
          _telemetryData[deviceId]!.removeLast();
        }
        
        notifyListeners();
      },
      onError: (error) {
        print('❌ Error in MQTT stream: $error');
        _error = error.toString();
        notifyListeners();
      },
    );
    
    print('📡 Subscribed to real-time telemetry for: $deviceId');
  }
  
  // Unsubscribe from real-time telemetry
  void unsubscribeFromRealTime(String deviceId) {
    _streamSubscriptions[deviceId]?.cancel();
    _streamSubscriptions.remove(deviceId);
    print('🔕 Unsubscribed from real-time telemetry for: $deviceId');
  }
  
  // Clear data for a device
  void clearDeviceData(String deviceId) {
    _telemetryData.remove(deviceId);
    _latestValues.remove(deviceId);
    _latestByMetric.remove(deviceId);
    unsubscribeFromRealTime(deviceId);
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    super.dispose();
  }
}
