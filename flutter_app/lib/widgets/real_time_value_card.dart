import 'package:flutter/material.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:campus_iot_app/config/theme.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
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
                    color: _getColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor Actual',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
                            ? AppColors.textSecondary.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.isOffline
                                  ? AppColors.textSecondary
                                  : AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isOffline ? 'OFFLINE' : 'EN VIVO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.isOffline
                                  ? AppColors.textSecondary
                                  : AppColors.success,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (widget.isOffline)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Desconectado',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
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
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
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
                        style: GoogleFonts.montserrat(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: _getColor(),
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.telemetry!.unit ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Timestamp
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Actualizado: ${_formatTimestamp(widget.telemetry!.timestamp)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Metadata if available
                  if (widget.telemetry!.metadata != null) ...[
                    const SizedBox(height: 16),
                    Divider(color: AppColors.divider.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
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
                            value:
                                '${widget.telemetry!.metadata!['signal']} dBm',
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
    switch (widget.deviceType.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'occupancy':
        return Icons.people_outline;
      case 'light':
        return Icons.light_mode_outlined;
      case 'energy':
        return Icons.bolt;
      default:
        return Icons.sensors;
    }
  }

  Color _getColor() {
    switch (widget.deviceType.toLowerCase()) {
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
