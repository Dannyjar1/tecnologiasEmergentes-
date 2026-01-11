import 'package:flutter/foundation.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/services/api_service.dart';
import 'dart:async';

class DeviceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filtered devices
  List<Device> get activeDevices => 
      _devices.where((d) => d.status == 'active').toList();
  
  List<Device> get inactiveDevices => 
      _devices.where((d) => d.status == 'inactive').toList();
  
  // Statistics
  int get totalDevices => _devices.length;
  int get activeCount => activeDevices.length;
  int get inactiveCount => inactiveDevices.length;
  
  DeviceProvider() {
    // Load devices on initialization
    loadDevices();
    // Start auto-refresh
    startAutoRefresh();
  }
  
  // Load all devices
  Future<void> loadDevices({
    String? status,
    String? type,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _devices = await _apiService.getDevices(
        status: status,
        type: type,
        location: location,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get device by ID
  Device? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }
  
  // Refresh device from API
  Future<Device?> refreshDevice(String deviceId) async {
    try {
      final device = await _apiService.getDeviceById(deviceId);
      
      // Update in local list
      final index = _devices.indexWhere((d) => d.deviceId == deviceId);
      if (index != -1) {
        _devices[index] = device;
        notifyListeners();
      }
      
      return device;
    } catch (e) {
      print('❌ Error refreshing device: $e');
      return null;
    }
  }
  
  // Create new device
  Future<bool> createDevice(Device device) async {
    try {
      final newDevice = await _apiService.createDevice(device);
      _devices.add(newDevice);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating device: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Update device
  Future<bool> updateDevice(String deviceId, Map<String, dynamic> updates) async {
    try {
      final updatedDevice = await _apiService.updateDevice(deviceId, updates);
      
      // Update in local list
      final index = _devices.indexWhere((d) => d.deviceId == deviceId);
      if (index != -1) {
        _devices[index] = updatedDevice;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating device: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Delete device
  Future<bool> deleteDevice(String deviceId) async {
    try {
      await _apiService.deleteDevice(deviceId);
      
      // Remove from local list
      _devices.removeWhere((d) => d.deviceId == deviceId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error deleting device: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Start auto-refresh timer
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadDevices(),
    );
  }
  
  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
