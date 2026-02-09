import 'package:explosive_android_app/Production_Magzine_Transfer/MagzineUnloadBoxScan.dart';
import 'package:flutter/material.dart';
import '../Database/db_handler.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
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

  // ============ BUSINESS LOGIC (PRESERVED) ============
  @override
  void initState() {
    super.initState();
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
            _showSnackBar(
                'No data found for magazine: $magazineCode', AppTheme.warning);
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
      _showSnackBar('Error loading magazine data: $e', AppTheme.error);
    }
  }

  void _clearMagazineFieldAndSetFocus() {
    _magazineController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _magazineFocusNode.requestFocus();
    });
  }

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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Unloading Operation',
        backgroundColor: AppTheme.moduleDirectDispatch,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _resetScan,
            tooltip: 'Reset Scan',
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Magazine Scan Input
                _buildMagazineScanCard(),
                const SizedBox(height: AppTheme.spaceMD),

                // Loading Indicator
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: AppTheme.paddingXL,
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.moduleDirectDispatch),
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            'Loading magazine data...',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Results Section
                if (_magazineDataList.isNotEmpty) ...[
                  // Stats Card
                  _buildStatsCard(),
                  const SizedBox(height: AppTheme.spaceMD),

                  // Magazine Records List Section Header
                  Text(
                    'Available Records',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spaceSM),

                  // Magazine Data Cards
                  ..._magazineDataList
                      .map((magazineData) => _buildMagazineCard(magazineData)),
                ],

                // Empty State when no results
                if (!_isLoading &&
                    _magazineDataList.isEmpty &&
                    _scannedMagazine == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: EmptyState(
                      message:
                          'Scan a magazine barcode to view unloading records',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineScanCard() {
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
            Row(
              children: [
                Container(
                  padding: AppTheme.paddingSM,
                  decoration: BoxDecoration(
                    color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: Icon(
                    Icons.warehouse_rounded,
                    color: AppTheme.moduleDirectDispatch,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Text(
                  'Scan Magazine',
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: _magazineController,
              focusNode: _magazineFocusNode,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Scan or enter magazine code',
                prefixIcon: const Icon(Icons.document_scanner_outlined),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(AppTheme.spaceXS),
                  decoration: BoxDecoration(
                    color: AppTheme.moduleDirectDispatch.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSM,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.search,
                        color: AppTheme.moduleDirectDispatch),
                    onPressed: () async {
                      final code = _magazineController.text;
                      if (code.isNotEmpty) {
                        await _scanMagazine(code);
                        _magazineController.clear();
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
                  borderSide: BorderSide(
                      color: AppTheme.moduleDirectDispatch, width: 2),
                ),
                contentPadding: AppTheme.paddingMD,
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
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: AppTheme.paddingLG,
      decoration: BoxDecoration(
        gradient: AppTheme.moduleGradient(AppTheme.moduleDirectDispatch),
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.borderRadiusSM,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magazine: $_scannedMagazine',
                  style: AppTheme.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  '${_magazineDataList.length} unloading record(s) available',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagazineCard(Map<String, dynamic> magazineData) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.borderRadiusMD,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusMD,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoxScanningPage(
                  magazineData: magazineData,
                  scannedBoxes: [],
                ),
              ),
            );

            setState(() {
              _magazineDataList = [];
              _scannedMagazine = null;
            });
            _clearMagazineFieldAndSetFocus();
          },
          child: Padding(
            padding: AppTheme.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: AppTheme.paddingSM,
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: AppTheme.borderRadiusSM,
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSM),
                          Flexible(
                            child: Text(
                              'Transfer: ${magazineData["transfer_id"]}',
                              style: AppTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Details Grid
                Wrap(
                  spacing: AppTheme.spaceLG,
                  runSpacing: AppTheme.spaceSM,
                  children: [
                    _buildDetailChip(
                        Icons.business, 'Plant: ${magazineData["plant"]}'),
                    _buildDetailChip(Icons.inventory,
                        'Brand: ${magazineData["bname"] ?? "N/A"}'),
                    _buildDetailChip(Icons.category,
                        'Size: ${magazineData["productsize"] ?? "N/A"}'),
                    _buildDetailChip(Icons.local_shipping,
                        'Truck: ${magazineData["truck_no"]}'),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: AppTheme.paddingSM,
                        decoration: BoxDecoration(
                          color: AppTheme.infoSurface,
                          borderRadius: AppTheme.borderRadiusSM,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 16, color: AppTheme.info),
                            const SizedBox(width: AppTheme.spaceXS),
                            Text(
                              'Cases: ${magazineData["case_quantity"]}',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.info,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Container(
                        padding: AppTheme.paddingSM,
                        decoration: BoxDecoration(
                          color: AppTheme.successSurface,
                          borderRadius: AppTheme.borderRadiusSM,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.scale,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: AppTheme.spaceXS),
                            Text(
                              'Weight: ${magazineData["total_wt"]}',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.spaceXXS),
        Text(text, style: AppTheme.labelSmall),
      ],
    );
  }
}
