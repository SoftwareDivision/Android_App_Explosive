import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:explosive_android_app/core/widgets.dart';
import 'package:flutter/material.dart';
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
  bool _isSaving = false;
  List<String> _validBarcodes = [];
  final FlutterTts flutterTts = FlutterTts();
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  // ============ BUSINESS LOGIC (PRESERVED) ============
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
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.lowLatency);

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
      _showSnackBar('Error loading valid barcodes: $e', AppTheme.error);
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

    if (brandId != null && !boxCode.contains(brandId)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Invalid box: Does not contain the correct Brand ID.',
          AppTheme.error);
      return;
    }

    if (!_validBarcodes.contains(boxCode)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Invalid box code or already loaded', AppTheme.error);
      return;
    }

    final totalCases = widget.magazineData['case_quantity'] ?? 0;
    if (_scannedBoxes.length >= totalCases) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('All boxes have been scanned', AppTheme.success);
      return;
    }

    if (_scannedBoxes.contains(boxCode)) {
      _clearBoxFieldAndSetFocus();
      _vibrateOnError();
      await _playSound('music/badread.wav');
      _showSnackBar('Box already scanned', AppTheme.warning);
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
        _showSnackBar(
            'All boxes have been scanned successfully!', AppTheme.success);
      } catch (e) {
        debugPrint('Completion sound error: $e');
      }
    }

    await _announceScannedCount();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final totalCases = widget.magazineData['case_quantity'] ?? 0;
    if (_scannedBoxes.length < totalCases) {
      _showSnackBar('Please scan all boxes before saving', AppTheme.warning);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLG),
        title: Row(
          children: [
            Container(
              padding: AppTheme.paddingSM,
              decoration: BoxDecoration(
                color: AppTheme.successSurface,
                borderRadius: AppTheme.borderRadiusSM,
              ),
              child: const Icon(Icons.save_rounded, color: AppTheme.success),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            const Text('Confirm Save'),
          ],
        ),
        content: const Text('Are you sure you want to save the scanned boxes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
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

        for (String barcode in _scannedBoxes) {
          await DBHandler.insertScannedBox(magazineTransferId, barcode);

          await db.update(
            'productiontomagazine_loading',
            {'flag': 1},
            where: 'l1barcode = ?',
            whereArgs: [barcode],
          );
        }

        await db.update(
          'magzinestocktransfer',
          {'read_flag': 1},
          where: 'id = ?',
          whereArgs: [magazineTransferId],
        );

        setState(() {
          _scannedBoxes.clear();
        });

        _showSnackBar('Boxes saved successfully!', AppTheme.success);
        Navigator.pop(context, null);
      } else {
        _showSnackBar('Magazine transfer record not found', AppTheme.error);
      }
    } catch (e) {
      _showSnackBar('Error saving scanned boxes: $e', AppTheme.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_scannedBoxes.isEmpty) return true;

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
            const Text('Confirm Exit'),
          ],
        ),
        content: const Text(
            'Are you sure you want to go back? All scanned box data will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Go Back'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      _scannedBoxes.clear();
    }
    return shouldPop ?? false;
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
    final totalCases = widget.magazineData['case_quantity'] ?? 0;
    final progress = totalCases > 0 ? _scannedBoxes.length / totalCases : 0.0;
    final isComplete = _scannedBoxes.length == totalCases;

    return PopScope(
      canPop: _scannedBoxes.isEmpty,
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
          title: 'Box Scanning',
          backgroundColor: AppTheme.moduleDirectDispatch,
        ),
        body: GradientBackground(
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Magazine Details Card
                              _buildDetailsCard(),
                              const SizedBox(height: AppTheme.spaceMD),

                              // Progress Stats
                              _buildProgressStats(isComplete, totalCases),
                              const SizedBox(height: AppTheme.spaceMD),

                              // Scan Input
                              _buildScanInput(),
                              const SizedBox(height: AppTheme.spaceMD),

                              // Scanned Boxes List
                              _buildScannedList(),
                            ],
                          ),
                        ),
                      ),

                      // Save Button
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
          Container(
            padding: AppTheme.paddingMD,
            decoration: BoxDecoration(
              gradient: AppTheme.moduleGradient(AppTheme.moduleDirectDispatch),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warehouse_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: AppTheme.spaceSM),
                Text(
                  'Magazine: ${widget.magazineData['magazine_name']}',
                  style: AppTheme.titleSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppTheme.paddingMD,
            child: Column(
              children: [
                _buildDetailRow(
                    'Brand',
                    '${widget.magazineData['bname'] ?? 'N/A'} (${widget.magazineData['bid'] ?? 'N/A'})',
                    Icons.inventory),
                _buildDetailRow(
                    'Product Size',
                    '${widget.magazineData['productsize'] ?? 'N/A'}',
                    Icons.straighten),
                _buildDetailRow(
                    'Total Cases',
                    '${widget.magazineData['case_quantity']}',
                    Icons.inventory_2),
                _buildDetailRow('Total Weight',
                    '${widget.magazineData['total_wt']}', Icons.scale),
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
            width: 90,
            child: Text(label, style: AppTheme.labelSmall),
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

  Widget _buildProgressStats(bool isComplete, int totalCases) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Scanned',
            value: '${_scannedBoxes.length}',
            color: isComplete ? AppTheme.success : AppTheme.info,
            icon: Icons.qr_code_scanner,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Target',
            value: '$totalCases',
            color: AppTheme.moduleDirectDispatch,
            icon: Icons.flag_rounded,
            compact: true,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: StatCard(
            title: 'Remaining',
            value: '${totalCases - _scannedBoxes.length}',
            color: (totalCases - _scannedBoxes.length) > 0
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
              Text('Scan Box', style: AppTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextField(
            controller: _boxController,
            focusNode: _boxFocusNode,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Scan or enter box barcode (27 digits)',
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
            onSubmitted: (value) async {
              if (value.isEmpty) {
                _clearBoxFieldAndSetFocus();
                return;
              }

              if (value.length != 27) {
                await _playSound('music/badread.wav');
                _vibrateOnError();
                _showSnackBar('Box code must be 27 digits', AppTheme.warning);
                _clearBoxFieldAndSetFocus();
                return;
              }

              await _scanBox(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList() {
    final sortedBoxes = List<String>.from(_scannedBoxes)..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        children: [
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
                          'Scanned Boxes',
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
                    color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                  ),
                  child: Text(
                    '${_scannedBoxes.length}',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.moduleDirectDispatch,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          sortedBoxes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(
                    message:
                        'No boxes scanned yet.\nScan a box to get started.',
                    icon: Icons.inventory_2_rounded,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: AppTheme.paddingXS,
                  itemCount: sortedBoxes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceXS,
                        vertical: AppTheme.spaceXXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successSurface,
                        borderRadius: AppTheme.borderRadiusSM,
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.3)),
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
                            color: AppTheme.success,
                            borderRadius: AppTheme.borderRadiusSM,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          sortedBoxes[index],
                          style: AppTheme.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isComplete) {
    return PrimaryButton(
      text: _isSaving
          ? 'Saving...'
          : 'Save (${_scannedBoxes.length}/${widget.magazineData['case_quantity']})',
      icon: Icons.save_rounded,
      onPressed: isComplete && !_isSaving ? _handleSave : null,
      isLoading: _isSaving,
      backgroundColor: isComplete ? AppTheme.success : AppTheme.backgroundAlt,
      foregroundColor: isComplete ? Colors.white : AppTheme.textTertiary,
    );
  }
}
