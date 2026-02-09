import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSaving = false;
  late AudioPlayer _audioPlayer;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  // ============ BUSINESS LOGIC (PRESERVED) ============
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
      _showSnackBar('Please scan a barcode!', AppTheme.error);
      return;
    }

    if (scanText.length != 27) {
      _clearScanFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Invalid barcode length!', AppTheme.error);
      return;
    }

    if (!_uniqueScanSet.contains(scanText)) {
      setState(() {
        _uniqueScanSet.add(scanText);
      });
      _hasUnsavedChanges = true;
      _clearScanFieldAndSetFocus();
      await _playSound('music/goodread.wav');
      await _announceScannedCount();
    } else {
      _clearScanFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Barcode "$scanText" already scanned!', AppTheme.warning);
    }
  }

  void _clearScanFieldAndSetFocus() {
    _scanController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scanFocusNode.canRequestFocus) {
        _scanFocusNode.requestFocus();
      }
    });
  }

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
    if (_uniqueScanSet.isNotEmpty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLG),
          title: Row(
            children: [
              Container(
                padding: AppTheme.paddingSM,
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface,
                  borderRadius: AppTheme.borderRadiusSM,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.warning),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              const Text('Discard Scanned Items?'),
            ],
          ),
          content: const Text(
              'You have scanned barcodes that will be lost. Do you want to leave without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  Future<void> _saveData() async {
    if (_isSaving) return;

    final truckNo = truckController.text.trim();

    if (truckNo.isEmpty) {
      _showSnackBar('Please enter a truck number!', AppTheme.error);
      return;
    }

    if (truckNo.length < 6 || truckNo.length > 10) {
      _vibrateOnError();
      _showSnackBar(
          'Truck number must be between 6 and 10 characters!', AppTheme.error);
      return;
    }

    if (_uniqueScanSet.isEmpty) {
      _showSnackBar(
          'Please scan at least one barcode before saving!', AppTheme.warning);
      return;
    }

    setState(() => _isSaving = true);

    final transId = 'LOADING_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final db = await DBHandler.getDatabase();
      if (db == null) {
        throw Exception('Database not initialized');
      }

      final transferId =
          await DBHandler.insertTransfer(transId, truckNo.toUpperCase());

      int savedCount = 0;
      for (final barcode in _uniqueScanSet) {
        try {
          await DBHandler.insertL1Barcode(transferId, barcode);
          savedCount++;
        } catch (e) {
          debugPrint('Error saving barcode $barcode: $e');
        }
      }

      final totalBarcodes = _uniqueScanSet.length;

      setState(() {
        _uniqueScanSet.clear();
        _hasUnsavedChanges = false;
      });

      _showSnackBar(
          'Data saved successfully! Saved $savedCount of $totalBarcodes barcodes.',
          AppTheme.success);

      await _speakTTS("Saved successfully");
      _clearTruckFieldAndSetFocus();
    } catch (e) {
      debugPrint('Error saving data: $e');
      _showSnackBar(
        'Error saving data: ${e.toString().contains("Database not initialized") ? "Database not ready. Please try again." : e}',
        AppTheme.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showUnloadingDialog(BuildContext context) {
    final TextEditingController unloadController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLG),
        title: Row(
          children: [
            Container(
              padding: AppTheme.paddingSM,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusSM,
              ),
              child: const Icon(Icons.remove_circle_outline,
                  color: AppTheme.error),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            const Text('Remove Box'),
          ],
        ),
        content: TextField(
          controller: unloadController,
          autofocus: true,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: 'Scan L1 Barcode to Remove',
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusMD,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusMD,
              borderSide: const BorderSide(color: AppTheme.error, width: 2),
            ),
          ),
          onSubmitted: (_) {
            _removeBarcode(unloadController.text.trim());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _removeBarcode(unloadController.text.trim());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeBarcode(String barcode) {
    if (barcode.isEmpty) return;

    if (_uniqueScanSet.contains(barcode)) {
      setState(() {
        _uniqueScanSet.remove(barcode);
      });
      _showSnackBar('Barcode "$barcode" removed!', AppTheme.warning);
    } else {
      _showSnackBar('Barcode "$barcode" not found!', AppTheme.error);
    }
  }
  // ============ END BUSINESS LOGIC ============

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success
                  ? Icons.check_circle
                  : color == AppTheme.warning
                      ? Icons.warning
                      : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMD),
        margin: AppTheme.paddingMD,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _uniqueScanSet.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const CustomAppBar(
          title: 'Loading Truck-Magazine',
          backgroundColor: AppTheme.moduleProduction,
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppTheme.paddingMD,
                    child: Column(
                      children: [
                        // Input Card
                        _buildInputCard(),
                        const SizedBox(height: AppTheme.spaceMD),

                        // Scanned Items List
                        SizedBox(
                          height: 300,
                          child: _buildScannedList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Save Button - fixed at bottom
                Padding(
                  padding: AppTheme.paddingMD,
                  child: _buildSaveButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Padding(
        padding: AppTheme.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Truck Number Input
            Row(
              children: [
                Icon(Icons.local_shipping,
                    size: 18, color: AppTheme.moduleProduction),
                const SizedBox(width: AppTheme.spaceSM),
                Text('Truck Number', style: AppTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
              controller: truckController,
              focusNode: _truckFocusNode,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter Truck No (6-10 characters)',
                prefixIcon: const Icon(Icons.local_shipping_outlined),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.moduleProduction, width: 2),
                ),
                contentPadding: AppTheme.paddingMD,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: (value) {
                final cleanValue = value.replaceAll(' ', '');
                if (cleanValue != value) {
                  truckController.value = truckController.value.copyWith(
                    text: cleanValue,
                    selection:
                        TextSelection.collapsed(offset: cleanValue.length),
                  );
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty &&
                    value.trim().length >= 6 &&
                    value.trim().length <= 10) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _scanFocusNode.canRequestFocus) {
                      _scanFocusNode.requestFocus();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Barcode Scan Input
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    size: 18, color: AppTheme.moduleProduction),
                const SizedBox(width: AppTheme.spaceSM),
                Text('Scan L1 Barcode', style: AppTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
              controller: _scanController,
              focusNode: _scanFocusNode,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Scan or enter barcode (27 digits)',
                prefixIcon: const Icon(Icons.document_scanner_outlined),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(AppTheme.spaceXS),
                  decoration: BoxDecoration(
                    color: AppTheme.moduleProduction.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.qr_code_scanner,
                        color: AppTheme.moduleProduction),
                    onPressed: () {
                      // TODO: Implement QR scanning
                    },
                  ),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusMD,
                  borderSide:
                      BorderSide(color: AppTheme.moduleProduction, width: 2),
                ),
                contentPadding: AppTheme.paddingMD,
              ),
              onSubmitted: (_) => _addScannedData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: AppTheme.paddingMD,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt,
                          size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: AppTheme.spaceSM),
                      Flexible(
                        child: Text(
                          'Scanned Items',
                          style: AppTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD,
                          vertical: AppTheme.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.moduleProduction.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCircle),
                        ),
                        child: Text(
                          '${_uniqueScanSet.length}',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.moduleProduction,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showUnloadingDialog(context),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _uniqueScanSet.isEmpty
                ? const EmptyState(
                    message:
                        'No barcodes scanned yet.\nScan a barcode to get started.',
                    icon: Icons.qr_code_2_rounded,
                  )
                : ListView.builder(
                    padding: AppTheme.paddingXS,
                    itemCount: _uniqueScanSet.length,
                    itemBuilder: (context, index) {
                      final sortedList = _uniqueScanSet.toList()..sort();
                      final barcode = sortedList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                          vertical: AppTheme.spaceXXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: AppTheme.borderRadiusSM,
                          border: Border.all(color: AppTheme.backgroundAlt),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMD,
                            vertical: 0,
                          ),
                          leading: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.moduleProduction.withOpacity(0.1),
                              borderRadius: AppTheme.borderRadiusSM,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.moduleProduction,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            barcode,
                            style: AppTheme.bodySmall.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.error, size: 20),
                            onPressed: () => _removeBarcode(barcode),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave =
        _uniqueScanSet.isNotEmpty && truckController.text.trim().length >= 6;

    return PrimaryButton(
      text: _isSaving
          ? 'Saving...'
          : 'Save Data (${_uniqueScanSet.length} items)',
      icon: Icons.save_rounded,
      onPressed: canSave && !_isSaving ? _saveData : null,
      isLoading: _isSaving,
      backgroundColor: canSave ? AppTheme.success : AppTheme.backgroundAlt,
      foregroundColor: canSave ? Colors.white : AppTheme.textTertiary,
    );
  }
}
