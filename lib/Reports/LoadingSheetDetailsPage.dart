import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Database/db_handler.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';

class LoadingSheetDetailsPage extends StatefulWidget {
  final int loadingSheetId;
  final String loadingSheetNo;

  const LoadingSheetDetailsPage({
    Key? key,
    required this.loadingSheetId,
    required this.loadingSheetNo,
  }) : super(key: key);

  @override
  _LoadingSheetDetailsPageState createState() =>
      _LoadingSheetDetailsPageState();
}

class _LoadingSheetDetailsPageState extends State<LoadingSheetDetailsPage> {
  List<Map<String, dynamic>> _barcodes = [];
  List<Map<String, dynamic>> _filteredBarcodes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ============ BUSINESS LOGIC (PRESERVED) ============
  @override
  void initState() {
    super.initState();
    _loadBarcodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarcodes() async {
    try {
      final data =
          await DBHandler.fetchL1BarcodesForLoadingSheet(widget.loadingSheetId);
      setState(() {
        _barcodes = data;
        _filteredBarcodes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading barcodes: $e', AppTheme.error);
    }
  }

  void _filterBarcodes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBarcodes = _barcodes;
      } else {
        _filteredBarcodes = _barcodes.where((item) {
          return item['l1barcode']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Barcode copied to clipboard', AppTheme.success);
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Barcodes: ${widget.loadingSheetNo}',
        backgroundColor: AppTheme.moduleMagazine,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadBarcodes();
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
                    // Summary Card
                    Padding(
                      padding: AppTheme.paddingMD,
                      child: _buildSummaryCard(),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD),
                      child: _buildSearchBar(),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),

                    // Barcodes List
                    Expanded(
                      child: _buildBarcodesList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.moduleGradient(AppTheme.moduleMagazine),
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      padding: AppTheme.paddingLG,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.borderRadiusMD,
            ),
            child: const Icon(
              Icons.qr_code_rounded,
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
                  'Total Barcodes',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '${_filteredBarcodes.length}',
                  style: AppTheme.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD,
              vertical: AppTheme.spaceSM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: AppTheme.spaceXS),
                Text(
                  widget.loadingSheetNo,
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          hintText: 'Search barcodes...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    _filterBarcodes('');
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
        onChanged: _filterBarcodes,
      ),
    );
  }

  Widget _buildBarcodesList() {
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
                    const Icon(Icons.list_alt, color: Colors.white, size: 20),
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(
                      'Barcode List',
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
                    '${_filteredBarcodes.length} Items',
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
            child: _filteredBarcodes.isEmpty
                ? const EmptyState(
                    message: 'No barcodes found for this loading sheet.',
                    icon: Icons.qr_code_scanner,
                  )
                : ListView.builder(
                    padding: AppTheme.paddingXS,
                    itemCount: _filteredBarcodes.length,
                    itemBuilder: (context, index) {
                      final barcodeData = _filteredBarcodes[index];
                      final barcode = barcodeData['l1barcode'] ?? 'N/A';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                          vertical: AppTheme.spaceXXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.borderRadiusSM,
                          border: Border.all(color: AppTheme.backgroundAlt),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMD,
                            vertical: AppTheme.spaceXS,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: AppTheme.borderRadiusSM,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            barcode,
                            style: AppTheme.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.moduleMagazine.withOpacity(0.1),
                              borderRadius: AppTheme.borderRadiusSM,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.copy_rounded,
                                color: AppTheme.moduleMagazine,
                                size: 20,
                              ),
                              onPressed: () => _copyToClipboard(barcode),
                              tooltip: 'Copy barcode',
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
}
