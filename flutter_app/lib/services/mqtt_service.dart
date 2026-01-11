import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:campus_iot_app/config/app_config.dart';
import 'package:campus_iot_app/models/telemetry.dart';

class MqttService {
  MqttServerClient? _client;
  bool _isConnected = false;
  
  // Stream controllers for telemetry data
  final Map<String, StreamController<Telemetry>> _telemetryControllers = {};
  
  // Singleton pattern
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();
  
  bool get isConnected => _isConnected;
  
  // Connect to MQTT broker
  Future<bool> connect() async {
    if (_isConnected) {
      print('✅ Already connected to MQTT broker');
      return true;
    }
    
    try {
      _client = MqttServerClient(
        AppConfig.mqttBrokerUrl,
        AppConfig.mqttClientId,
      );
      
      _client!.port = AppConfig.mqttBrokerPort;
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 60;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.autoReconnect = true;
      
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(AppConfig.mqttClientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMessage;
      
      print('🔄 Connecting to MQTT broker at ${AppConfig.mqttBrokerUrl}:${AppConfig.mqttBrokerPort}...');
      await _client!.connect();
      
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        print('✅ Connected to MQTT broker');
        
        // Subscribe to all device topics
        _subscribeToAllTopics();
        
        return true;
      } else {
        print('❌ Connection failed: ${_client!.connectionStatus}');
        _client!.disconnect();
        return false;
      }
    } catch (e) {
      print('❌ Error connecting to MQTT broker: $e');
      _client?.disconnect();
      return false;
    }
  }
  
  void _onConnected() {
    print('✅ MQTT client connected');
    _isConnected = true;
  }
  
  void _onDisconnected() {
    print('⚠️ MQTT client disconnected');
    _isConnected = false;
  }
  
  // Subscribe to all device topics
  void _subscribeToAllTopics() {
    if (_client == null || !_isConnected) return;
    
    // Subscribe to wildcard topic to receive all telemetry
    final topic = '${AppConfig.mqttTopicPrefix}/+/+';
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    print('📡 Subscribed to topic: $topic');
    
    // Listen to messages
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        _handleMessage(message);
      }
    });
  }
  
  // Subscribe to specific device telemetry
  Stream<Telemetry> subscribeTelemetry(String deviceId) {
    final key = deviceId;
    
    // Create stream controller if it doesn't exist
    if (!_telemetryControllers.containsKey(key)) {
      _telemetryControllers[key] = StreamController<Telemetry>.broadcast();
    }
    
    // If not connected, try to connect
    if (!_isConnected) {
      connect();
    }
    
    return _telemetryControllers[key]!.stream;
  }
  
  // Handle incoming MQTT messages
  void _handleMessage(MqttReceivedMessage<MqttMessage> message) {
    final topic = message.topic;
    final payload = message.payload as MqttPublishMessage;
    final payloadString = MqttPublishPayload.bytesToStringAsString(
      payload.payload.message,
    );
    
    try {
      // Parse topic: campus/{deviceId}/{metric}
      final parts = topic.split('/');
      if (parts.length != 3) return;
      
      final deviceId = parts[1];
      final metric = parts[2];
      
      // Parse JSON payload
      final data = json.decode(payloadString);
      
      // Create Telemetry object
      final telemetry = Telemetry(
        deviceId: deviceId,
        metric: metric,
        value: data['value']?.toDouble() ?? 0.0,
        unit: data['unit'] ?? '',
        timestamp: DateTime.parse(data['timestamp']),
        metadata: data['metadata'],
      );
      
      // Emit to stream
      final key = deviceId;
      if (_telemetryControllers.containsKey(key)) {
        _telemetryControllers[key]!.add(telemetry);
      }
      
      print('📨 Received: $deviceId - $metric: ${telemetry.value}${telemetry.unit}');
    } catch (e) {
      print('❌ Error parsing MQTT message: $e');
    }
  }
  
  // Publish message (for future use)
  void publish(String topic, Map<String, dynamic> message) {
    if (_client == null || !_isConnected) {
      print('⚠️ Cannot publish: Not connected to MQTT broker');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode(message));
    
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('📤 Published to $topic: $message');
  }
  
  // Disconnect
  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
      _isConnected = false;
      print('🔌 Disconnected from MQTT broker');
    }
    
    // Close all stream controllers
    for (final controller in _telemetryControllers.values) {
      controller.close();
    }
    _telemetryControllers.clear();
  }
  
  // Dispose
  void dispose() {
    disconnect();
  }
}
