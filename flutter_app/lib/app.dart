import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/config/routes.dart';
import 'package:campus_iot_app/config/theme.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/providers/telemetry_provider.dart';
import 'package:campus_iot_app/services/mqtt_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MqttService _mqttService = MqttService();
  
  @override
  void initState() {
    super.initState();
    // Connect to MQTT broker on app start
    _connectToMqtt();
  }
  
  Future<void> _connectToMqtt() async {
    try {
      await _mqttService.connect();
      print('✅ MQTT connected successfully');
    } catch (e) {
      print('⚠️ MQTT connection failed: $e');
    }
  }
  
  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
      ],
      child: MaterialApp(
        title: 'Campus IoT',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system, // Automatically switch between light/dark
        initialRoute: AppRoutes.dashboard,
        onGenerateRoute: AppRoutes.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
