import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class BoxScanningPage extends StatefulWidget {
  final Map<String, dynamic> magazineData;
  final List<String> scannedBoxes;

  const BoxScanningPage({
    Key? key,
    required this.magazineData,
    required this.scannedBoxes,
  }) : super(key: key);

  @override
  _BoxScanningPageState createState() => _BoxScanningPageState();
}

class _BoxScanningPageState extends State<BoxScanningPage> {
  final TextEditingController _boxController = TextEditingController();
  final FocusNode _boxFocusNode = FocusNode();
  late AudioPlayer _audioPlayer;
  List<String> _scannedBoxes = [];
  bool _isLoading = false;
  List<String> _validBarcodes = [];
  final FlutterTts flutterTts = FlutterTts();
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initTTS();
    _scannedBoxes = List.from(widget.scannedBoxes);
    _loadValidBarcodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_boxFocusNode);
    });
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop) // Stop previous playback
      ..setPlayerMode(PlayerMode.lowLatency);

    // Set global audio context for proper focus handling
    await _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
  }

  @override
  void dispose() {
    _boxController.dispose();
    _boxFocusNode.dispose();
    _audioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadValidBarcodes() async {
    setState(() => _isLoading = true);
    try {
      final db = await DBHandler.getDatabase();
      final List<Map<String, dynamic>> result = await db!.query(
        'productiontomagazine_loading',
        columns: ['l1barcode'],
        where: 'flag = ?',
        whereArgs: [0],
      );
      setState(() {
        _validBarcodes =
            result.map((row) => row['l1barcode'] as String).toList();
      });
    } catch (e) {
      _vibrateOnError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading valid barcodes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _vibrateOnError() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  Future<void> _announceScannedCount() async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(_scannedBoxes.length.toString());
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      _vibrateOnError();
    }
  }

  // Helper method to clear box field and set focus - consistent approach
  void _clearBoxFieldAndSetFocus() {
    _boxController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boxFocusNode.requestFocus();
    });
  }

  Future<void> _scanBox(String boxCode) async {
    if (boxCode.isEmpty) {
      _clearBoxFieldAndSetFocus();
      return;
    }

    final String? brandId = widget.magazineData['bid'];

    // Brand ID check
    if (brandId != null && !boxCode.contains(brandId)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid box: Does not contain the correct Brand ID.',
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Valid barcode check
    if (!_validBarcodes.contains(boxCode)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid box code or already loaded',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final totalCases = widget.magazineData['case_quantity'] ?? 0;
    if (_scannedBoxes.length >= totalCases) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All boxes have been scanned'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (_scannedBoxes.contains(boxCode)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Box already scanned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _scannedBoxes.add(boxCode);
    });

    _clearBoxFieldAndSetFocus();
    await _playSound('music/goodread.wav');

    if (_scannedBoxes.length == totalCases) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('music/completdscan.m4a'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All boxes have been scanned successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        debugPrint('Completion sound error: $e');
      }
    }

    await _announceScannedCount();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }

        if (_scannedBoxes.isEmpty) {
          Navigator.of(context).pop();
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Exit'),
            content: const Text(
                'Are you sure you want to go back? All scanned box data will be cleared.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Go Back'),
              ),
            ],
          ),
        );

        if (shouldPop == true) {
          _scannedBoxes.clear();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: GFAppBar(
          title: const Text(
            'Box Scanning',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.blue[800],
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
                  // Magazine Details Card
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Magazine: ${widget.magazineData['magazine_name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              'Brand: ${widget.magazineData['bname'] ?? 'N/A'} (ID: ${widget.magazineData['bid'] ?? 'N/A'})'),
                          Text(
                              'Product Size: ${widget.magazineData['productsize'] ?? 'N/A'} (Code: ${widget.magazineData['sizecode'] ?? 'N/A'})'),
                          Text(
                              'Cases: ${widget.magazineData['case_quantity']}'),
                          Text(
                              'Total Weight: ${widget.magazineData['total_wt']}'),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: widget.magazineData['case_quantity'] > 0
                                ? _scannedBoxes.length /
                                    widget.magazineData['case_quantity']
                                : 0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[800]!),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scanned: ${_scannedBoxes.length} / ${widget.magazineData['case_quantity']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Box Scanning Card
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _boxController,
                            focusNode: _boxFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Scan Box',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: () async {
                                  final code = _boxController.text;
                                  if (code.isNotEmpty) {
                                    await _scanBox(code);
                                  } else {
                                    _clearBoxFieldAndSetFocus();
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) async {
                              if (value.isEmpty) {
                                _clearBoxFieldAndSetFocus();
                                return;
                              }

                              if (value.length != 27) {
                                await _playSound('music/badread.wav');
                                _vibrateOnError();
                                GFToast.showToast(
                                  'Box code must be 27 digits',
                                  context,
                                  toastPosition: GFToastPosition.BOTTOM,
                                  backgroundColor: Colors.orange,
                                );
                                _clearBoxFieldAndSetFocus();
                                return;
                              }

                              await _scanBox(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Scanned Boxes List Card
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scanned Boxes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _scannedBoxes.length,
                            itemBuilder: (context, index) {
                              final sortedBoxes =
                                  List<String>.from(_scannedBoxes)..sort();
                              return ListTile(
                                title: Text(sortedBoxes[index]),
                                leading: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 24),
                                dense: true,
                                visualDensity:
                                    const VisualDensity(vertical: -4),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 0),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GFButton(
            onPressed: () async {
              final totalCases = widget.magazineData['case_quantity'] ?? 0;
              if (_scannedBoxes.length < totalCases) {
                GFToast.showToast(
                  'Please scan all boxes before saving',
                  context,
                  toastPosition: GFToastPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                );
                return;
              }

              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Save'),
                  content: const Text(
                      'Are you sure you want to save the scanned boxes?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              setState(() => _isLoading = true);
              try {
                // Get the magazine transfer ID by querying the database
                final db = await DBHandler.getDatabase();
                final result = await db!.query(
                  'magzinestocktransfer',
                  columns: ['id'],
                  where:
                      'transfer_id = ? AND magazine_name = ?  AND plant =? AND bid = ? AND sizecode = ?',
                  whereArgs: [
                    widget.magazineData['transfer_id'],
                    widget.magazineData['magazine_name'],
                    widget.magazineData['plant'],
                    widget.magazineData['bid'],
                    widget.magazineData['sizecode'],
                  ],
                  limit: 1,
                );

                if (result.isNotEmpty) {
                  final magazineTransferId = result.first['id'] as int;

                  // Save each scanned box
                  for (String barcode in _scannedBoxes) {
                    await DBHandler.insertScannedBox(
                        magazineTransferId, barcode);

                    await db.update(
                      'productiontomagazine_loading',
                      {'flag': 1},
                      where: 'l1barcode = ?',
                      whereArgs: [barcode],
                    );
                  }

                  // Update read_flag to 1
                  await db.update(
                    'magzinestocktransfer',
                    {'read_flag': 1},
                    where: 'id = ?',
                    whereArgs: [magazineTransferId],
                  );

                  // Clear the scanned boxes list
                  setState(() {
                    _scannedBoxes.clear();
                  });

                  GFToast.showToast(
                    'Boxes saved successfully!',
                    context,
                    toastPosition: GFToastPosition.BOTTOM,
                    backgroundColor: Colors.green,
                  );

                  // Navigate back and trigger parent state reset
                  Navigator.pop(context, null);
                } else {
                  GFToast.showToast(
                    'Magazine transfer record not found',
                    context,
                    toastPosition: GFToastPosition.BOTTOM,
                    backgroundColor: Colors.red,
                  );
                }
              } catch (e) {
                GFToast.showToast(
                  'Error saving scanned boxes: $e',
                  context,
                  toastPosition: GFToastPosition.BOTTOM,
                  backgroundColor: Colors.red,
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            text: 'Save',
            size: GFSize.LARGE,
            fullWidthButton: true,
            color: Colors.blue[800]!,
          ),
        ),
      ),
    );
  }
}
