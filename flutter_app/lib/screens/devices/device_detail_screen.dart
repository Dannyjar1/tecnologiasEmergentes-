import 'package:campus_iot_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/providers/telemetry_provider.dart';
import 'package:campus_iot_app/widgets/telemetry_chart.dart';
import 'package:campus_iot_app/widgets/real_time_value_card.dart';
import 'package:campus_iot_app/config/constants.dart';
import 'package:intl/intl.dart';
import 'package:campus_iot_app/screens/devices/edit_device_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // CORRECCIÓN 2: Guardamos la referencia al Provider aquí
    _telemetryProvider = context.read<TelemetryProvider>();
  }

  @override
  void dispose() {
    // Unsubscribe from real-time updates
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(),
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
                        builder: (context, telemetryProvider, deviceProvider,
                            child) {
                          final latestValue =
                              telemetryProvider.getLatestValueForMetric(
                                  widget.device.deviceId, metric);

                          // Get reactive device status
                          final currentDevice = deviceProvider.devices
                              .firstWhere(
                                  (d) => d.deviceId == widget.device.deviceId,
                                  orElse: () => widget.device);

                          return RealTimeValueCard(
                            telemetry: latestValue,
                            deviceType: type,
                            isLoading: telemetryProvider.isLoading &&
                                latestValue == null,
                            isOffline: currentDevice.status == 'inactive',
                          );
                        },
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),

                  // Historical Charts Header
                  Text(
                    'Análisis Histórico',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Charts
                  ...sensorTypes.map((type) {
                    final metric = _getMetricForType(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildChartCard(type, metric),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Device Metadata
                  _buildMetadataSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
            left: 60, bottom: 16), // Adjust for back button
        title: Text(
          widget.device.name,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(color: AppColors.primary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          onPressed: () => _showEditDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.uideGold),
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    bool isActive = widget.device.status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Dispositivo Activo' : 'Dispositivo Inactivo',
            style: GoogleFonts.inter(
              color: isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.device.lastSeen != null)
            Text(
              '• Última vez: ${DateFormat('HH:mm').format(widget.device.lastSeen!)}',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String type, String metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            DeviceTypes.getDisplayName(type),
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Consumer<TelemetryProvider>(
            builder: (context, provider, child) {
              final history = provider
                  .getTelemetryHistory(widget.device.deviceId)
                  .where((t) => t.metric == metric)
                  .toList();

              if (provider.isLoading && history.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return TelemetryChart(
                data: history,
                metric: type,
                lineColor: _getChartColor(type),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    if (widget.device.metadata == null || widget.device.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayMetadata = widget.device.metadata!.entries
        .where((e) => e.key != 'sensors')
        .toList();

    if (displayMetadata.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Técnica',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: displayMetadata.map((entry) {
              final isLast = entry.key == displayMetadata.last.key;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getChartColor(String type) {
    switch (type) {
      case 'temperature':
        return const Color(0xFFF97316); // Orange 500
      case 'humidity':
        return const Color(0xFF3B82F6); // Blue 500
      case 'occupancy':
        return const Color(0xFF8B5CF6); // Violet 500
      case 'light':
        return const Color(0xFFEAB308); // Yellow 500
      case 'energy':
        return const Color(0xFF22C55E); // Green 500
      default:
        return AppColors.accent;
    }
  }

  void _showEditDialog(BuildContext context) async {
    // Navigation logic implies logic not just UI, assuming this is correct or needs updating to new route names if changed.
    // Keeping existing logic for now but wrapped in modern calls if needed.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDeviceScreen(device: widget.device),
      ),
    );

    if (mounted) {
      final deviceProvider = context.read<DeviceProvider>();
      final updatedDevice = deviceProvider.devices.firstWhere(
        (d) => d.deviceId == widget.device.deviceId,
        orElse: () => widget.device,
      );

      if (updatedDevice != widget.device) {
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
        title: Text('Eliminar dispositivo',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${widget.device.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
