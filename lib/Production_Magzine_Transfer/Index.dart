import 'package:explosive_android_app/Production_Magzine_Transfer/ProductionLoading.dart';
import 'package:explosive_android_app/Production_Magzine_Transfer/MagzineUnload.dart';
import 'package:flutter/material.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';

class TransferDetailsPage extends StatelessWidget {
  const TransferDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Truck-Magazine Transfer',
        backgroundColor: AppTheme.moduleProduction,
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

                // Transfer Options Section
                Text(
                  'Select Operation',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Loading Card
                _buildTransferCard(
                  context: context,
                  title: 'Loading',
                  subtitle: 'Load boxes from production to truck',
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.success,
                  secondaryIcon: Icons.local_shipping,
                  destination: const LoadingPage(),
                ),
                const SizedBox(height: AppTheme.spaceLG),

                // Unloading Card
                _buildTransferCard(
                  context: context,
                  title: 'Unloading',
                  subtitle: 'Unload boxes from truck to magazine',
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.moduleDirectDispatch,
                  secondaryIcon: Icons.warehouse,
                  destination: const UnloadingOperation(),
                ),

                const SizedBox(height: AppTheme.spaceXXL),

                // Info Section
                _buildInfoSection(),
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
            AppTheme.moduleProduction,
            AppTheme.moduleProduction.withOpacity(0.8),
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
              Icons.swap_horiz_rounded,
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
                  'Transfer Operations',
                  style: AppTheme.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Manage loading and unloading between production and magazine',
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

  Widget _buildTransferCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required IconData secondaryIcon,
    required Widget destination,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            },
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: AppTheme.paddingXL,
              child: Row(
                children: [
                  // Icon Stack
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: AppTheme.borderRadiusMD,
                        ),
                        child: Icon(
                          secondaryIcon,
                          color: Colors.white.withOpacity(0.5),
                          size: 32,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppTheme.spaceLG),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          subtitle,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppTheme.borderRadiusSM,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: AppTheme.paddingLG,
      decoration: BoxDecoration(
        color: AppTheme.infoSurface,
        borderRadius: AppTheme.borderRadiusMD,
        border: Border.all(
          color: AppTheme.info.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: AppTheme.paddingSM,
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSM,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Loading: Scan L1 boxes to load onto the truck from production.\n'
                  'Unloading: Scan boxes to unload from truck to magazine.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
