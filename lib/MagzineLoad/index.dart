import 'package:explosive_android_app/MagzineLoad/MagzineL1Scan.dart';
import 'package:flutter/material.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';

class MagzineLoadIndex extends StatefulWidget {
  const MagzineLoadIndex({super.key});

  @override
  State<MagzineLoadIndex> createState() => _MagzineLoadIndexState();
}

class _MagzineLoadIndexState extends State<MagzineLoadIndex> {
  final TextEditingController _magazineController = TextEditingController();

  // Focus nodes for managing focus
  final FocusNode _magazineFocusNode = FocusNode();

  // State variables to hold fetched data and loading status
  List<Map<String, dynamic>> _loadingSheets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _loadingNumbers = [];
  String? _selectedLoadingNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_magazineFocusNode);
    });
  }

  @override
  void dispose() {
    _magazineController.dispose();
    _magazineFocusNode.dispose();
    super.dispose();
  }

  // ============ BUSINESS LOGIC (PRESERVED) ============
  Future<void> _fetchLoadingNumbers() async {
    try {
      final magazineNo = _magazineController.text.trim();
      if (magazineNo.isEmpty) {
        setState(() {
          _errorMessage = 'Please scan Magazine Number.';
          _loadingNumbers = [];
        });
        return;
      }
      final data = await DBHandler.fetchIncompleteLoadingSheets();
      setState(() {
        _loadingNumbers = data
            .where((e) =>
                e['typeoofdispatc'] == 'ML' && e['magzine'] == magazineNo)
            .map((e) => e['loadingno'].toString())
            .toSet()
            .toList();
        if (_loadingNumbers.isNotEmpty) {
          _selectedLoadingNumber = _loadingNumbers.first;
          _fetchLoadingSheets();
        } else {
          _errorMessage = 'No loading sheets found for this magazine.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching loading numbers: ${e.toString()}';
      });
      debugPrint('Error fetching incomplete loading sheets: $e');
    }
  }

  Future<void> _fetchLoadingSheets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingSheets = [];
    });

    final magazineNo = _magazineController.text.trim();
    final loadingSheetNo = _selectedLoadingNumber;

    if (magazineNo.isEmpty || loadingSheetNo == null) {
      setState(() {
        _errorMessage = 'Please scan Magazine Number and select Loading Sheet.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await DBHandler.fetchLoadingSheetByLoadingNoAndMagazine(
          loadingSheetNo, magazineNo);
      setState(() {
        _loadingSheets = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching loading sheets: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error fetching loading sheets: $e');
    }
  }

  void _navigateToL1Scan(Map<String, dynamic> loadingSheetData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => L1BoxScanPage(loadingSheetData: loadingSheetData),
      ),
    );
    _fetchLoadingSheets();
  }
  // ============ END BUSINESS LOGIC ============

  void _resetSelection() {
    _magazineController.clear();
    setState(() {
      _loadingSheets = [];
      _loadingNumbers = [];
      _selectedLoadingNumber = null;
      _errorMessage = null;
    });
    FocusScope.of(context).requestFocus(_magazineFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Magazine Loading',
        backgroundColor: AppTheme.moduleMagazine,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset',
            onPressed: _resetSelection,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: AppTheme.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Magazine Scan Card
                _buildMagazineScanCard(),
                const SizedBox(height: AppTheme.spaceMD),

                // Loading Sheet Dropdown (only visible after magazine scan)
                if (_loadingNumbers.isNotEmpty) ...[
                  _buildLoadingSheetDropdown(),
                  const SizedBox(height: AppTheme.spaceMD),
                ],

                // Stats Row
                if (_loadingSheets.isNotEmpty) ...[
                  _buildStatsRow(),
                  const SizedBox(height: AppTheme.spaceMD),
                ],

                // Loading Sheets List
                Expanded(
                  child: _buildContentArea(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineScanCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Padding(
        padding: AppTheme.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: AppTheme.paddingSM,
                  decoration: BoxDecoration(
                    color: AppTheme.moduleMagazine.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: Icon(
                    Icons.warehouse_rounded,
                    color: AppTheme.moduleMagazine,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Text(
                  'Scan Magazine',
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: _magazineController,
              focusNode: _magazineFocusNode,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Scan Magazine Number',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.backgroundAlt, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.moduleMagazine, width: 2),
                ),
                contentPadding: AppTheme.paddingMD,
              ),
              onSubmitted: (value) {
                _fetchLoadingNumbers();
              },
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSheetDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Padding(
        padding: AppTheme.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: AppTheme.paddingSM,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Text(
                  'Select Loading Sheet',
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              value: _selectedLoadingNumber,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select Loading Sheet Number',
                prefixIcon: const Icon(Icons.numbers_rounded),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.backgroundAlt, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.moduleMagazine, width: 2),
                ),
                contentPadding: AppTheme.paddingMD,
              ),
              items: _loadingNumbers.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: AppTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLoadingNumber = newValue;
                });
                if (newValue != null) {
                  _fetchLoadingSheets();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final completedCount =
        _loadingSheets.where((s) => s['complete_flag'] == 1).length;
    final pendingCount = _loadingSheets.length - completedCount;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total',
            value: '${_loadingSheets.length}',
            color: AppTheme.info,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Completed',
            value: '$completedCount',
            color: AppTheme.success,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Pending',
            value: '$pendingCount',
            color: AppTheme.warning,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.moduleMagazine),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Loading sheets...',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return EmptyState(
        message: _errorMessage!,
        icon: Icons.error_outline_rounded,
        onRetry: _fetchLoadingNumbers,
        retryText: 'Try Again',
      );
    }

    if (_loadingNumbers.isEmpty && _magazineController.text.isEmpty) {
      return EmptyState(
        message: 'Scan a magazine number to view loading sheets',
        icon: Icons.qr_code_scanner_rounded,
      );
    }

    if (_loadingSheets.isEmpty && _loadingNumbers.isNotEmpty) {
      return EmptyState(
        message: 'No loading sheets found for the selected options',
        icon: Icons.inbox_rounded,
      );
    }

    if (_loadingSheets.isEmpty) {
      return const EmptyState(
        message: 'No data available',
        icon: Icons.inbox_rounded,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: AppTheme.paddingMD,
            decoration: BoxDecoration(
              gradient: AppTheme.moduleGradient(AppTheme.moduleMagazine),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loading Sheets',
                  style: AppTheme.titleMedium.copyWith(color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                  ),
                  child: Text(
                    '${_loadingSheets.length} Items',
                    style: AppTheme.labelMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: AppTheme.paddingSM,
              itemCount: _loadingSheets.length,
              itemBuilder: (context, index) {
                final sheet = _loadingSheets[index];
                return _buildSheetCard(sheet, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(Map<String, dynamic> sheet, int index) {
    final isCompleted = sheet['complete_flag'] == 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successSurface : Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        border: Border.all(
          color: isCompleted
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.backgroundAlt,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.borderRadiusMD,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusMD,
          onTap: isCompleted ? null : () => _navigateToL1Scan(sheet),
          child: Padding(
            padding: AppTheme.paddingMD,
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.moduleMagazine.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.pending_actions,
                    color: isCompleted
                        ? AppTheme.success
                        : AppTheme.moduleMagazine,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Loading No: ${sheet['loadingno'] ?? 'N/A'}',
                              style: AppTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceSM,
                              vertical: AppTheme.spaceXXS,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusCircle),
                            ),
                            child: Text(
                              isCompleted ? 'Completed' : 'Pending',
                              style: AppTheme.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Wrap(
                        spacing: AppTheme.spaceMD,
                        runSpacing: AppTheme.spaceXS,
                        children: [
                          _buildInfoChip(Icons.local_shipping,
                              'Truck: ${sheet['truckno'] ?? 'N/A'}'),
                          _buildInfoChip(
                              Icons.inventory, '${sheet['bname'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${sheet['product'] ?? 'N/A'}',
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceSM,
                              vertical: AppTheme.spaceXXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusCircle),
                            ),
                            child: Text(
                              'Cases: ${sheet['laodcases'] ?? 'N/A'}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(width: AppTheme.spaceSM),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.spaceXXS),
        Text(
          text,
          style: AppTheme.labelSmall,
        ),
      ],
    );
  }
}
