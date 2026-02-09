import 'package:audioplayers/audioplayers.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ============ BUSINESS LOGIC (PRESERVED) ============
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

  void _setFocusOnScanField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scanFocusNode.canRequestFocus) {
        _scanFocusNode.requestFocus();
      }
    });
  }

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
      await _vibrateOnError();
    }
  }

  Future<void> _handleScan(String barcode) async {
    if (_scannedCount == _targetCases) {
      _clearTextFieldAndSetFocus();
      await _playSound('music/goodread.wav');
      _showSnackBar('Scan complete! All cases scanned.', AppTheme.success);
      return;
    }

    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.length != 27) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar(
          'Barcode must be exactly 27 characters long.', AppTheme.error);
      return;
    }

    if (!trimmedBarcode.contains(bid)) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Barcode does not match the Brand ID.', AppTheme.error);
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
      await _playSound('music/goodread.wav');
      await _announceScannedCount();
    } else if (_scannedBarcodes.contains(trimmedBarcode)) {
      _clearTextFieldAndSetFocus();
      await _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar(
          'Barcode "$trimmedBarcode" already scanned.', AppTheme.warning);
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
            const Text('Discard Changes?'),
          ],
        ),
        content: const Text(
            'You have unsaved scanned barcodes. Do you want to discard them and leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
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
        _showSnackBar(
          'Please scan $_targetCases cases before saving. Currently scanned: $_scannedCount',
          AppTheme.error,
        );
        return;
      }

      for (final barcode in _scannedBarcodes) {
        await DBHandler.insertLoadingCase(loadingSheetId, barcode);
      }

      await DBHandler.updateLoadingSheetCompleteFlag(loadingSheetId, 1);

      await _playSound('music/success.wav');

      _showSnackBar('Loading saved successfully!', AppTheme.success);

      setState(() {
        _scannedBarcodes.clear();
        _scannedCount = 0;
        _hasUnsavedChanges = false;
      });

      Navigator.pop(context);
    } catch (e) {
      await _playSound('music/error.wav');
      debugPrint('Error saving loading: $e');
      _showSnackBar('Error saving loading: ${e.toString()}', AppTheme.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    // loadingSheetId available from widget.loadingSheetData['id'] if needed
    final progress = _targetCases > 0 ? _scannedCount / _targetCases : 0.0;
    final isComplete = _scannedCount == _targetCases;

    return PopScope(
      canPop: !_hasUnsavedChanges,
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
        appBar: CustomAppBar(
          title: 'L1 Box Scanning',
          backgroundColor: AppTheme.moduleDirectDispatch,
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Container(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.backgroundAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? AppTheme.success
                          : AppTheme.moduleDirectDispatch,
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: AppTheme.paddingMD,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Card with Sheet Details
                        _buildDetailsCard(),
                        const SizedBox(height: AppTheme.spaceMD),

                        // Progress Stats
                        _buildProgressStats(isComplete),
                        const SizedBox(height: AppTheme.spaceMD),

                        // Scan Input
                        _buildScanInput(),
                        const SizedBox(height: AppTheme.spaceMD),

                        // Scanned List (with fixed height)
                        SizedBox(
                          height: 250,
                          child: _buildScannedList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Save Button - fixed at bottom
                Padding(
                  padding: AppTheme.paddingMD,
                  child: _buildSaveButton(isComplete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
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
              gradient: AppTheme.moduleGradient(AppTheme.moduleDirectDispatch),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: AppTheme.spaceSM),
                Text(
                  'Loading Sheet #${widget.loadingSheetData['id'] ?? 'N/A'}',
                  style: AppTheme.titleSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: AppTheme.paddingMD,
            child: Column(
              children: [
                _buildDetailRow(
                    'Truck No',
                    widget.loadingSheetData['truckno'] ?? 'N/A',
                    Icons.local_shipping),
                _buildDetailRow('Transporter',
                    widget.loadingSheetData['tname'] ?? 'N/A', Icons.business),
                _buildDetailRow(
                    'Brand',
                    '${widget.loadingSheetData['bid'] ?? 'N/A'} - ${widget.loadingSheetData['bname'] ?? 'N/A'}',
                    Icons.inventory),
                _buildDetailRow(
                    'Product',
                    widget.loadingSheetData['product'] ?? 'N/A',
                    Icons.category),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.spaceSM),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.labelSmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats(bool isComplete) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Scanned',
            value: '$_scannedCount',
            color: isComplete ? AppTheme.success : AppTheme.info,
            icon: Icons.qr_code_scanner,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Target',
            value: '$_targetCases',
            color: AppTheme.moduleDirectDispatch,
            icon: Icons.flag_rounded,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Remaining',
            value: '${_targetCases - _scannedCount}',
            color: (_targetCases - _scannedCount) > 0
                ? AppTheme.warning
                : AppTheme.success,
            icon: Icons.pending_actions,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildScanInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      padding: AppTheme.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner,
                  size: 18, color: AppTheme.moduleDirectDispatch),
              const SizedBox(width: AppTheme.spaceSM),
              Text('Scan Barcode', style: AppTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextField(
            controller: _scanController,
            focusNode: _scanFocusNode,
            inputFormatters: [LengthLimitingTextInputFormatter(27)],
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Scan or enter L1 Box Barcode (27 digits)',
              prefixIcon: const Icon(Icons.document_scanner_outlined),
              suffixIcon: Container(
                margin: const EdgeInsets.all(AppTheme.spaceXS),
                decoration: BoxDecoration(
                  color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusSM,
                ),
                child: IconButton(
                  icon: Icon(Icons.qr_code_scanner,
                      color: AppTheme.moduleDirectDispatch),
                  onPressed: () {
                    // TODO: Implement QR code scanning
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
                    BorderSide(color: AppTheme.moduleDirectDispatch, width: 2),
              ),
              contentPadding: AppTheme.paddingMD,
            ),
            onSubmitted: _handleScan,
            textInputAction: TextInputAction.done,
          ),
        ],
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
                          'Scanned Barcodes',
                          style: AppTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                  ),
                  child: Text(
                    '${_scannedBarcodes.length}',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? EmptyState(
                    message:
                        'No barcodes scanned yet.\nScan a barcode to get started.',
                    icon: Icons.qr_code_2_rounded,
                  )
                : ListView.builder(
                    padding: AppTheme.paddingXS,
                    itemCount: _scannedBarcodes.length,
                    itemBuilder: (context, index) {
                      final barcode = _scannedBarcodes[index];
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
                              color: AppTheme.primarySurface,
                              borderRadius: AppTheme.borderRadiusSM,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.primary,
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

  Widget _buildSaveButton(bool isComplete) {
    return PrimaryButton(
      text: _isSaving
          ? 'Saving...'
          : 'Save Loading ($_scannedCount/$_targetCases)',
      icon: Icons.save_rounded,
      onPressed: isComplete && !_isSaving ? _handleSave : null,
      isLoading: _isSaving,
      backgroundColor: isComplete ? AppTheme.success : AppTheme.backgroundAlt,
      foregroundColor: isComplete ? Colors.white : AppTheme.textTertiary,
    );
  }
}
