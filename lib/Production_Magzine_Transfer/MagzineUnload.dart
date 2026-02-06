import 'package:explosive_android_app/Production_Magzine_Transfer/MagzineUnloadBoxScan.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../Database/db_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class UnloadingOperation extends StatefulWidget {
  const UnloadingOperation({Key? key}) : super(key: key);

  @override
  _UnloadingOperationState createState() => _UnloadingOperationState();
}

class _UnloadingOperationState extends State<UnloadingOperation> {
  String? _scannedMagazine;
  List<Map<String, dynamic>> _magazineDataList = [];
  bool _isLoading = false;
  final TextEditingController _magazineController = TextEditingController();
  final FocusNode _magazineFocusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Set focus to magazine TextField after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_magazineFocusNode);
    });
  }

  @override
  void dispose() {
    _magazineController.dispose();
    _magazineFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _scanMagazine(String magazineCode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DBHandler.getDatabase();
      if (db != null) {
        final data = await db.query(
          'magzinestocktransfer',
          where: 'magazine_name = ? AND read_flag = 0',
          whereArgs: [magazineCode.toUpperCase()],
        );

        setState(() {
          if (data.isNotEmpty) {
            _magazineDataList = data;
            _scannedMagazine = magazineCode;
          } else {
            _magazineDataList = [];
            _scannedMagazine = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No data found for magazine: $magazineCode'),
                backgroundColor: Colors.red,
              ),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _magazineDataList = [];
        _scannedMagazine = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading magazine data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to clear magazine field and set focus - consistent approach
  void _clearMagazineFieldAndSetFocus() {
    _magazineController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _magazineFocusNode.requestFocus();
    });
  }

  // New method to reset the scan
  void _resetScan() {
    setState(() {
      _scannedMagazine = null;
      _magazineDataList = [];
    });
    _clearMagazineFieldAndSetFocus();
  }

  Future<void> _playSound(String assetPath) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(assetPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Unloading Operation',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blue[800],
        // Add reset button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetScan,
            tooltip: 'Reset Scan',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pexels-hngstrm-1939485.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                // Magazine Scanning Section
                Card(
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _magazineController,
                          focusNode: _magazineFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Scan Magazine',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () async {
                                // Implement actual scanner integration here
                                final code = _magazineController.text;
                                if (code.isNotEmpty) {
                                  await _scanMagazine(code);
                                  _magazineController.clear();
                                }
                              },
                            ),
                          ),
                          onSubmitted: (value) async {
                            if (value.isNotEmpty) {
                              await _scanMagazine(value);
                              _magazineController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_magazineDataList.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  // Show count of matching records
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Found ${_magazineDataList.length} unloading record(s) for magazine: $_scannedMagazine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Magazine Details Cards - one for each record
                  ..._magazineDataList.map(
                    (magazineData) => GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoxScanningPage(
                              magazineData: magazineData,
                              scannedBoxes: [], // Pass empty list since we're removing local box scanning
                            ),
                          ),
                        );

                        // Reset all data when returning from BoxScanningPage
                        setState(() {
                          _magazineDataList = [];
                          _scannedMagazine = null;
                        });

                        // Set focus back to magazine scanner
                        _clearMagazineFieldAndSetFocus();
                      },
                      child: Card(
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transfer ID: ${magazineData["transfer_id"]}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  'Plant: ${magazineData["plant"]} (Code: ${magazineData["plantcode"] ?? 'N/A'})'),
                              Text(
                                  'Brand: ${magazineData["bname"] ?? 'N/A'} (ID: ${magazineData["bid"] ?? 'N/A'})'),
                              Text(
                                  'Product Size: ${magazineData["productsize"] ?? 'N/A'} (Code: ${magazineData["sizecode"] ?? 'N/A'})'),
                              Text('Cases: ${magazineData["case_quantity"]}'),
                              Text('Total Weight: ${magazineData["total_wt"]}'),
                              Text('Truck No: ${magazineData["truck_no"]}'),
                              const SizedBox(height: 8),
                              // Add a visual indicator that this is selectable
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
