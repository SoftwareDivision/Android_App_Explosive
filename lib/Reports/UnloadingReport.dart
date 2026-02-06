import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../Database/db_handler.dart';

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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        GFToast.showToast(
          'Error loading data: $e',
          context,
          toastPosition: GFToastPosition.BOTTOM,
          textStyle: const TextStyle(fontSize: 16, color: Colors.white),
          backgroundColor: Colors.red,
        );
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

    // Apply magazine filter
    if (_selectedMagazine != null) {
      filtered = filtered
          .where((item) => item['magazine_name'] == _selectedMagazine)
          .toList();
    }

    // Apply search filter
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Unloading Report',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _selectedMagazine = null;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadUnloadingData();
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
                                'Search by Transfer ID, Plant, Truck, or Brand...',
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
                    if (_magazineList.isNotEmpty)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            FilterChip(
                              label: const Text('All Magazines'),
                              selected: _selectedMagazine == null,
                              onSelected: (selected) {
                                _filterByMagazine(null);
                              },
                              selectedColor: Colors.blue[300],
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(width: 8),
                            ..._magazineList.map(
                              (magazine) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(magazine),
                                  selected: _selectedMagazine == magazine,
                                  onSelected: (selected) {
                                    _filterByMagazine(magazine);
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
                          _buildSummaryCard('Total Records',
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
                    // Data Display Card
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
                                    'Unloading Details',
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
                                        'No unloading records found',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _filteredData.length,
                                      itemBuilder: (context, index) {
                                        final data = _filteredData[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          child: ExpansionTile(
                                            title: Text(
                                              'Transfer ID: ${data['transfer_id'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              'Magazine: ${data['magazine_name'] ?? 'N/A'}',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildDataRow('Plant',
                                                        '${data['plant'] ?? 'N/A'} - ${data['plantcode'] ?? 'N/A'}'),
                                                    _buildDataRow(
                                                        'Magazine',
                                                        data['magazine_name'] ??
                                                            'N/A'),
                                                    _buildDataRow(
                                                        'Cases',
                                                        data['case_quantity']
                                                                ?.toString() ??
                                                            '0'),
                                                    _buildDataRow('Weight',
                                                        '${data['total_wt']?.toString() ?? '0.0'} kg'),
                                                    _buildDataRow(
                                                        'Truck No',
                                                        data['truck_no'] ??
                                                            'N/A'),
                                                    _buildDataRow('Brand',
                                                        '${data['bname'] ?? 'N/A'} (ID: ${data['bid'] ?? 'N/A'})'),
                                                    _buildDataRow(
                                                        'Product Size',
                                                        '${data['productsize'] ?? 'N/A'} (Code: ${data['sizecode'] ?? 'N/A'})'),
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Status: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                data['read_flag'] == 1
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .orange,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Text(
                                                            data['read_flag'] ==
                                                                    1
                                                                ? 'Completed'
                                                                : 'Pending',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
