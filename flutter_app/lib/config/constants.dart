// Device Types
class DeviceTypes {
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String occupancy = 'occupancy';
  static const String light = 'light';
  static const String energy = 'energy';
  static const String multi = 'multi-sensor';
  
  static const List<String> all = [
    temperature,
    humidity,
    occupancy,
    light,
    energy,
    multi,
  ];
  
  static String getDisplayName(String type) {
    switch (type) {
      case temperature:
        return 'Temperatura';
      case humidity:
        return 'Humedad';
      case occupancy:
        return 'Ocupación';
      case light:
        return 'Iluminación';
      case energy:
        return 'Energía';
      default:
        return type;
    }
  }
}

// Device Status
class DeviceStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String maintenance = 'maintenance';
  
  static const List<String> all = [active, inactive, maintenance];
}

// Protocols
class Protocols {
  static const String mqtt = 'MQTT';
  static const String http = 'HTTP';
  static const String coap = 'CoAP';
  
  static const List<String> all = [mqtt, http, coap];
}

// Alert Severity
class AlertSeverity {
  static const String info = 'info';
  static const String warning = 'warning';
  static const String critical = 'critical';
  
  static const List<String> all = [info, warning, critical];
}

// Metric Units
class MetricUnits {
  static const String celsius = '°C';
  static const String fahrenheit = '°F';
  static const String percent = '%';
  static const String people = 'personas';
  static const String watts = 'W';
  static const String kilowatts = 'kW';
  static const String lux = 'lux';
}
