import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/DirectDispatchLoad/index.dart';
import 'package:explosive_android_app/Reports/Index.dart';
import 'package:explosive_android_app/Production_Magzine_Transfer/Index.dart';
import 'package:explosive_android_app/MagzineLoad/index.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0.0;
  int _currentSyncStep = 0; // Track current sync step (1-5)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============ BUSINESS LOGIC (PRESERVED) ============
  Future<void> _syncData() async {
    if (_isSyncing) return;

    // Start sync directly without confirmation
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Starting synchronization...';
      _syncProgress = 0.0;
      _currentSyncStep = 0;
    });
    try {
      // Start sync process
      await DBHandler.syncDataWithApi(
        onProgress: (progress, status) {
          // Safety check: only update UI if widget is still mounted
          if (mounted) {
            // Calculate current step based on progress (5 steps total)
            int step = 0;
            if (progress >= 0.1) step = 1;
            if (progress >= 0.3) step = 2;
            if (progress >= 0.5) step = 3;
            if (progress >= 0.7) step = 4;
            if (progress >= 0.9) step = 5;
            if (progress >= 1.0) step = 6; // Complete

            setState(() {
              _syncProgress = progress;
              _syncStatus = status;
              _currentSyncStep = step;
            });
          }
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppTheme.spaceSM),
              const Text('Data synchronized successfully'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(child: Text('Sync failed: $e')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _currentSyncStep = 0;
        });
      }
    }
  }

  Future<void> _resetDatabase() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Confirm Reset',
        content:
            'Are you sure you want to reset the database? This action cannot be undone.',
        confirmText: 'Reset',
        confirmColor: AppTheme.error,
        isDestructive: true,
      ),
    );

    if (confirm != true) return;

    final passwordController = TextEditingController();
    final bool? passwordOk = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLG),
        title: Row(
          children: [
            Container(
              padding: AppTheme.paddingSM,
              decoration: BoxDecoration(
                color: AppTheme.warningSurface,
                borderRadius: AppTheme.borderRadiusSM,
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.warning),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            const Text('Enter Password'),
          ],
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter admin password',
            prefixIcon: const Icon(Icons.key),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusMD,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(passwordController.text == '1234');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (passwordOk != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white),
              const SizedBox(width: AppTheme.spaceSM),
              const Text('Incorrect password. Reset cancelled.'),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        ),
      );
      return;
    }

    try {
      await DBHandler.resetAllData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppTheme.spaceSM),
              const Text('Database reset successfully'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                  child: Text('Error resetting database: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'Logout',
        content: 'Are you sure you want to exit the application?',
        confirmText: 'Exit',
        confirmColor: AppTheme.error,
      ),
    ).then((confirm) {
      if (confirm == true) {
        SystemNavigator.pop();
      }
    });
  }
  // ============ END BUSINESS LOGIC ============

  Widget _buildConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    bool isDestructive = false,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLG),
      title: Row(
        children: [
          Container(
            padding: AppTheme.paddingSM,
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppTheme.errorSurface
                  : AppTheme.primarySurface,
              borderRadius: AppTheme.borderRadiusSM,
            ),
            child: Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              color: isDestructive ? AppTheme.error : AppTheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text(title, style: AppTheme.titleLarge),
        ],
      ),
      content: Text(content, style: AppTheme.bodyMedium),
      actionsPadding: AppTheme.paddingMD,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child:
              Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSyncing,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Explosive Storage & Dispatch',
          backgroundColor: AppTheme.primaryDark,
          actions: [
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'logout') {
                  _logout();
                }
              },
              enabled: !_isSyncing,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.textSecondary),
                      const SizedBox(width: AppTheme.spaceSM),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background
            GradientBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    // Sync Progress Bar (optional, since we have the overlay now)
                    if (_isSyncing)
                      LinearProgressIndicator(
                        value: _syncProgress,
                        backgroundColor: AppTheme.primarySurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary),
                      ),

                    // Main Content
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: AppTheme.paddingLG,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Section
                              _buildWelcomeSection(),
                              const SizedBox(height: AppTheme.spaceXL),

                              // Operations Section
                              _buildSectionTitle(
                                  'Operations', Icons.dashboard_rounded),
                              const SizedBox(height: AppTheme.spaceMD),

                              // Operation Cards
                              ModuleCard(
                                title: 'Production-Magazine Transfer',
                                subtitle:
                                    'Transfer stock between production and magazine',
                                icon: Icons.swap_horiz_rounded,
                                color: AppTheme.moduleProduction,
                                onTap: () =>
                                    _navigateTo(const TransferDetailsPage()),
                              ),
                              ModuleCard(
                                title: 'Direct Dispatch Loading',
                                subtitle: 'Load directly for plant dispatch',
                                icon: Icons.local_shipping_rounded,
                                color: AppTheme.moduleDirectDispatch,
                                onTap: () =>
                                    _navigateTo(DirectDispatchLoadIndex()),
                              ),
                              ModuleCard(
                                title: 'Loading from Magazine',
                                subtitle: 'Load from magazine stock',
                                icon: Icons.inventory_2_rounded,
                                color: AppTheme.moduleMagazine,
                                onTap: () =>
                                    _navigateTo(const MagzineLoadIndex()),
                              ),
                              ModuleCard(
                                title: 'Reports',
                                subtitle: 'View all operational reports',
                                icon: Icons.analytics_rounded,
                                color: AppTheme.moduleReports,
                                onTap: () => _navigateTo(const ReportsIndex()),
                              ),

                              const SizedBox(height: AppTheme.spaceXL),

                              // System Section
                              _buildSectionTitle(
                                  'System', Icons.settings_rounded),
                              const SizedBox(height: AppTheme.spaceMD),

                              ModuleCard(
                                title: 'Sync Data',
                                subtitle: 'Synchronize with server',
                                icon: Icons.sync_rounded,
                                color: AppTheme.moduleSync,
                                onTap: _syncData,
                                isLoading: _isSyncing,
                              ),
                              ModuleCard(
                                title: 'Reset Database',
                                subtitle: 'Clear all local data',
                                icon: Icons.delete_forever_rounded,
                                color: AppTheme.moduleReset,
                                onTap: _resetDatabase,
                              ),

                              const SizedBox(height: AppTheme.spaceXXL),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Enhanced Sync Overlay with Step Progress
            if (_isSyncing)
              Positioned.fill(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.borderRadiusLG,
                        boxShadow: AppTheme.shadowLG,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with icon and title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync_rounded,
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Syncing Data',
                                style: AppTheme.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Progress percentage with circular indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: _syncProgress,
                                  strokeWidth: 8,
                                  backgroundColor: AppTheme.backgroundAlt,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppTheme.primary),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${(_syncProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                    style: AppTheme.headlineMedium.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Step-by-step progress indicators
                          _buildSyncStep(
                              1, 'Upload Loading Sheets', Icons.upload_rounded),
                          _buildSyncStep(2, 'Download Dispatch Data',
                              Icons.download_rounded),
                          _buildSyncStep(3, 'Upload Scanned Boxes',
                              Icons.qr_code_scanner_rounded),
                          _buildSyncStep(4, 'Download Magazine Data',
                              Icons.inventory_2_rounded),
                          _buildSyncStep(
                              5, 'Sync Production Data', Icons.factory_rounded),

                          const SizedBox(height: 16),

                          // Current status text
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundAlt,
                              borderRadius: AppTheme.borderRadiusMD,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _syncStatus,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a sync step indicator widget
  Widget _buildSyncStep(int stepNumber, String stepName, IconData icon) {
    final bool isCompleted = _currentSyncStep > stepNumber;
    final bool isActive = _currentSyncStep == stepNumber;
    final bool isPending = _currentSyncStep < stepNumber;

    Color iconColor;
    Widget statusWidget;

    if (isCompleted) {
      iconColor = AppTheme.success;
      statusWidget =
          const Icon(Icons.check_circle, color: AppTheme.success, size: 20);
    } else if (isActive) {
      iconColor = AppTheme.primary;
      statusWidget = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
      );
    } else {
      iconColor = AppTheme.textTertiary;
      statusWidget =
          Icon(Icons.circle_outlined, color: AppTheme.textTertiary, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          statusWidget,
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stepName,
              style: AppTheme.bodyMedium.copyWith(
                color: isPending
                    ? AppTheme.textTertiary
                    : (isActive ? AppTheme.primary : AppTheme.textPrimary),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: AppTheme.paddingLG,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary,
          ],
        ),
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.borderRadiusMD,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: AppTheme.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Manage your explosive storage and dispatch operations',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: AppTheme.spaceSM),
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _navigateTo(Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}
