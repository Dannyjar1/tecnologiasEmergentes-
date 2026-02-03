import 'package:campus_iot_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class TelemetryChart extends StatelessWidget {
  final List<Telemetry> data;
  final String metric;
  final Color lineColor;

  const TelemetryChart({
    Key? key,
    required this.data,
    required this.metric,
    this.lineColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart,
                  size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No hay datos suficientes',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Reverse data to show oldest first
    final reversedData = data.reversed.toList();

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(0, 24, 16, 0), // Adjust padding for labels
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getInterval(reversedData),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= reversedData.length) {
                    return const SizedBox.shrink();
                  }

                  // Show roughly 5 labels
                  final step = (reversedData.length / 5).ceil().clamp(1, 100);

                  if (index % step == 0) {
                    final time = DateFormat('HH:mm').format(
                      reversedData[index].timestamp,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (reversedData.length - 1).toDouble(),
          minY: _getMinY(reversedData),
          maxY: _getMaxY(reversedData),
          lineBarsData: [
            LineChartBarData(
              spots: reversedData
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(
                        entry.key.toDouble(),
                        entry.value.value,
                      ))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0.2),
                    lineColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= reversedData.length) {
                    return null;
                  }

                  final telemetry = reversedData[index];
                  final time =
                      DateFormat('HH:mm:ss').format(telemetry.timestamp);

                  return LineTooltipItem(
                    '${telemetry.formattedValue}\n',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: time,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getInterval(List<Telemetry> data) {
    if (data.isEmpty) return 1;
    final min = _getMinY(data);
    final max = _getMaxY(data);
    final range = max - min;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    return 10;
  }

  double _getMinY(List<Telemetry> data) {
    if (data.isEmpty) return 0;
    final values = data.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min - (min * 0.1)).floorToDouble(); // Add 10% breathing room
  }

  double _getMaxY(List<Telemetry> data) {
    if (data.isEmpty) return 10;
    final values = data.map((e) => e.value).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max + (max * 0.1)).ceilToDouble(); // Add 10% breathing room
  }
}
