import 'package:campus_iot_app/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/models/alert.dart';
import 'package:campus_iot_app/widgets/device_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load devices on init (Provider handles this automatically)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Campus IoT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // Badge de alertas
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.alerts);
                    },
                  ),
                  // TODO: Add alert badge when alerts are implemented
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading && deviceProvider.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (deviceProvider.error != null && deviceProvider.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(deviceProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => deviceProvider.loadDevices(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => deviceProvider.loadDevices(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome banner
                if (deviceProvider.devices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dashboard, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Bienvenido!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tienes ${deviceProvider.totalDevices} ${deviceProvider.totalDevices == 1 ? "dispositivo registrado" : "dispositivos registrados"}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
                      ],
                    ),
                  ),
                
                // Resumen de estadísticas
                _buildStatsCards(deviceProvider),
                const SizedBox(height: 24),
                
                // Lista de dispositivos
                _buildSectionHeader('Mis Dispositivos', () {
                  Navigator.pushNamed(context, AppRoutes.devices);
                }),
                const SizedBox(height: 12),
                
                if (deviceProvider.devices.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.devices_other_rounded,
                              size: 64,
                              color: Colors.blue[300],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '¡Comienza agregando tu primer dispositivo!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Los dispositivos IoT te permiten monitorear\ntemperatura, ocupación y más en tiempo real.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.addDevice);
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Agregar Primer Dispositivo'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...deviceProvider.devices.map((device) => DeviceCard(
                    device: device,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.deviceDetail,
                        arguments: device,
                      );
                    },
                  )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.addDevice);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text(
            'Agregar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(DeviceProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Activos',
            value: provider.activeCount.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Inactivos',
            value: provider.inactiveCount.toString(),
            icon: Icons.cancel,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: provider.totalDevices.toString(),
            icon: Icons.devices,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('Ver todos'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Alert {}

class AlertCard extends StatelessWidget {
  const AlertCard({
    Key? key,
    required this.alert,
  }) : super(key: key);

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}