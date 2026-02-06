import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../Database/db_handler.dart';
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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        GFToast.showToast(
          'Error loading data: $e',
          context,
          toastPosition: GFToastPosition.BOTTOM,
          textStyle: const TextStyle(fontSize: 16, color: Colors.white),
          backgroundColor: GFColors.DANGER,
        );
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

    // Apply dispatch type filter
    if (_selectedDispatchType != null) {
      filtered = filtered
          .where((data) => data['typeoofdispatc'] == _selectedDispatchType)
          .toList();
    }

    // Apply search filter
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Loading Sheet Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _selectedDispatchType = null;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadLoadingData();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pexels-hngstrm-1939485.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Search Bar
                    Card(
                      margin: const EdgeInsets.all(12.0),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search by Loading No, Truck, Brand, or Product...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterBySearch('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: _filterBySearch,
                        ),
                      ),
                    ),
                    // Filter Chips
                    if (_dispatchTypeList.isNotEmpty)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            FilterChip(
                              label: const Text('All Types'),
                              selected: _selectedDispatchType == null,
                              onSelected: (selected) {
                                _filterByDispatchType(null);
                              },
                              selectedColor: Colors.blue[300],
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 8),
                            ..._dispatchTypeList.map(
                              (type) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(type),
                                  selected: _selectedDispatchType == type,
                                  onSelected: (selected) {
                                    _filterByDispatchType(type);
                                  },
                                  selectedColor: Colors.blue[300],
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          _buildSummaryCard('Total Sheets',
                              '${_filteredData.length}', Colors.blue[700]!),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                              'Pending', '$_pendingCount', Colors.orange[700]!),
                          const SizedBox(width: 12),
                          _buildSummaryCard('Completed', '$_completedCount',
                              Colors.green[700]!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Data Display Card List
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(12.0),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Header with count
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[800],
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Loading Sheet Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_filteredData.length} Records',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // List of data
                            Expanded(
                              child: _filteredData.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No loading sheets found',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _filteredData.length,
                                      itemBuilder: (context, index) {
                                        final data = _filteredData[index];
                                        final loadingSheetId =
                                            data['id'] as int?;
                                        final loadingSheetNo =
                                            data['loadingno'] as String?;
                                        final completeFlag =
                                            data['complete_flag'] as int? ?? 0;

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          child: ListTile(
                                            onTap: () {
                                              if (loadingSheetId != null &&
                                                  loadingSheetNo != null) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoadingSheetDetailsPage(
                                                      loadingSheetId:
                                                          loadingSheetId,
                                                      loadingSheetNo:
                                                          loadingSheetNo,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Loading Sheet ID or Number is missing.'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                            },
                                            title: Text(
                                              'LoadSheet: ${loadingSheetNo ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                _buildDataRow('Truck No',
                                                    data['truckno'] ?? 'N/A'),
                                                _buildDataRow('T Name',
                                                    data['tname'] ?? 'N/A'),
                                                _buildDataRow('Brand',
                                                    '${data['bname'] ?? 'N/A'} (ID: ${data['bid'] ?? 'N/A'})'),
                                                _buildDataRow('Product',
                                                    '${data['product'] ?? 'N/A'} (${data['pcode'] ?? 'N/A'})'),
                                                _buildDataRow(
                                                    'Dispatch Type',
                                                    data['typeoofdispatc'] ??
                                                        'N/A'),
                                                _buildDataRow('Magazine',
                                                    data['magzine'] ?? 'N/A'),
                                                _buildDataRow('Load Wt',
                                                    '${data['loadwt'] ?? 'N/A'} kg'),
                                                _buildDataRow(
                                                    'Load Cases',
                                                    data['laodcases']
                                                            ?.toString() ??
                                                        'N/A'),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Status: ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: completeFlag == 1
                                                            ? Colors.green
                                                            : Colors.orange,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        completeFlag == 1
                                                            ? 'Completed'
                                                            : 'Pending',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
