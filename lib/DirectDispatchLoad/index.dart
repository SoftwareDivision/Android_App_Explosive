import 'dart:convert';

import 'package:explosive_android_app/DirectDispatchLoad/DirectL1Scan.dart';
import 'package:flutter/material.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';

class DirectDispatchLoadIndex extends StatefulWidget {
  const DirectDispatchLoadIndex({super.key});

  @override
  State<DirectDispatchLoadIndex> createState() =>
      _DirectDispatchLoadIndexState();
}

class _DirectDispatchLoadIndexState extends State<DirectDispatchLoadIndex> {
  final TextEditingController _loadingSheetController = TextEditingController();
  final FocusNode _loadingSheetFocusNode = FocusNode();

  // State variable to hold fetched loading sheet data
  List<Map<String, dynamic>> _loadingSheets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _loadingNumbers = [];
  String? _selectedLoadingNumber;

  @override
  void initState() {
    super.initState();
    _fetchLoadingNumbers(); // Fetch loading numbers for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FocusScope.of(context).requestFocus(_loadingSheetFocusNode);
    });
  }

  @override
  void dispose() {
    // Clean up the controller and focus node when the widget is disposed
    _loadingSheetController.dispose();
    _loadingSheetFocusNode.dispose();
    super.dispose();
  }

  // ============ BUSINESS LOGIC (PRESERVED) ============
  // Function to fetch loading sheets from the database
  Future<void> _fetchLoadingNumbers() async {
    try {
      final data = await DBHandler.fetchIncompleteLoadingSheets();
      debugPrint(jsonEncode(data), wrapWidth: 1024);
      setState(() {
        _loadingNumbers = data
            .where((e) => e['typeoofdispatc'] == 'DD')
            .map((e) => e['loadingno'].toString())
            .toSet()
            .toList();
        if (_loadingNumbers.isNotEmpty) {
          _selectedLoadingNumber = _loadingNumbers.first;
          _fetchLoadingSheets(); // Fetch details for the first loading number
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching loading numbers: ${e.toString()}';
      });
      debugPrint('Error fetching incomplete loading sheets: $e');
    }
  }

  // Function to fetch loading sheets from the database
  Future<void> _fetchLoadingSheets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingSheets = []; // Clear previous data
    });

    final loadingSheetNo =
        _selectedLoadingNumber; // Use selected dropdown value

    if (loadingSheetNo == null || loadingSheetNo.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a Loading Sheet Number.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data =
          await DBHandler.fetchDirectDispatchLoadingSheet(loadingSheetNo);
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
  // ============ END BUSINESS LOGIC ============

  void _resetSelection() {
    _loadingSheetController.clear();
    setState(() {
      _loadingSheets = [];
      _errorMessage = null;
    });
    FocusScope.of(context).requestFocus(_loadingSheetFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Direct Dispatch Loading',
        backgroundColor: AppTheme.moduleDirectDispatch,
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
                // Header Card with Dropdown
                _buildDropdownCard(),
                const SizedBox(height: AppTheme.spaceMD),

                // Stats Row
                if (_loadingSheets.isNotEmpty) ...[
                  _buildStatsRow(),
                  const SizedBox(height: AppTheme.spaceMD),
                ],

                // Display Loading Sheets or loading/error state
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

  Widget _buildDropdownCard() {
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
                    color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: AppTheme.moduleDirectDispatch,
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
                  borderSide: BorderSide(
                      color: AppTheme.moduleDirectDispatch, width: 2),
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
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Sheets',
            value: '${_loadingSheets.length}',
            color: AppTheme.info,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Ready to Load',
            value:
                '${_loadingSheets.where((s) => (s['complete_flag'] ?? 0) == 0).length}',
            color: AppTheme.success,
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
                  AlwaysStoppedAnimation<Color>(AppTheme.moduleDirectDispatch),
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
        onRetry: _fetchLoadingSheets,
        retryText: 'Try Again',
      );
    }

    if (_loadingSheets.isEmpty) {
      return EmptyState(
        message: _loadingNumbers.isEmpty
            ? 'No loading sheets available for Direct Dispatch'
            : 'No loading sheets found for the selected number',
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
              gradient: AppTheme.moduleGradient(AppTheme.moduleDirectDispatch),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        border: Border.all(color: AppTheme.backgroundAlt),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.borderRadiusMD,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusMD,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DirectL1ScanPage(loadingSheetData: sheet),
              ),
            );
          },
          child: Padding(
            padding: AppTheme.paddingMD,
            child: Row(
              children: [
                // Index Badge
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.titleSmall.copyWith(
                      color: AppTheme.moduleDirectDispatch,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading No: ${sheet['loadingno'] ?? 'N/A'}',
                        style: AppTheme.titleSmall,
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Wrap(
                        spacing: AppTheme.spaceMD,
                        runSpacing: AppTheme.spaceXS,
                        children: [
                          _buildInfoChip(Icons.receipt_long,
                              'Indent: ${sheet['indentno'] ?? 'N/A'}'),
                          _buildInfoChip(Icons.local_shipping,
                              'Truck: ${sheet['truckno'] ?? 'N/A'}'),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${sheet['bname'] ?? 'N/A'} - ${sheet['product'] ?? 'N/A'}',
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
                              color: AppTheme.successSurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusCircle),
                            ),
                            child: Text(
                              'Qty: ${sheet['laodcases'] ?? 'N/A'}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
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
