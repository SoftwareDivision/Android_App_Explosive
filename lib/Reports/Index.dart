import 'package:explosive_android_app/Reports/TruckLoadReport.dart';
import 'package:explosive_android_app/Reports/UnloadingReport.dart';
import 'package:explosive_android_app/Reports/LoadingSheetReport.dart';
import 'package:flutter/material.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';

class ReportsIndex extends StatelessWidget {
  const ReportsIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Reports Dashboard',
        backgroundColor: AppTheme.moduleReports,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: AppTheme.spaceXXL),

                // Reports Section Title
                Text(
                  'Available Reports',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Reports Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.spaceMD,
                  mainAxisSpacing: AppTheme.spaceMD,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.9,
                  children: [
                    // Truck Load Report Card
                    _buildReportCard(
                      context,
                      title: 'Truck Load',
                      subtitle: 'Loading Reports',
                      icon: Icons.local_shipping_rounded,
                      color: AppTheme.moduleProduction,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TruckLoadReport(),
                          ),
                        );
                      },
                    ),
                    // Unloading Report Card
                    _buildReportCard(
                      context,
                      title: 'Unloading',
                      subtitle: 'Magazine Unloading',
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.success,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UnloadingReport(),
                          ),
                        );
                      },
                    ),
                    // Loading Sheet Report Card
                    _buildReportCard(
                      context,
                      title: 'Loading Sheet',
                      subtitle: 'Detailed Reports',
                      icon: Icons.description_rounded,
                      color: AppTheme.moduleMagazine,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoadingSheetReport(),
                          ),
                        );
                      },
                    ),
                    // Summary Report Card
                    _buildReportCard(
                      context,
                      title: 'Summary',
                      subtitle: 'Overview Reports',
                      icon: Icons.analytics_rounded,
                      color: AppTheme.moduleDirectDispatch,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: AppTheme.spaceSM),
                                Text('Summary Report coming soon!'),
                              ],
                            ),
                            backgroundColor: AppTheme.info,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.borderRadiusMD,
                            ),
                            margin: AppTheme.paddingMD,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spaceXXL),

                // Quick Stats Section
                _buildQuickStatsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: AppTheme.paddingXL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.moduleReports,
            AppTheme.moduleReports.withOpacity(0.8),
          ],
        ),
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.borderRadiusMD,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: AppTheme.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'View detailed reports and track operations',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.borderRadiusMD,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.85),
              ],
            ),
            borderRadius: AppTheme.borderRadiusMD,
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppTheme.borderRadiusMD,
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: AppTheme.paddingLG,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  size: 20, color: AppTheme.moduleReports),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Quick Stats',
                style: AppTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  'Today\'s Loads',
                  '—',
                  Icons.local_shipping_outlined,
                  AppTheme.moduleProduction,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildQuickStatItem(
                  'Pending',
                  '—',
                  Icons.pending_actions,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildQuickStatItem(
                  'Completed',
                  '—',
                  Icons.check_circle_outline,
                  AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Container(
            padding: AppTheme.paddingSM,
            decoration: BoxDecoration(
              color: AppTheme.infoSurface,
              borderRadius: AppTheme.borderRadiusSM,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.info),
                const SizedBox(width: AppTheme.spaceSM),
                Text(
                  'Stats will update when connected to database',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: AppTheme.paddingSM,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.borderRadiusSM,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTheme.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
