import 'package:flutter/material.dart';
import '../Database/db_handler.dart';

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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading barcodes: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcodes: ${widget.loadingSheetNo}'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadBarcodes();
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
                    // Summary Card
                    Card(
                      margin: const EdgeInsets.all(12.0),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[700]!.withOpacity(0.9),
                              Colors.blue[700]!.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Barcodes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_filteredBarcodes.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Search Bar
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search barcodes...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterBarcodes('');
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
                          onChanged: _filterBarcodes,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Barcodes List
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(12.0),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Header
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
                                    'Barcode List',
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
                                      '${_filteredBarcodes.length} Items',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Barcode items
                            Expanded(
                              child: _filteredBarcodes.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No barcodes found for this loading sheet.',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _filteredBarcodes.length,
                                      itemBuilder: (context, index) {
                                        final barcodeData =
                                            _filteredBarcodes[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          child: ListTile(
                                            title: Text(
                                              barcodeData['l1barcode'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.copy),
                                              onPressed: () {
                                                // TODO: Implement copy to clipboard functionality
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Copy functionality coming soon!'),
                                                    backgroundColor:
                                                        Colors.blue,
                                                  ),
                                                );
                                              },
                                            ),
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
}
