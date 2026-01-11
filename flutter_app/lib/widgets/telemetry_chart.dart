import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:campus_iot_app/models/telemetry.dart';
import 'package:intl/intl.dart';

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
              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay datos disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    // Reverse data to show oldest first
    final reversedData = data.reversed.toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
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
                    return const Text('');
                  }
                  
                  // Show time for some points
                  if (index % (reversedData.length ~/ 5).clamp(1, 10) == 0) {
                    final time = DateFormat('HH:mm').format(
                      reversedData[index].timestamp,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        time,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
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
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: reversedData.length <= 20,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= reversedData.length) {
                    return null;
                  }
                  
                  final telemetry = reversedData[index];
                  final time = DateFormat('HH:mm:ss').format(telemetry.timestamp);
                  
                  return LineTooltipItem(
                    '${telemetry.formattedValue}\n$time',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
  
  double _getMinY(List<Telemetry> data) {
    final values = data.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min - 5).floorToDouble();
  }
  
  double _getMaxY(List<Telemetry> data) {
    final values = data.map((e) => e.value).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max + 5).ceilToDouble();
  }
}
