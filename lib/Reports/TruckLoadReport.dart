import 'package:flutter/material.dart';
import '../Database/db_handler.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart' hide DataRow;

class TruckLoadReport extends StatefulWidget {
  const TruckLoadReport({super.key});

  @override
  State<TruckLoadReport> createState() => _TruckLoadReportState();
}

class _TruckLoadReportState extends State<TruckLoadReport> {
  List<Map<String, dynamic>> _transferData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ============ BUSINESS LOGIC (PRESERVED) ============
  @override
  void initState() {
    super.initState();
    _loadTransferData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransferData() async {
    try {
      final data = await DBHandler.fetchAllTransferData();
      setState(() {
        _transferData = data;
        _filteredData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Error loading data: $e', AppTheme.error);
      }
    }
  }

  void _filterData(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredData = _transferData;
      } else {
        _filteredData = _transferData.where((item) {
          return item['truck_no']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              item['l1barcode']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              item['trans_id']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _exportData() {
    _showSnackBar('Export functionality coming soon!', AppTheme.info);
  }
  // ============ END BUSINESS LOGIC ============

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success
                  ? Icons.check_circle
                  : color == AppTheme.info
                      ? Icons.info_outline
                      : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        margin: AppTheme.paddingMD,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueTrucks = _filteredData.map((e) => e['truck_no']).toSet().length;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Truck Load Report',
        backgroundColor: AppTheme.moduleProduction,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadTransferData();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Export',
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: AppTheme.paddingMD,
                      child: _buildSearchBar(),
                    ),

                    // Summary Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Boxes',
                              value: '${_filteredData.length}',
                              color: AppTheme.moduleProduction,
                              icon: Icons.inventory_2_rounded,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          Expanded(
                            child: StatCard(
                              title: 'Unique Trucks',
                              value: '$uniqueTrucks',
                              color: AppTheme.success,
                              icon: Icons.local_shipping_rounded,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),

                    // Data Table
                    Expanded(
                      child: _buildDataTable(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      padding: AppTheme.paddingSM,
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by Truck No, Barcode, or Transfer ID...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    _filterData('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusMD,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          contentPadding: AppTheme.paddingMD,
        ),
        onChanged: _filterData,
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      margin: AppTheme.paddingMD,
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
              gradient: AppTheme.moduleGradient(AppTheme.moduleProduction),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: Colors.white, size: 20),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Loading Details',
                      style: AppTheme.titleSmall.copyWith(color: Colors.white),
                    ),
                  ],
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
                    '${_filteredData.length} Records',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Content
          Expanded(
            child: _filteredData.isEmpty
                ? const EmptyState(
                    message: 'No records found.\nTry adjusting your search.',
                    icon: Icons.search_off_rounded,
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) => AppTheme.surfaceVariant,
                        ),
                        headingTextStyle: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        dataTextStyle: AppTheme.bodySmall,
                        columnSpacing: AppTheme.spaceLG,
                        columns: const [
                          DataColumn(label: Text('Truck No')),
                          DataColumn(label: Text('L1 Barcode')),
                          DataColumn(label: Text('Transfer ID')),
                        ],
                        rows: _filteredData.map((data) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spaceSM,
                                    vertical: AppTheme.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySurface,
                                    borderRadius: AppTheme.borderRadiusSM,
                                  ),
                                  child: Text(
                                    data['truck_no'] ?? 'N/A',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['l1barcode'] ?? 'N/A',
                                  style: AppTheme.bodySmall.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['trans_id'] ?? 'N/A',
                                  style: AppTheme.bodySmall,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
