import 'package:campus_iot_app/config/routes.dart';
import 'package:campus_iot_app/config/theme.dart'; // Import for AppColors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_iot_app/providers/device_provider.dart';
import 'package:campus_iot_app/models/device.dart';
import 'package:campus_iot_app/widgets/device_card.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load devices on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          return RefreshIndicator(
            onRefresh: () => deviceProvider.loadDevices(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: _buildWelcomeSection(deviceProvider),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: _buildStatsCards(deviceProvider),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                    child: _buildSectionHeader(context, 'Mis Dispositivos', () {
                      Navigator.pushNamed(context, AppRoutes.devices);
                    }),
                  ),
                ),

                _buildDeviceList(context, deviceProvider),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)), // Bottom padding
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addDevice);
        },
        backgroundColor: AppColors.uideGold,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: AppColors.primary),
        label: Text(
          'Nuevo Dispositivo',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Campus IoT',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.uideGold),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.alerts);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(DeviceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitoreo en tiempo real de ${provider.totalDevices} dispositivos conectados.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(DeviceProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Activos',
            value: provider.activeCount.toString(),
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            backgroundColor: AppColors.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Inactivos',
            value: provider.inactiveCount.toString(),
            icon: Icons.error_outline,
            iconColor: AppColors.textSecondary, // Muted for inactive
            backgroundColor: AppColors.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Alertas',
            value: '0', // Placeholder for now
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            backgroundColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Ver todos',
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context, DeviceProvider provider) {
    if (provider.isLoading && provider.devices.isEmpty) {
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    }

    if (provider.devices.isEmpty) {
      return SliverFillRemaining(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other,
              size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No hay dispositivos registrados',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      )));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final device = provider.devices[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: DeviceCard(
              device: device,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.deviceDetail,
                  arguments: device,
                );
              },
            ),
          );
        },
        childCount: provider.devices.length,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
