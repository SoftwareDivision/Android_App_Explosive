import 'dart:convert';

import 'package:explosive_android_app/DirectDispatchLoad/DirectL1Scan.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:explosive_android_app/Database/db_handler.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Direct Dispatch Loading'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              _loadingSheetController.clear();
              setState(() {
                _loadingSheets = [];
                _errorMessage = null;
              });
              FocusScope.of(context).requestFocus(_loadingSheetFocusNode);
            },
          ),
        ],
      ),
      body: Container(
        // Wrap the body in a Container to add a background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/pexels-hngstrm-1939485.jpg'), // Your background image
            fit: BoxFit.cover, // Cover the entire background
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input for Loading Sheet Number (Dropdown)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLoadingNumber,
                    decoration: InputDecoration(
                      hintText: 'Select Loading Sheet Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _loadingNumbers.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
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
                ),
              ),
              const SizedBox(height: 1),

              // Display Loading Sheets or loading/error state
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : _loadingSheets.isEmpty
                            ? const Center(
                                child: Text('No loading sheets found.'),
                              )
                            : ListView.builder(
                                itemCount: _loadingSheets.length,
                                itemBuilder: (context, index) {
                                  final sheet = _loadingSheets[index];
                                  // Display loading sheet details here
                                  return InkWell(
                                    // Wrap with InkWell for tap detection and visual feedback
                                    onTap: () {
                                      // Navigate to DirectL1ScanPage and pass the selected sheet data
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DirectL1ScanPage(
                                                  loadingSheetData: sheet),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Loading No: ${sheet['loadingno'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                'Indent No: ${sheet['indentno'] ?? 'N/A'}'),
                                            Text(
                                                'Truck No: ${sheet['truckno'] ?? 'N/A'}'),
                                            Text(
                                                'T Name: ${sheet['tname'] ?? 'N/A'}'),
                                            Text(
                                                'B Name: ${sheet['bname'] ?? 'N/A'}-${sheet['bid'] ?? 'N/A'}'),
                                            Text(
                                                'Product: ${sheet['product'] ?? 'N/A'}-${sheet['pcode'] ?? 'N/A'}'),
                                            Text(
                                                'Load Qnty: ${sheet['laodcases'] ?? 'N/A'}'),
                                            // Add other relevant fields
                                          ],
                                        ),
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
    );
  }
}
