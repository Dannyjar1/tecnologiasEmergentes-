import 'package:flutter/material.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../screens/devices/device_detail_screen.dart';
import '../screens/devices/add_device_screen.dart';
import '../screens/alerts/alerts_list_screen.dart';
import '../models/device.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String devices = '/devices';
  static const String deviceDetail = '/device-detail';
  static const String addDevice = '/add-device';
  static const String alerts = '/alerts';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
