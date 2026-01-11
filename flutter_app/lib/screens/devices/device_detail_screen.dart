import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/providers/telemetry_provider.dart';
import 'package:campus_iot_app/widgets/telemetry_chart.dart';
import 'package:campus_iot_app/widgets/real_time_value_card.dart';
import 'package:campus_iot_app/config/theme.dart';
import 'package:intl/intl.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load historical telemetry
    final telemetryProvider = context.read<TelemetryProvider>();
    telemetryProvider.loadTelemetry(
      deviceId: widget.device.deviceId,
      limit: 50,
    );
    
    // Subscribe to real-time updates
    telemetryProvider.subscribeToRealTime(widget.device.deviceId);
  }
  
  @override
  void dispose() {
    // Unsubscribe from real-time updates
    context.read<TelemetryProvider>().unsubscribeFromRealTime(
      widget.device.deviceId,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<TelemetryProvider>().loadTelemetry(
            deviceId: widget.device.deviceId,
            limit: 50,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Info Card
              _buildDeviceInfoCard(),
              
              const SizedBox(height: 24),
              
              // Real-time Value
              Consumer<TelemetryProvider>(
                builder: (context, provider, child) {
                  final latestValue = provider.getLatestValue(widget.device.deviceId);
                  
                  return RealTimeValueCard(
                    telemetry: latestValue,
                    deviceType: widget.device.type,
                    isLoading: provider.isLoading,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Historical Chart
              const Text(
                'Histórico',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Consumer<TelemetryProvider>(
                builder: (context, provider, child) {
                  final history = provider.getTelemetryHistory(widget.device.deviceId);
                  
                  return Card(
                    child: Container(
                      height: 300,
                      padding: const EdgeInsets.all(8),
                      child: provider.isLoading && history.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : TelemetryChart(
                              data: history,
                              metric: widget.device.type,
                              lineColor: _getChartColor(),
                            ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Device Metadata
              _buildMetadataSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.device.statusColor.withOpacity(0.2),
                  radius: 30,
                  child: Icon(
                    widget.device.icon,
                    color: widget.device.statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: widget.device.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.device.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.device.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            _buildInfoRow(Icons.fingerprint, 'ID', widget.device.deviceId),
            _buildInfoRow(Icons.category, 'Tipo', widget.device.type),
            _buildInfoRow(Icons.location_on, 'Ubicación', 
              widget.device.location ?? 'No especificada'),
            if (widget.device.building != null)
              _buildInfoRow(Icons.business, 'Edificio', widget.device.building!),
            if (widget.device.floor != null)
              _buildInfoRow(Icons.stairs, 'Piso', widget.device.floor.toString()),
            _buildInfoRow(Icons.settings_input_antenna, 'Protocolo', 
              widget.device.protocol),
            if (widget.device.lastSeen != null)
              _buildInfoRow(Icons.access_time, 'Última conexión', 
                DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.device.lastSeen!)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetadataSection() {
    if (widget.device.metadata == null || widget.device.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metadata',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: widget.device.metadata!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(entry.value.toString()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getChartColor() {
    switch (widget.device.type) {
      case 'temperature':
        return AppColors.accentOrange;
      case 'humidity':
        return AppColors.infoBlue;
      case 'occupancy':
        return AppColors.accentPurple;
      default:
        return AppColors.primaryBlue;
    }
  }
  
  void _showEditDialog(BuildContext context) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición próximamente')),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dispositivo'),
        content: Text('¿Estás seguro de que deseas eliminar "${widget.device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await context.read<DeviceProvider>().deleteDevice(
                widget.device.deviceId,
              );
              
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dispositivo eliminado')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar dispositivo')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
