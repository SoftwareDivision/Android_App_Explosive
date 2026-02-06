import 'package:explosive_android_app/MagzineLoad/MagzineL1Scan.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:explosive_android_app/Database/db_handler.dart';

class MagzineLoadIndex extends StatefulWidget {
  const MagzineLoadIndex({super.key});

  @override
  State<MagzineLoadIndex> createState() => _MagzineLoadIndexState();
}

class _MagzineLoadIndexState extends State<MagzineLoadIndex> {
  final TextEditingController _magazineController = TextEditingController();

  // Focus nodes for managing focus
  final FocusNode _magazineFocusNode = FocusNode();

  // State variables to hold fetched data and loading status
  List<Map<String, dynamic>> _loadingSheets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _loadingNumbers = [];
  String? _selectedLoadingNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_magazineFocusNode);
    });
  }

  @override
  void dispose() {
    // Clean up the controllers and focus nodes when the widget is disposed
    _magazineController.dispose();
    _magazineFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchLoadingNumbers() async {
    try {
      final magazineNo = _magazineController.text.trim();
      if (magazineNo.isEmpty) {
        setState(() {
          _errorMessage = 'Please scan both Magazine Number.';
          _loadingNumbers = [];
        });
        return;
      }
      final data = await DBHandler.fetchIncompleteLoadingSheets();
      setState(() {
        _loadingNumbers = data
            .where((e) =>
                e['typeoofdispatc'] == 'ML' && e['magzine'] == magazineNo)
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

    final magazineNo = _magazineController.text.trim();
    final loadingSheetNo = _selectedLoadingNumber;

    if (magazineNo.isEmpty || loadingSheetNo == null) {
      setState(() {
        _errorMessage =
            'Please scan both Magazine Number and Loading Sheet Number.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch loading sheets based on scanned magazine and loading sheet numbers
      final data = await DBHandler.fetchLoadingSheetByLoadingNoAndMagazine(
          loadingSheetNo, magazineNo);
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

  // Function to handle card tap and navigate to L1BoxScanPage
  void _navigateToL1Scan(Map<String, dynamic> loadingSheetData) async {
    // Made async
    // Navigate to the L1BoxScanPage, passing the selected loading sheet data
    await Navigator.push(
      // Await the navigation
      context,
      MaterialPageRoute(
        builder: (context) => L1BoxScanPage(loadingSheetData: loadingSheetData),
      ),
    );
    // This code runs when returning from L1BoxScanPage
    _fetchLoadingSheets(); // Re-fetch data to update the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Magazine Loading'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              _magazineController.clear();
              setState(() {
                _loadingSheets = [];
                _loadingNumbers = [];
                _errorMessage = null;
              });
              FocusScope.of(context).requestFocus(_magazineFocusNode);
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
              // Input for Magazine Number
              Card(
                elevation: 2, // Add elevation for a card effect
                child: Padding(
                  padding: const EdgeInsets.all(
                      8.0), // Add some padding inside the card
                  child: TextField(
                    // Reverted to just TextField
                    controller: _magazineController,
                    focusNode: _magazineFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Scan Magazine Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) {
                      _fetchLoadingNumbers();
                    },
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),

              // Input for Loading Sheet Number
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
                                  // Check if the sheet is completed
                                  final isCompleted =
                                      sheet['complete_flag'] == 1;
                                  return Card(
                                    elevation: 2,
                                    color: isCompleted
                                        ? Colors.green[100]
                                        : null, // Highlight completed sheets
                                    child: InkWell(
                                      // Make the card tappable
                                      onTap: isCompleted
                                          ? null
                                          : () => _navigateToL1Scan(
                                              sheet), // Disable tap if completed
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
                                                'B Name: ${sheet['bname'] ?? 'N/A'}'),
                                            Text(
                                                'Product: ${sheet['product'] ?? 'N/A'}'),
                                            Text(
                                                'Cases: ${sheet['laodcases'] ?? 'N/A'}'),
                                            Text(
                                              'Status: ${isCompleted ? 'Completed' : 'Pending'}',
                                              style: TextStyle(
                                                color: isCompleted
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
