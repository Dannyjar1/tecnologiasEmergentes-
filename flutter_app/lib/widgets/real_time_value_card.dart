import 'package:flutter/material.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/config/theme.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class RealTimeValueCard extends StatefulWidget {
  final Telemetry? telemetry;
  final String deviceType;
  final bool isLoading;
  final bool isOffline;
  
  const RealTimeValueCard({
    Key? key,
    this.telemetry,
    required this.deviceType,
    this.isLoading = false,
    this.isOffline = false,
  }) : super(key: key);

  @override
  State<RealTimeValueCard> createState() => _RealTimeValueCardState();
}

class _RealTimeValueCardState extends State<RealTimeValueCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every second to update relative time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && widget.telemetry != null && !widget.isOffline) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getGradientColor().withOpacity(0.1),
              _getGradientColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getGradientColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getGradientColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor Actual',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isOffline 
                            ? Colors.grey[300] 
                            : AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.isOffline ? Colors.grey[600] : AppColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isOffline ? 'OFFLINE' : 'EN VIVO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isOffline ? Colors.grey[600] : AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Value
            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (widget.isOffline)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Dispositivo Inactivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        'Sin recepción de datos',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else if (widget.telemetry == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Esperando datos...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.telemetry!.value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getGradientColor(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.telemetry!.unit ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Timestamp
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Actualizado: ${_formatTimestamp(widget.telemetry!.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Metadata if available
                  if (widget.telemetry!.metadata != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (widget.telemetry!.metadata!['battery'] != null)
                          _MetadataChip(
                            icon: Icons.battery_charging_full,
                            label: 'Batería',
                            value: '${widget.telemetry!.metadata!['battery']}%',
                          ),
                        if (widget.telemetry!.metadata!['signal'] != null)
                          _MetadataChip(
                            icon: Icons.signal_cellular_alt,
                            label: 'Señal',
                            value: '${widget.telemetry!.metadata!['signal']} dBm',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIcon() {
    print('DEBUG: Getting icon for type: ${widget.deviceType}');
    switch (widget.deviceType.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat_outlined; 
      case 'humidity':
        return Icons.water_drop;
      case 'occupancy':
        return Icons.people_alt; 
      case 'light':
        return Icons.wb_incandescent; 
      case 'energy':
        return Icons.flash_on; 
      default:
        return Icons.sensors;
    }
  }
  
  Color _getGradientColor() {
    switch (widget.deviceType.toLowerCase()) { // Safely lowercase
      case 'temperature':
        return AppColors.accentOrange;
      case 'humidity':
        return AppColors.infoBlue;
      case 'occupancy':
        return AppColors.accentPurple;
      case 'light':
        return AppColors.warningAmber;
      case 'energy':
        return AppColors.successGreen;
      default:
        return AppColors.primaryBlue;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    // Fix: Ensure we don't show negative times due to slight clock skews
    if (diff.isNegative) {
      return 'ahora';
    }
    
    if (diff.inSeconds < 60) {
      return 'hace ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes}m';
    } else {
      return DateFormat('HH:mm:ss').format(timestamp);
    }
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
