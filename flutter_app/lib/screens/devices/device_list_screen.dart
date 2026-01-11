import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/widgets/device_card.dart';
import 'package:campus_iot_app/config/routes.dart';
import 'package:campus_iot_app/config/constants.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  String? _selectedType;
  String? _selectedStatus;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          // Apply filters
          var devices = provider.devices;
          
          if (_selectedType != null) {
            devices = devices.where((d) => d.type == _selectedType).toList();
          }
          
          if (_selectedStatus != null) {
            devices = devices.where((d) => d.status == _selectedStatus).toList();
          }
          
          if (provider.isLoading && devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null && devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadDevices(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.loadDevices(),
            child: Column(
              children: [
                // Filter chips
                if (_selectedType != null || _selectedStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (_selectedType != null)
                          _FilterChip(
                            label: DeviceTypes.getDisplayName(_selectedType!),
                            onDeleted: () {
                              setState(() => _selectedType = null);
                            },
                          ),
                        if (_selectedStatus != null) ...[
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: _selectedStatus!.toUpperCase(),
                            onDeleted: () {
                              setState(() => _selectedStatus = null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Stats summary
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickStat(
                        label: 'Total',
                        value: devices.length.toString(),
                        icon: Icons.devices,
                        color: Colors.blue,
                      ),
                      _QuickStat(
                        label: 'Activos',
                        value: devices.where((d) => d.status == 'active').length.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _QuickStat(
                        label: 'Inactivos',
                        value: devices.where((d) => d.status == 'inactive').length.toString(),
                        icon: Icons.cancel,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Device list
                Expanded(
                  child: devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron dispositivos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return DeviceCard(
                              device: device,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.deviceDetail,
                                  arguments: device,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addDevice);
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
  
  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.filter_list, size: 24),
            SizedBox(width: 12),
            Text('Filtrar dispositivos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type filter
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null, 
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 12),
                      Text('Todos los tipos'),
                    ],
                  ),
                ),
                ...DeviceTypes.all.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(type), size: 20),
                        const SizedBox(width: 12),
                        Text(DeviceTypes.getDisplayName(type)),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Status filter
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 12),
                      Text('Todos los estados'),
                    ],
                  ),
                ),
                const DropdownMenuItem(
                  value: 'active',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Text('Activo'),
                    ],
                  ),
                ),
                const DropdownMenuItem(
                  value: 'inactive',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.grey, size: 20),
                      SizedBox(width: 12),
                      Text('Inactivo'),
                    ],
                  ),
                ),
                const DropdownMenuItem(
                  value: 'maintenance',
                  child: Row(
                    children: [
                      Icon(Icons.build, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Text('Mantenimiento'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedStatus = null;
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case DeviceTypes.temperature:
        return Icons.thermostat;
      case DeviceTypes.occupancy:
        return Icons.people;
      case DeviceTypes.humidity:
        return Icons.water_drop;
      case DeviceTypes.light:
        return Icons.lightbulb;
      case DeviceTypes.energy:
        return Icons.bolt;
      default:
        return Icons.device_unknown;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  
  const _FilterChip({
    required this.label,
    required this.onDeleted,
  });
  
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
