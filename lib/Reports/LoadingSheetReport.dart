import 'package:flutter/material.dart';
import '../Database/db_handler.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import 'LoadingSheetDetailsPage.dart';

class LoadingSheetReport extends StatefulWidget {
  const LoadingSheetReport({super.key});

  @override
  State<LoadingSheetReport> createState() => _LoadingSheetReportState();
}

class _LoadingSheetReportState extends State<LoadingSheetReport> {
  List<Map<String, dynamic>> _loadingData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  String? _selectedDispatchType;
  List<String> _dispatchTypeList = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ============ BUSINESS LOGIC (PRESERVED) ============
  @override
  void initState() {
    super.initState();
    _loadLoadingData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoadingData() async {
    try {
      final data = await DBHandler.fetchLoadingSheets();
      final dispatchTypes =
          data.map((e) => e['typeoofdispatc'].toString()).toSet().toList();
      dispatchTypes.sort();

      setState(() {
        _loadingData = data;
        _filteredData = data;
        _dispatchTypeList = dispatchTypes;
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

  void _filterByDispatchType(String? dispatchType) {
    setState(() {
      _selectedDispatchType = dispatchType;
      _applyFilters();
    });
  }

  void _filterBySearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _loadingData;

    if (_selectedDispatchType != null) {
      filtered = filtered
          .where((data) => data['typeoofdispatc'] == _selectedDispatchType)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['loadingno']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['truckno']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['bname']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['product']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredData = filtered;
    });
  }

  int get _pendingCount => _filteredData
      .where((item) => (item['complete_flag'] as int? ?? 0) == 0)
      .length;
  int get _completedCount => _filteredData
      .where((item) => (item['complete_flag'] as int? ?? 0) == 1)
      .length;
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Loading Sheet Report',
        backgroundColor: AppTheme.moduleMagazine,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _selectedDispatchType = null;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadLoadingData();
            },
            tooltip: 'Refresh',
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

                    // Filter Chips
                    if (_dispatchTypeList.isNotEmpty) _buildFilterChips(),
                    const SizedBox(height: AppTheme.spaceMD),

                    // Summary Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total',
                              value: '${_filteredData.length}',
                              color: AppTheme.moduleMagazine,
                              icon: Icons.description_rounded,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Expanded(
                            child: StatCard(
                              title: 'Pending',
                              value: '$_pendingCount',
                              color: AppTheme.warning,
                              icon: Icons.pending_actions,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Expanded(
                            child: StatCard(
                              title: 'Completed',
                              value: '$_completedCount',
                              color: AppTheme.success,
                              icon: Icons.check_circle,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),

                    // Data Display
                    Expanded(
                      child: _buildDataList(),
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
          hintText: 'Search by Loading No, Truck, Brand, or Product...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    _filterBySearch('');
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
        onChanged: _filterBySearch,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('All Types'),
            selected: _selectedDispatchType == null,
            onSelected: (selected) {
              _filterByDispatchType(null);
            },
            selectedColor: AppTheme.moduleMagazine.withOpacity(0.3),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: _selectedDispatchType == null
                  ? AppTheme.moduleMagazine
                  : AppTheme.textSecondary,
              fontWeight: _selectedDispatchType == null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusSM,
              side: BorderSide(
                color: _selectedDispatchType == null
                    ? AppTheme.moduleMagazine
                    : AppTheme.backgroundAlt,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          ..._dispatchTypeList.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceSM),
              child: FilterChip(
                label: Text(type),
                selected: _selectedDispatchType == type,
                onSelected: (selected) {
                  _filterByDispatchType(type);
                },
                selectedColor: AppTheme.moduleMagazine.withOpacity(0.3),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedDispatchType == type
                      ? AppTheme.moduleMagazine
                      : AppTheme.textSecondary,
                  fontWeight: _selectedDispatchType == type
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusSM,
                  side: BorderSide(
                    color: _selectedDispatchType == type
                        ? AppTheme.moduleMagazine
                        : AppTheme.backgroundAlt,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
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
              gradient: AppTheme.moduleGradient(AppTheme.moduleMagazine),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Loading Sheet Details',
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
          // List
          Expanded(
            child: _filteredData.isEmpty
                ? const EmptyState(
                    message:
                        'No loading sheets found.\nTry adjusting your filters.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.builder(
                    padding: AppTheme.paddingXS,
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final data = _filteredData[index];
                      final loadingSheetId = data['id'] as int?;
                      final loadingSheetNo = data['loadingno'] as String?;
                      final completeFlag = data['complete_flag'] as int? ?? 0;
                      final isCompleted = completeFlag == 1;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                          vertical: AppTheme.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.borderRadiusMD,
                          border: Border.all(
                            color: isCompleted
                                ? AppTheme.success.withOpacity(0.3)
                                : AppTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: AppTheme.borderRadiusMD,
                          child: InkWell(
                            borderRadius: AppTheme.borderRadiusMD,
                            onTap: () {
                              if (loadingSheetId != null &&
                                  loadingSheetNo != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LoadingSheetDetailsPage(
                                      loadingSheetId: loadingSheetId,
                                      loadingSheetNo: loadingSheetNo,
                                    ),
                                  ),
                                );
                              } else {
                                _showSnackBar(
                                    'Loading Sheet ID or Number is missing.',
                                    AppTheme.warning);
                              }
                            },
                            child: Padding(
                              padding: AppTheme.paddingMD,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    children: [
                                      Container(
                                        padding: AppTheme.paddingSM,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppTheme.successSurface
                                              : AppTheme.warningSurface,
                                          borderRadius: AppTheme.borderRadiusSM,
                                        ),
                                        child: Icon(
                                          isCompleted
                                              ? Icons.check_circle
                                              : Icons.pending,
                                          color: isCompleted
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceMD),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sheet: ${loadingSheetNo ?? 'N/A'}',
                                              style: AppTheme.titleSmall,
                                            ),
                                            const SizedBox(
                                                height: AppTheme.spaceXXS),
                                            Text(
                                              'Truck: ${data['truckno'] ?? 'N/A'}',
                                              style: AppTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: AppTheme.textTertiary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceMD),
                                  // Details
                                  Wrap(
                                    spacing: AppTheme.spaceMD,
                                    runSpacing: AppTheme.spaceXS,
                                    children: [
                                      _buildInfoChip(Icons.inventory,
                                          data['bname'] ?? 'N/A'),
                                      _buildInfoChip(Icons.category,
                                          data['product'] ?? 'N/A'),
                                      _buildInfoChip(Icons.local_shipping,
                                          data['typeoofdispatc'] ?? 'N/A'),
                                      _buildInfoChip(Icons.warehouse,
                                          data['magzine'] ?? 'N/A'),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  // Stats row
                                  Row(
                                    children: [
                                      _buildStatBadge(
                                          'Cases',
                                          data['laodcases']?.toString() ?? '0',
                                          AppTheme.moduleMagazine),
                                      const SizedBox(width: AppTheme.spaceSM),
                                      _buildStatBadge(
                                          'Weight',
                                          '${data['loadwt'] ?? 0} kg',
                                          AppTheme.info),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spaceSM,
                                          vertical: AppTheme.spaceXXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusCircle),
                                        ),
                                        child: Text(
                                          isCompleted ? 'DONE' : 'PENDING',
                                          style: AppTheme.labelSmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            value,
            style: AppTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
