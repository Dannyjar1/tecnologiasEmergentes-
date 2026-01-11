class AppConfig {
  // API REST Configuration
  static const String apiBaseUrl = 'http://127.0.0.1:8080/api';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // MQTT Configuration
  static const String mqttBrokerUrl = '127.0.0.1';
  static const int mqttBrokerPort = 1883;
  static const String mqttClientId = 'flutter_campus_iot';
  
  // MQTT Topics
  static const String mqttTopicPrefix = 'campus';
  static String getMqttTopic(String deviceId, String metric) {
    return '$mqttTopicPrefix/$deviceId/$metric';
  }
  
  // Refresh Intervals
  static const Duration deviceRefreshInterval = Duration(seconds: 30);
  static const Duration telemetryRefreshInterval = Duration(seconds: 60);
  
  // Pagination
  static const int defaultPageSize = 50;
  static const int telemetryDefaultLimit = 100;
  
  // Chart Configuration
  static const int chartMaxDataPoints = 50;
  static const Duration chartDefaultTimeRange = Duration(hours: 24);
}
