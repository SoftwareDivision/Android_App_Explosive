import 'package:audioplayers/audioplayers.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DirectL1ScanPage extends StatefulWidget {
  final Map<String, dynamic> loadingSheetData;

  const DirectL1ScanPage({Key? key, required this.loadingSheetData})
      : super(key: key);

  @override
  _DirectL1ScanPageState createState() => _DirectL1ScanPageState();
}

class _DirectL1ScanPageState extends State<DirectL1ScanPage> {
  final FlutterTts flutterTts = FlutterTts();
  late AudioPlayer _audioPlayer;
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  List<String> _scannedBarcodes = [];
  int _scannedCount = 0;
  int _targetCases = 0;
  bool _hasUnsavedChanges = false;
  String bid = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _initTTS();
    _loadInitialData();
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
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setVolume(0.5);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _loadInitialData() async {
    _targetCases =
        int.tryParse(widget.loadingSheetData['laodcases']?.toString() ?? '0') ??
            0;
    bid = widget.loadingSheetData['bid'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setFocusOnScanField();
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocusNode.dispose();
    _audioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  // Helper method to set focus on scan field - consistent approach
  void _setFocusOnScanField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scanFocusNode.canRequestFocus) {
        _scanFocusNode.requestFocus();
      }
    });
  }

  // Helper method to clear text field and set focus - consistent approach
  void _clearTextFieldAndSetFocus() {
    _scanController.clear();
    _setFocusOnScanField();
  }

  Future<void> _vibrateOnError() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _announceScannedCount() async {
    try {
      await flutterTts.stop();
      await flutterTts.speak(_scannedCount.toString());
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
      await _vibrateOnError(); // Fallback to vibration if audio fails
    }
  }

  Future<void> _handleScan(String barcode) async {
    if (_scannedCount == _targetCases) {
      _clearTextFieldAndSetFocus();
      await _playSound('music/goodread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan complete! All cases scanned.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.length != 27) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcode must be exactly 27 characters long.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!trimmedBarcode.contains(bid)) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcode does not match the Brand ID.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (trimmedBarcode.isNotEmpty &&
        !_scannedBarcodes.contains(trimmedBarcode)) {
      setState(() {
        _scannedBarcodes.add(trimmedBarcode);
        _scannedBarcodes.sort((a, b) => a.compareTo(b));
        _scannedCount = _scannedBarcodes.length;
        _hasUnsavedChanges = true;
      });
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
    } else if (_scannedBarcodes.contains(trimmedBarcode)) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode "$trimmedBarcode" already scanned.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeBarcode(String barcode) {
    setState(() {
      _scannedBarcodes.remove(barcode);
      _scannedCount = _scannedBarcodes.length;
      _hasUnsavedChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved scanned barcodes. Do you want to discard them and leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final loadingSheetId = widget.loadingSheetData['id'];
      if (loadingSheetId == null) {
        throw Exception('Loading Sheet ID not found');
      }

      if (_scannedCount != _targetCases) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please scan $_targetCases cases before saving. Currently scanned: $_scannedCount'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Save to database - Fixed to use the correct function for direct dispatch loading
      for (final barcode in _scannedBarcodes) {
        await DBHandler.insertLoadingCase(loadingSheetId, barcode);
      }

      await DBHandler.updateLoadingSheetCompleteFlag(loadingSheetId, 1);

      await _playSound('music/success.wav'); // Add success sound

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _scannedBarcodes.clear();
        _scannedCount = 0;
        _hasUnsavedChanges = false;
      });

      Navigator.pop(context);
    } catch (e) {
      await _playSound('music/error.wav'); // Add error sound
      debugPrint('Error saving loading: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving loading: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadingSheetId = widget.loadingSheetData['id'];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: GFAppBar(
          title: Text(
            'Scan L1 Boxes for Loading Sheet ${loadingSheetId ?? 'N/A'}',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.purple[800],
          iconTheme: const IconThemeData(color: Colors.white),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Truck No: ${widget.loadingSheetData['truckno'] ?? 'N/A'}'),
                          Text(
                              'T Name: ${widget.loadingSheetData['tname'] ?? 'N/A'}'),
                          Text(
                              'Brand Id: ${widget.loadingSheetData['bid'] ?? 'N/A'} (Brand Name: ${widget.loadingSheetData['bname'] ?? 'N/A'})'),
                          Text(
                              'Product: ${widget.loadingSheetData['product'] ?? 'N/A'}'),
                          Text('Target Cases: $_targetCases'),
                          Text('Scanned Cases: $_scannedCount'),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _scanController,
                        focusNode: _scanFocusNode,
                        inputFormatters: [LengthLimitingTextInputFormatter(27)],
                        decoration: InputDecoration(
                          hintText: 'Scan or enter L1 Box Barcode (27 digits)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              // TODO: Implement QR code scanning
                            },
                          ),
                        ),
                        onSubmitted: _handleScan,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _scannedBarcodes.isEmpty
                            ? const Center(
                                child: Text('No barcodes scanned yet'))
                            : ListView.builder(
                                itemCount: _scannedBarcodes.length,
                                itemBuilder: (context, index) {
                                  final barcode = _scannedBarcodes[index];
                                  return ListTile(
                                    title: Text(barcode),
                                    trailing: IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red),
                                      onPressed: () => _removeBarcode(barcode),
                                    ),
                                    dense: true,
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _scannedCount == _targetCases && !_isSaving
                      ? _handleSave
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: _scannedCount == _targetCases
                        ? Colors.green
                        : Colors.grey,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, size: 24),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save ($_scannedCount/$_targetCases)',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
