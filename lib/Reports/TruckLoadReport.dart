import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../Database/db_handler.dart';

class TruckLoadReport extends StatefulWidget {
  const TruckLoadReport({super.key});

  @override
  State<TruckLoadReport> createState() => _TruckLoadReportState();
}

class _TruckLoadReportState extends State<TruckLoadReport> {
  List<Map<String, dynamic>> _transferData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Truck Load Report',
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
              });
              _loadTransferData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
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
                                'Search by Truck No, Barcode, or Transfer ID...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterData('');
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
                          onChanged: _filterData,
                        ),
                      ),
                    ),
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          _buildSummaryCard('Total Boxes',
                              '${_filteredData.length}', Colors.blue[700]!),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                              'Unique Trucks',
                              '${_filteredData.map((e) => e['truck_no']).toSet().length}',
                              Colors.green[700]!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Data Table Card
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
                                    'Loading Details',
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
                            // Data table
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor:
                                        MaterialStateColor.resolveWith(
                                      (states) => Colors.blue[100]!,
                                    ),
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Truck No')),
                                      DataColumn(label: Text('L1 Barcode')),
                                      DataColumn(label: Text('Transfer ID')),
                                    ],
                                    rows: _filteredData.map(
                                      (data) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                    data['truck_no'] ?? 'N/A'),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                    data['l1barcode'] ?? 'N/A'),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                    data['trans_id'] ?? 'N/A'),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
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
                  fontSize: 24,
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
}
