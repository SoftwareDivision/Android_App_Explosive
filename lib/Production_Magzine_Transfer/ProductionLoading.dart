import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final TextEditingController _scanController = TextEditingController();
  final TextEditingController truckController = TextEditingController();
  final FocusNode _truckFocusNode = FocusNode();
  final FocusNode _scanFocusNode = FocusNode();
  final Set<String> _uniqueScanSet = {};
  final FlutterTts flutterTts = FlutterTts();
  bool _hasUnsavedChanges = false;
  late AudioPlayer _audioPlayer;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initTTS();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _truckFocusNode.requestFocus();
    });
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.lowLatency);
    await _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
  }

  Future<void> _initTTS() async {
    try {
      await flutterTts.setLanguage("hi-IN");
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    truckController.dispose();
    _truckFocusNode.dispose();
    _scanFocusNode.dispose();
    _audioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _vibrateOnError() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
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

  Future<void> _addScannedData() async {
    final scanText = _scanController.text.trim();

    if (scanText.isEmpty) {
      _clearScanFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please scan a barcode!',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (scanText.length != 27) {
      _clearScanFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid barcode length!',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_uniqueScanSet.contains(scanText)) {
      setState(() {
        _uniqueScanSet.add(scanText);
      });
      _hasUnsavedChanges = true;
      _clearScanFieldAndSetFocus();
      await _playSound('music/goodread.wav');
      await _announceScannedCount(); // Call TTS before clearing field
    } else {
      _clearScanFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode "$scanText" already scanned!',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper method to clear scan field and set focus - consistent approach
  void _clearScanFieldAndSetFocus() {
    _scanController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scanFocusNode.canRequestFocus) {
        _scanFocusNode.requestFocus();
      }
    });
  }

  // Helper method to clear truck field and set focus - consistent approach
  void _clearTruckFieldAndSetFocus() {
    truckController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _truckFocusNode.canRequestFocus) {
        _truckFocusNode.requestFocus();
      }
    });
  }

  Future<void> _speakTTS(String text) async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(text);
      debugPrint('TTS spoken: $text');
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> _announceScannedCount() async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(_uniqueScanSet.length.toString());
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<bool> _onWillPop() async {
    // Show warning if there are any scanned items, regardless of _hasUnsavedChanges flag
    if (_uniqueScanSet.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Scanned Items?'),
          content: const Text(
              'You have scanned barcodes that will be lost. Do you want to leave without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }

    // If no scanned items, allow pop without warning
    return true;
  }

  Future<void> _saveData() async {
    final truckNo = truckController.text.trim();

    if (truckNo.isEmpty) {
      GFToast.showToast(
        'Please enter a truck number!',
        context,
        toastPosition: GFToastPosition.BOTTOM,
        textStyle: const TextStyle(fontSize: 16, color: Colors.white),
        backgroundColor: Colors.red,
      );
      return;
    }

    if (truckNo.length < 6 || truckNo.length > 10) {
      _vibrateOnError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Truck number must be between 6 and 10 characters!',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if there are any scanned barcodes to save
    if (_uniqueScanSet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please scan at least one barcode before saving!',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final transId = 'LOADING_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Ensure database is initialized
      final db = await DBHandler.getDatabase();
      if (db == null) {
        throw Exception('Database not initialized');
      }

      // Insert main transfer and get ID
      final transferId =
          await DBHandler.insertTransfer(transId, truckNo.toUpperCase());

      // Insert all scanned barcodes linked to this transfer
      int savedCount = 0;
      for (final barcode in _uniqueScanSet) {
        try {
          await DBHandler.insertL1Barcode(transferId, barcode);
          savedCount++;
        } catch (e) {
          debugPrint('Error saving barcode $barcode: $e');
          // Continue with other barcodes even if one fails
        }
      }

      setState(() {
        _uniqueScanSet.clear();
        _hasUnsavedChanges = false; // Reset the flag after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data saved successfully! Saved $savedCount of ${_uniqueScanSet.length} barcodes.',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _speakTTS("Saved successfully");
      // After saving, clear truck field and set focus back to it
      _clearTruckFieldAndSetFocus();
    } catch (e) {
      debugPrint('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving data: ${e.toString().contains("Database not initialized") ? "Database not ready. Please try again." : e}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUnloadingDialog(BuildContext context) {
    final TextEditingController unloadController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Unloading - Remove Loded Box",
            style: TextStyle(color: Colors.black, fontSize: 14)),
        content: TextField(
          controller: unloadController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Scan L1Barcode",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _removeBarcode(unloadController.text.trim());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _removeBarcode(String barcode) {
    setState(() {
      _uniqueScanSet.remove(barcode);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Barcode "$barcode" removed!',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: GFAppBar(
          title: const Text(
            'Loading Truck-Magzine',
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
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Card(
                    elevation: 6,
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Truck No",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: truckController,
                            focusNode: _truckFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Enter Truck No',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]')),
                            ],
                            onChanged: (value) {
                              final cleanValue = value.replaceAll(' ', '');
                              if (cleanValue != value) {
                                truckController.value =
                                    truckController.value.copyWith(
                                  text: cleanValue,
                                  selection: TextSelection.collapsed(
                                      offset: cleanValue.length),
                                );
                              }
                            },
                            onSubmitted: (value) {
                              // After entering truck number, move focus to scan field
                              if (value.trim().isNotEmpty &&
                                  value.trim().length >= 6 &&
                                  value.trim().length <= 10) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted &&
                                      _scanFocusNode.canRequestFocus) {
                                    _scanFocusNode.requestFocus();
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Scan L1Barcode",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _scanController,
                            focusNode: _scanFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Scan L1Barcode',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (_) => _addScannedData(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      elevation: 6,
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Scanned Items",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    GFBadge(
                                      size: GFSize.LARGE,
                                      color: GFColors.PRIMARY,
                                      child: Text("${_uniqueScanSet.length}"),
                                    ),
                                    const SizedBox(width: 10),
                                    GFButton(
                                      onPressed: () =>
                                          _showUnloadingDialog(context),
                                      text: "Unloading",
                                      size: GFSize.SMALL,
                                      color: GFColors.SECONDARY,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columnSpacing: 2,
                                  columns: const [
                                    DataColumn(label: Text('Scan Data'))
                                  ],
                                  rows: (_uniqueScanSet.toList()..sort())
                                      .map(
                                        (scan) => DataRow(
                                          cells: [
                                            DataCell(Text(scan)),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Data',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
