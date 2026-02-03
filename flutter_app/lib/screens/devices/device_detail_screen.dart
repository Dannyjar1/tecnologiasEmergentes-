import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/providers/telemetry_provider.dart';
import 'package:campus_iot_app/widgets/telemetry_chart.dart';
import 'package:campus_iot_app/widgets/real_time_value_card.dart';
import 'package:campus_iot_app/config/theme.dart';
import 'package:campus_iot_app/config/constants.dart';
import 'package:intl/intl.dart';
import 'package:campus_iot_app/screens/devices/edit_device_screen.dart';

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

    // Defer state updates to after the first frame
    // CORRECCIÓN 1: Posponemos la carga de datos hasta después del primer renderizado
    // para evitar el error "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final telemetryProvider = context.read<TelemetryProvider>();
      // Load historical telemetry
      telemetryProvider.loadTelemetry(
        deviceId: widget.device.deviceId,
        limit: 100, // Increased limit for multi-sensor data
      );

      // Subscribe to real-time updates
      telemetryProvider.subscribeToRealTime(widget.device.deviceId);
    });
  }

  late TelemetryProvider _telemetryProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CORRECCIÓN 2: Guardamos la referencia al Provider aquí, mientras el contexto es válido.
    // Intentar leer el contexto en dispose() lanzaría "Looking up a deactivated widget's ancestor is unsafe".
    _telemetryProvider = context.read<TelemetryProvider>();
  }

  @override
  void dispose() {
    // Unsubscribe from real-time updates
    // Usamos la referencia guardada (_telemetryProvider) para limpiar la suscripción de forma segura.
    _telemetryProvider.unsubscribeFromRealTime(
      widget.device.deviceId,
    );
    super.dispose();
  }

  List<String> _getSensorTypes() {
    if (widget.device.metadata != null &&
        widget.device.metadata!['sensors'] != null &&
        widget.device.metadata!['sensors'] is List) {
      return List<String>.from(widget.device.metadata!['sensors']);
    }
    // Fallback for legacy or single-sensor devices
    if (widget.device.type != DeviceTypes.multi) {
      return [widget.device.type];
    }
    return [];
  }

  String _getMetricForType(String type) {
    switch (type) {
      case 'light':
        return 'illumination';
      case 'energy':
        return 'power';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorTypes = _getSensorTypes();

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
                limit: 100,
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

              // Dynamic Real-time Cards
              if (sensorTypes.isEmpty)
                const Center(
                    child: Text("No sensors configured for this device.")),

              ...sensorTypes.map((type) {
                final metric = _getMetricForType(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Consumer2<TelemetryProvider, DeviceProvider>(
                    builder:
                        (context, telemetryProvider, deviceProvider, child) {
                      final latestValue =
                          telemetryProvider.getLatestValueForMetric(
                              widget.device.deviceId, metric);

                      // Get reactive device status
                      final currentDevice = deviceProvider.devices.firstWhere(
                          (d) => d.deviceId == widget.device.deviceId,
                          orElse: () => widget.device);

                      return RealTimeValueCard(
                        telemetry: latestValue,
                        deviceType: type,
                        isLoading:
                            telemetryProvider.isLoading && latestValue == null,
                        isOffline: currentDevice.status == 'inactive',
                      );
                    },
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Historical Charts
              const Text(
                'Histórico',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...sensorTypes.map((type) {
                final metric = _getMetricForType(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(DeviceTypes.getDisplayName(type),
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                      ),
                      const SizedBox(height: 8),
                      Consumer<TelemetryProvider>(
                        builder: (context, provider, child) {
                          final history = provider
                              .getTelemetryHistory(widget.device.deviceId)
                              .where((t) => t.metric == metric)
                              .toList();

                          return Card(
                            child: Container(
                              height: 250,
                              padding: const EdgeInsets.all(8),
                              child: provider.isLoading && history.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : TelemetryChart(
                                      data: history,
                                      metric:
                                          type, // Pass original type for color/labels
                                      lineColor: _getChartColor(type),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),

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
            _buildInfoRow(Icons.category, 'Tipo',
                _getSensorTypes().join(', ')), // Show all types
            _buildInfoRow(Icons.location_on, 'Ubicación',
                widget.device.location ?? 'No especificada'),
            if (widget.device.building != null)
              _buildInfoRow(
                  Icons.business, 'Edificio', widget.device.building!),
            if (widget.device.floor != null)
              _buildInfoRow(
                  Icons.stairs, 'Piso', widget.device.floor.toString()),
            _buildInfoRow(Icons.settings_input_antenna, 'Protocolo',
                widget.device.protocol),
            if (widget.device.lastSeen != null)
              _buildInfoRow(
                  Icons.access_time,
                  'Última conexión',
                  DateFormat('dd/MM/yyyy HH:mm:ss')
                      .format(widget.device.lastSeen!)),
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

    // Filter out internal 'sensors' metadata as it's already shown as cards
    final displayMetadata = widget.device.metadata!.entries
        .where((e) => e.key != 'sensors')
        .toList();

    if (displayMetadata.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Adicional', // Changed from 'Metadata' to be more user friendly
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
              children: displayMetadata.map((entry) {
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

  Color _getChartColor(String type) {
    switch (type) {
      case 'temperature':
        return AppColors.accentOrange;
      case 'humidity':
        return AppColors.infoBlue;
      case 'occupancy':
        return AppColors.accentPurple;
      case 'light':
        return Colors.amber;
      case 'energy':
        return Colors.green;
      default:
        return AppColors.primaryBlue;
    }
  }

  void _showEditDialog(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDeviceScreen(device: widget.device),
      ),
    );

    // Refresh device info from provider to get updated status
    if (mounted) {
      final deviceProvider = context.read<DeviceProvider>();
      final updatedDevice = deviceProvider.devices.firstWhere(
        (d) => d.deviceId == widget.device.deviceId,
        orElse: () => widget.device,
      );

      if (updatedDevice != widget.device) {
        setState(() {
          // We can't easily reassign widget.device as it's final in the State,
          // but normally we would want the parent or a provider to handle this.
          // For now, let's trigger a full refresh or just accept that
          // provider.devices is updated, BUT widget.device is still old.
          // Ideally, this screen should use Consumer<DeviceProvider> to find self.
        });
        // Trigger API reload just in case
        await deviceProvider.loadDevices();
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DeviceDetailScreen(
                    device: deviceProvider.devices.firstWhere(
                        (d) => d.deviceId == widget.device.deviceId))));
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dispositivo'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${widget.device.name}"?'),
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
                    const SnackBar(
                        content: Text('Error al eliminar dispositivo')),
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
