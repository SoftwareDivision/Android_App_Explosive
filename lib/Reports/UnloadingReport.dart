import 'package:flutter/material.dart';
import '../Database/db_handler.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';

class UnloadingReport extends StatefulWidget {
  const UnloadingReport({Key? key}) : super(key: key);

  @override
  _UnloadingReportState createState() => _UnloadingReportState();
}

class _UnloadingReportState extends State<UnloadingReport> {
  List<Map<String, dynamic>> _unloadingData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  String? _selectedMagazine;
  List<String> _magazineList = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ============ BUSINESS LOGIC (PRESERVED) ============
  @override
  void initState() {
    super.initState();
    _loadUnloadingData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnloadingData() async {
    try {
      final db = await DBHandler.getDatabase();
      if (db != null) {
        final data = await db.query('magzinestocktransfer');
        final magazines =
            data.map((e) => e['magazine_name'].toString()).toSet().toList();
        magazines.sort();
        setState(() {
          _unloadingData = data;
          _filteredData = data;
          _magazineList = magazines;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Error loading data: $e', AppTheme.error);
      }
    }
  }

  void _filterByMagazine(String? magazine) {
    setState(() {
      _selectedMagazine = magazine;
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
    List<Map<String, dynamic>> filtered = _unloadingData;

    if (_selectedMagazine != null) {
      filtered = filtered
          .where((item) => item['magazine_name'] == _selectedMagazine)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['transfer_id']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['plant']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['truck_no']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['bname']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredData = filtered;
    });
  }

  int get _pendingCount =>
      _filteredData.where((item) => item['read_flag'] == 0).length;
  int get _completedCount =>
      _filteredData.where((item) => item['read_flag'] == 1).length;
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
        title: 'Unloading Report',
        backgroundColor: AppTheme.success,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _selectedMagazine = null;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadUnloadingData();
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
                    if (_magazineList.isNotEmpty) _buildFilterChips(),
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
                              color: AppTheme.info,
                              icon: Icons.inventory_2_rounded,
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
          hintText: 'Search by Transfer ID, Plant, Truck, or Brand...',
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
            label: const Text('All Magazines'),
            selected: _selectedMagazine == null,
            onSelected: (selected) {
              _filterByMagazine(null);
            },
            selectedColor: AppTheme.success.withOpacity(0.3),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: _selectedMagazine == null
                  ? AppTheme.success
                  : AppTheme.textSecondary,
              fontWeight: _selectedMagazine == null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusSM,
              side: BorderSide(
                color: _selectedMagazine == null
                    ? AppTheme.success
                    : AppTheme.backgroundAlt,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          ..._magazineList.map(
            (magazine) => Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceSM),
              child: FilterChip(
                label: Text(magazine),
                selected: _selectedMagazine == magazine,
                onSelected: (selected) {
                  _filterByMagazine(magazine);
                },
                selectedColor: AppTheme.success.withOpacity(0.3),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedMagazine == magazine
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                  fontWeight: _selectedMagazine == magazine
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusSM,
                  side: BorderSide(
                    color: _selectedMagazine == magazine
                        ? AppTheme.success
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
              gradient: AppTheme.moduleGradient(AppTheme.success),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMD),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Unloading Details',
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
                        'No unloading records found.\nTry adjusting your filters.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.builder(
                    padding: AppTheme.paddingXS,
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final data = _filteredData[index];
                      final isCompleted = data['read_flag'] == 1;

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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: AppTheme.paddingMD,
                            title: Row(
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
                                        'Transfer: ${data['transfer_id'] ?? 'N/A'}',
                                        style: AppTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppTheme.spaceXXS),
                                      Text(
                                        'Magazine: ${data['magazine_name'] ?? 'N/A'}',
                                        style: AppTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: AppTheme.paddingMD,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDataRow(Icons.business, 'Plant',
                                        '${data['plant'] ?? 'N/A'} - ${data['plantcode'] ?? 'N/A'}'),
                                    _buildDataRow(Icons.warehouse, 'Magazine',
                                        data['magazine_name'] ?? 'N/A'),
                                    _buildDataRow(
                                        Icons.inventory_2,
                                        'Cases',
                                        data['case_quantity']?.toString() ??
                                            '0'),
                                    _buildDataRow(Icons.scale, 'Weight',
                                        '${data['total_wt']?.toString() ?? '0.0'} kg'),
                                    _buildDataRow(Icons.local_shipping,
                                        'Truck No', data['truck_no'] ?? 'N/A'),
                                    _buildDataRow(Icons.inventory, 'Brand',
                                        '${data['bname'] ?? 'N/A'} (ID: ${data['bid'] ?? 'N/A'})'),
                                    _buildDataRow(
                                        Icons.straighten,
                                        'Product Size',
                                        '${data['productsize'] ?? 'N/A'} (${data['sizecode'] ?? 'N/A'})'),
                                    const SizedBox(height: AppTheme.spaceMD),
                                    Container(
                                      padding: AppTheme.paddingSM,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppTheme.successSurface
                                            : AppTheme.warningSurface,
                                        borderRadius: AppTheme.borderRadiusSM,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCompleted
                                                ? Icons.check_circle
                                                : Icons.pending,
                                            color: isCompleted
                                                ? AppTheme.success
                                                : AppTheme.warning,
                                            size: 16,
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spaceSM),
                                          Text(
                                            isCompleted
                                                ? 'Completed'
                                                : 'Pending',
                                            style:
                                                AppTheme.labelMedium.copyWith(
                                              color: isCompleted
                                                  ? AppTheme.success
                                                  : AppTheme.warning,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.spaceSM),
          SizedBox(
            width: 90,
            child: Text(label, style: AppTheme.labelSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
