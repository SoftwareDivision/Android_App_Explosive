import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class DBHandler {
  static Database? _database;
  static const String _apiBaseUrl = 'http://192.168.10.12:4201/api';

  static Future<void> initDB({Function(int progress)? onProgress}) async {
    try {
      await _requestStoragePermission();
      onProgress?.call(10);

      // Use proper directory handling for Android 12+ compatibility
      late Directory dir;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
          // Android 11+
          // Use app-specific external storage directory for Android 11+
          final extDir = await getExternalStorageDirectory();
          dir = Directory('${extDir!.path}/ExplosiveDB');
        } else {
          // For older Android versions, use the legacy path
          dir = Directory('/storage/emulated/0/ExplosiveDB');
        }
      } else {
        // For non-Android platforms, use the documents directory
        final docDir = await getApplicationDocumentsDirectory();
        dir = Directory('${docDir.path}/ExplosiveDB');
      }

      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }
      onProgress?.call(20);

      final dbPath = join(dir.path, 'explosivedata.db');

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('PRAGMA foreign_keys = ON');
          onProgress?.call(30);

          // Create tables with progress updates
          await _createTables(db, onProgress);
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      onProgress?.call(80);

      await loginInsert();
      onProgress?.call(100);
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      rethrow;
    }
  }

  static Future<void> _createTables(
      Database db, Function(int progress)? onProgress) async {
    final tables = [
      // User table with separate index creation
      '''
  CREATE TABLE IF NOT EXISTS user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    password TEXT
  );
  ''',
      '''
  CREATE INDEX IF NOT EXISTS idx_user_username ON user(username);
  ''',

      // Production transfer table
      '''
  CREATE TABLE IF NOT EXISTS production_transfer (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trans_id TEXT UNIQUE,
    truck_no TEXT
  );
  ''',

      // Production to magazine loading table
      '''
  CREATE TABLE IF NOT EXISTS productiontomagazine_loading (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    production_transfer_id INTEGER,
    l1barcode TEXT UNIQUE,
    flag INTEGER DEFAULT 0
  );
  ''',
      'CREATE INDEX IF NOT EXISTS idx_ptl_ptid ON productiontomagazine_loading(production_transfer_id);',

      // Magazine stock transfer table
      '''
    CREATE TABLE IF NOT EXISTS magzinestocktransfer (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transfer_id TEXT,
      plant TEXT,
      plantcode TEXT,
      bname TEXT,
      bid TEXT,
      productsize TEXT,
      sizecode TEXT,
      magazine_name TEXT,
      case_quantity INTEGER,
      total_wt REAL,
      read_flag INTEGER DEFAULT 0,
      truck_no TEXT
    );
    ''',
      'CREATE INDEX IF NOT EXISTS idx_mst_transfer_id ON magzinestocktransfer(transfer_id);',

      // Scanned box table with foreign key
      '''
    CREATE TABLE IF NOT EXISTS scannedbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      magzinestocktransfer_id INTEGER,
      l1barcode TEXT UNIQUE,
      FOREIGN KEY (magzinestocktransfer_id) REFERENCES magzinestocktransfer(id) ON DELETE CASCADE
    );
    ''',
      'CREATE INDEX IF NOT EXISTS idx_sb_mst_id ON scannedbox(magzinestocktransfer_id);',

      // Loading sheet table
      '''
  CREATE TABLE IF NOT EXISTS loadingsheet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    loadingno TEXT,
    indentno TEXT,
    truckno TEXT,
    tname TEXT,
    bname TEXT,
    bid TEXT,
    product TEXT,
    pcode TEXT,
    typeoofdispatc TEXT,
    magzine TEXT,
    loadwt REAL,
    laodcases INTEGER,
    complete_flag INTEGER DEFAULT 0,
    UNIQUE (loadingno, indentno, bid, pcode, typeoofdispatc, magzine)
  );
  ''',
      'CREATE INDEX IF NOT EXISTS idx_ls_loadingno ON loadingsheet(loadingno);',
      'CREATE INDEX IF NOT EXISTS idx_ls_complete ON loadingsheet(complete_flag);',

      // Loading cases table
      '''
    CREATE TABLE IF NOT EXISTS loadingcases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      loadingsheet_id INTEGER,
      l1barcode TEXT UNIQUE,
      FOREIGN KEY (loadingsheet_id) REFERENCES loadingsheet(id) ON DELETE CASCADE
    );
    ''',
      'CREATE INDEX IF NOT EXISTS idx_lc_ls_id ON loadingcases(loadingsheet_id);',

      // loadingsheet batch table
      '''
      CREATE TABLE IF NOT EXISTS loadingsheetbatch (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loadingsheet_id INTEGER,
        batch_id TEXT,
        fromcase INTEGER,
        tocases INTEGER,
        totalcases INTEGER,
        FOREIGN KEY (loadingsheet_id) REFERENCES loadingsheet(id) ON DELETE CASCADE
      );
      ''',
      'CREATE INDEX IF NOT EXISTS idx_lsb_ls_id ON loadingsheetbatch(loadingsheet_id);',
    ];

    for (int i = 0; i < tables.length; i++) {
      await db.execute(tables[i]);
      // Slightly roughly estimate progress
      onProgress?.call(30 + ((i + 1) * 5));
    }
  }

  // Request storage permission with Android 12+ support
  // Request storage permission with Android 12+ support
  static Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      if (await Permission.storage.isGranted) return;
      if (!await Permission.storage.request().isGranted) {
        throw Exception('Storage permission denied');
      }
      return;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      // Android 11+
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      // Note: If denied, we fall back to app-specific storage which doesn't need permission
    } else {
      // Android 10 and below
      if (await Permission.storage.isGranted) return;
      if (!await Permission.storage.request().isGranted) {
        throw Exception('Storage permission denied');
      }
    }
  }

// Insert login details from API into local database
  static Future<void> loginInsert() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/DownloadUploadData/GetLoginDetails'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch data: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == true && responseData['data'] != null) {
        final List<dynamic> users = responseData['data'];
        final db = await getDatabase();

        // Get existing usernames from local database
        final existingUsers = await db!.query('user', columns: ['username']);
        final existingUsernames =
            existingUsers.map((user) => user['username'] as String).toSet();

        int insertedCount = 0;
        int skippedCount = 0;

        final batch = db.batch();

        for (var user in users) {
          final username = user['username'] as String;

          // Only insert if username doesn't exist
          if (!existingUsernames.contains(username)) {
            batch.insert(
              'user',
              {
                'username': username,
                'password': user['password'],
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            insertedCount++;
          } else {
            skippedCount++;
          }
        }
        await batch.commit(noResult: true);

        debugPrint(
            'User sync completed: $insertedCount new users inserted, $skippedCount existing users skipped');
      } else {
        throw Exception('No user data found.');
      }
    } catch (e) {
      debugPrint('Error inserting users: $e');
    }
  }

  /// Insert into production_transfer
  static Future<int> insertTransfer(String transId, String truckNo) async {
    return await _database!.insert(
      'production_transfer',
      {
        'trans_id': transId,
        'truck_no': truckNo,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert L1 barcode linked to transfer
  static Future<void> insertL1Barcode(int transferId, String barcode) async {
    await _database!.insert(
      'productiontomagazine_loading',
      {
        'production_transfer_id': transferId,
        'l1barcode': barcode,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Fetch all transfer data (production_transfer and productiontomagazine_loading)
  static Future<List<Map<String, dynamic>>> fetchAllTransferData() async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await _database!.rawQuery('''
    SELECT
      pt.id,
      pt.trans_id,
      pt.truck_no,
      pl.l1barcode
    FROM productiontomagazine_loading pl
    INNER JOIN production_transfer pt
    ON pl.production_transfer_id = pt.id
  ''');

    return result;
  }

  /// Delete a transfer (will also delete related barcodes due to ON DELETE CASCADE)
  static Future<void> deleteTransfer(int transferId) async {
    await _database!.delete(
      'production_transfer',
      where: 'id = ?',
      whereArgs: [transferId],
    );
  }

  static Future<void> resetAllData() async {
    final db = await getDatabase();
    try {
      await db?.transaction((txn) async {
        // Disable foreign keys
        await txn.execute('PRAGMA foreign_keys = OFF');

        // Clear all tables (add all your table names here)
        final tables = [
          'scannedbox',
          'magzinestocktransfer',
          'productiontomagazine_loading',
          'production_transfer',
          'loadingcases',
          'loadingsheet',
          'loadingsheetbatch',
          'sqlite_sequence', // Reset sequences
        ];

        for (final table in tables) {
          try {
            await txn.delete(table);
          } catch (e) {
            debugPrint('Error clearing table $table: $e');
          }
        }

        // Reset sequences
        await txn.execute('DELETE FROM sqlite_sequence');

        // Re-enable foreign keys
        await txn.execute('PRAGMA foreign_keys = ON');
      });
    } catch (e) {
      debugPrint('Database reset error: $e');
      rethrow;
    }
  }

  /// Sync magazine transfer data with API
  static Future<void> downloadMagzineAllottedData() async {
    try {
      // Fetch data from API
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/DownloadUploadData/GetMagzineAllottedData'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch data: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == true && responseData['statusCode'] == 200) {
        final transferData = List<Map<String, dynamic>>.from(
            responseData['data']['transferToMazgnies']);
        final productionTransferCases = List<Map<String, dynamic>>.from(
            responseData['data']['productionTransferCases']);
        // Save productionTransferCases data
        await downloadProductionTransferCases(productionTransferCases);
        // Save data to local database
        await _database!.transaction((txn) async {
          // Note: Cannot easily batch mixed queries and inserts with conditional logic
          // But we can optimize by batching inserts if we pre-validated.
          // For now, keeping the logic but using batch for cleaner code if possible?
          // The logic requires checking existence for EACH item.
          // Optimization: Prepare statement or keep as is.
          // Keeping as is to ensure correctness of "upsert" logic without unique constraint.
          for (var transfer in transferData) {
            // Check if record already exists
            final existingRecord = await txn.query(
              'magzinestocktransfer',
              where:
                  'transfer_id = ? AND  bid = ?  AND sizecode = ? AND magazine_name = ? AND plant =?',
              whereArgs: [
                transfer['transferId'],
                transfer['brandId'],
                transfer['productSizecCode'],
                transfer['magazineName'].toString().trim(),
                transfer['plant'],
              ],
              limit: 1,
            );

            // Only insert if record doesn't exist
            if (existingRecord.isEmpty) {
              await txn.insert(
                'magzinestocktransfer',
                {
                  'transfer_id': transfer['transferId'],
                  'plant': transfer['plant'],
                  'plantcode': transfer['plantCode'],
                  'bname': transfer['brandName'],
                  'bid': transfer['brandId'],
                  'productsize': transfer['productSize'],
                  'sizecode': transfer['productSizecCode'],
                  'magazine_name': transfer['magazineName'].toString().trim(),
                  'case_quantity': transfer['caseQuantity'],
                  'total_wt': transfer['totalwt'],
                  'read_flag': transfer['readFlag'],
                  'truck_no': transfer['truckNo'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        });
      } else {
        throw Exception('API response status is false');
      }
    } catch (e) {
      throw Exception('Magazine sync failed: $e');
    }
  }

  // Sync production transfer data with API
  static Future<void> syncProductionScannedBox() async {
    final transferData = await fetchAllTransferData();
    final syncedTransIds = <int>{};
    final groupedData = <String, Map<String, dynamic>>{};

    for (var item in transferData) {
      final transId = item['trans_id'] as String;
      syncedTransIds.add(item['id'] as int);

      if (!groupedData.containsKey(transId)) {
        groupedData[transId] = {
          "id": 0,
          "transId": transId,
          "truckNo": item['truck_no'],
          "allotflag": 0,
          "months": 0,
          "years": 0,
          "barcodes": <Map<String, dynamic>>[]
        };
      }

      groupedData[transId]!['barcodes']!.add(
          {"id": 0, "productionTransferId": 0, "l1Barcode": item['l1barcode']});
    }

    final apiData = groupedData.values.toList();

    if (apiData.isNotEmpty) {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/DownloadUploadData/SyncLoadBoxInTruckData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(apiData),
      );
      debugPrint(response.body);
      if (response.statusCode != 200) {
        throw Exception('Failed to sync production data: ${response.body}');
      }

      await _database!.transaction((txn) async {
        final batch = txn.batch();
        for (int transId in syncedTransIds) {
          batch.delete(
            'production_transfer',
            where: 'id = ?',
            whereArgs: [transId],
          );
          batch.delete(
            'productiontomagazine_loading',
            where: 'production_transfer_id =?',
            whereArgs: [transId],
          );
        }
        await batch.commit(noResult: true);
      });
    }
  }

  static Future<List<Map<String, dynamic>>>
      fetchIncompleteLoadingSheets() async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await db.query(
      'loadingsheet',
      where: 'complete_flag = ?',
      whereArgs: [0],
    );

    return result;
  }

  /// Fetch dispatch data from API and insert into local database
  static Future<void> fetchAndInsertDispatchData() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/DownloadUploadData/GetDispatchData'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch dispatch data: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == true && responseData['statusCode'] == 200) {
        final dispatchData = List<dynamic>.from(responseData['data']);
        if (dispatchData.isEmpty) {
          debugPrint('No dispatch data found');
          return;
        }
        await insertDispatchData(dispatchData);

        debugPrint('Dispatch data fetched and inserted successfully');
      } else {
        throw Exception(
            'API response status is false or statusCode is not 200');
      }
    } catch (e) {
      throw Exception('Failed to fetch and insert dispatch data: $e');
    }
  }

  static Future<void> insertDispatchData(List<dynamic> dispatchData) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var loadingSheet in dispatchData) {
        final loadingNo = loadingSheet['loadingSheetNo'];
        final truckNo = loadingSheet['truckNo'];
        final tName = loadingSheet['tName'];

        if (loadingSheet['indentDetails'] != null) {
          for (var item in loadingSheet['indentDetails']) {
            if (item['iscompleted'] == 0) {
              batch.insert(
                'loadingsheet',
                {
                  'loadingno': loadingNo,
                  'truckno': truckNo,
                  'tname': tName,
                  'bname': item['bname'],
                  'indentno': item['indentNo'],
                  'bid': item['bid'],
                  'product': item['psize'],
                  'pcode': item['sizeCode'],
                  'typeoofdispatc': item['typeOfDispatch'],
                  'magzine': item['mag'],
                  'loadwt': item['loadWt'],
                  'laodcases': item['loadcase'],
                  'complete_flag': 0,
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// Sync scanned box data with API
  static Future<void> uploadUnloadCasesToMagzine() async {
    try {
      // Fetch data from local database with join
      final result = await _database!.rawQuery('''
        SELECT 
          m.id,
          m.transfer_id,
          m.truck_no,
          m.plant,
          m.plantcode,
          m.bname,
          m.bid,
          m.productsize,
          m.sizecode,
          m.magazine_name,
          m.case_quantity,
          m.total_wt,
          m.read_flag,
          s.l1barcode
        FROM magzinestocktransfer m
        LEFT JOIN scannedbox s
        ON m.id = s.magzinestocktransfer_id
        WHERE m.read_flag = 1
      ''');

      // Group the data by transfer details
      final groupedData = <int, Map<String, dynamic>>{};

      for (var row in result) {
        final transferId = row['id'] as int;

        if (!groupedData.containsKey(transferId)) {
          groupedData[transferId] = {
            "id": 0,
            "transferId": row['transfer_id'],
            "truckNo": row['truck_no'],
            "plant": row['plant'],
            "plantCode": row['plantcode'],
            "brandName": row['bname'],
            "brandId": row['bid'],
            "productSize": row['productsize'],
            "productSizecCode": row['sizecode'],
            "magazineName": row['magazine_name'],
            "caseQuantity": row['case_quantity'],
            "totalwt": row['total_wt'],
            "readFlag": row['read_flag'],
            "transferToMazgnieScanneddata": <Map<String, dynamic>>[]
          };
        }

        if (row['l1barcode'] != null) {
          groupedData[transferId]!['transferToMazgnieScanneddata']!.add({
            "id": 0,
            "transferToMazgnieId": 0,
            "l1Scanned": row['l1barcode']
          });
        }
      }

      final apiData = groupedData.values.toList();
      print(jsonEncode(apiData));
      if (apiData.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/DownloadUploadData/SyncMagzineUnloadData'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(apiData),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to sync scanned box data: ${response.body}');
        }

        // Clear synced data efficiently
        await _database!.transaction((txn) async {
          final batch = txn.batch();
          // Delete grouped items by magazine transfer ID locally
          for (var id in groupedData.keys) {
            batch.delete('scannedbox',
                where: 'magzinestocktransfer_id = ?', whereArgs: [id]);
            batch.delete('magzinestocktransfer',
                where: 'id = ?', whereArgs: [id]);
          }
          // Cleanup flags
          batch.delete(
            'productiontomagazine_loading',
            where: 'flag = ?',
            whereArgs: [1],
          );
          await batch.commit(noResult: true);
        });
      }
    } catch (e) {
      throw Exception('Failed to sync scanned box data: $e');
    }
  }

  static Future<void> syncDataWithApi({
    Function(double progress, String status)? onProgress,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    final stopwatch = Stopwatch()..start();

    while (retryCount < maxRetries) {
      try {
        onProgress?.call(0.0, 'Starting synchronization...');

        // Step 1: Upload completed loading sheets (20% weight)
        onProgress?.call(0.1, 'Uploading completed loading sheets...');
        await _executeWithRetry(
          () => syncCompletedLoadingSheetsData(),
          operationName: 'syncCompletedLoadingSheetsData',
        );

        // Step 2: Fetch and insert dispatch data (20% weight)
        onProgress?.call(0.3, 'Downloading dispatch data...');
        await _executeWithRetry(
          () => fetchAndInsertDispatchData(),
          operationName: 'fetchAndInsertDispatchData',
        );

        // Step 3: Upload scanned box data (20% weight)
        onProgress?.call(0.5, 'Uploading scanned box data...');
        await _executeWithRetry(
          () => uploadUnloadCasesToMagzine(),
          operationName: 'uploadUnloadCasesToMagzine',
        );

        // Step 4: Download magazine transfer data (20% weight)
        onProgress?.call(0.7, 'Downloading magazine allocations...');
        await _executeWithRetry(
          () => downloadMagzineAllottedData(),
          operationName: 'downloadMagzineAllottedData',
        );

        // Step 5: Sync production scanned boxes (20% weight)
        onProgress?.call(0.9, 'Syncing production transfers...');
        await _executeWithRetry(
          () => syncProductionScannedBox(),
          operationName: 'syncProductionScannedBox',
        );

        onProgress?.call(1.0, 'Synchronization completed successfully!');
        debugPrint('Sync completed in ${stopwatch.elapsed}');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('Sync attempt $retryCount failed: $e');

        if (retryCount < maxRetries) {
          final delay = Duration(seconds: retryCount * 2);
          onProgress?.call(0.0,
              'Sync failed. Retrying in ${delay.inSeconds} seconds... (Attempt ${retryCount + 1}/$maxRetries)');
          await Future.delayed(delay);
        } else {
          onProgress?.call(0.0, 'Sync failed after $maxRetries attempts');
          debugPrint('Final sync error: $e');
          throw Exception('Sync failed after $maxRetries attempts: $e');
        }
      }
    }
  }

  /// Helper method to execute an operation with basic retry logic
  static Future<void> _executeWithRetry(
    Future<void> Function() operation, {
    required String operationName,
    int maxRetries = 2,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        await operation();
        return;
      } catch (e) {
        debugPrint('$operationName attempt $attempt failed: $e');
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(initialDelay * attempt);
      }
    }
  }

  static Future<Database?> getDatabase() async {
    if (_database == null) {
      await initDB();
    }
    return _database;
  }

  /// Insert scanned box linked to magazine transfer
  static Future<void> insertScannedBox(
      int magazineTransferId, String l1barcode) async {
    await _database!.insert(
      'scannedbox',
      {
        'magzinestocktransfer_id': magazineTransferId,
        'l1barcode': l1barcode,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Insert scanned L1 barcode linked to a loading sheet
  static Future<void> insertLoadingCase(
      int loadingSheetId, String l1barcode) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }
    await db.insert(
      'loadingcases',
      {
        'loadingsheet_id': loadingSheetId,
        'l1barcode': l1barcode,
      },
      conflictAlgorithm: ConflictAlgorithm
          .ignore, // Ignore if barcode already exists for this sheet
    );
  }

  /// Update the complete_flag for a loading sheet
  static Future<void> updateLoadingSheetCompleteFlag(
      int loadingSheetId, int flag) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }
    await db.update(
      'loadingsheet',
      {'complete_flag': flag},
      where: 'id = ?',
      whereArgs: [loadingSheetId],
    );
  }

  /// Fetch all loading sheets (without barcodes initially)
  static Future<List<Map<String, dynamic>>> fetchLoadingSheets() async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await db.query('loadingsheet');

    return result;
  }

  /// Fetch L1 barcodes for a specific loading sheet ID
  static Future<List<Map<String, dynamic>>> fetchL1BarcodesForLoadingSheet(
      int loadingSheetId) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await db.query(
      'loadingcases',
      columns: ['l1barcode'],
      where: 'loadingsheet_id = ?',
      whereArgs: [loadingSheetId],
    );
    return result;
  }

  /// Fetch loading sheets by loading number and magazine
  static Future<List<Map<String, dynamic>>>
      fetchLoadingSheetByLoadingNoAndMagazine(
          String loadingNo, String magazine) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await db.query(
      'loadingsheet',
      where:
          'loadingno = ? AND magzine = ? AND typeoofdispatc = ?  AND complete_flag =?',
      whereArgs: [loadingNo, magazine, 'ML', 0],
    );
    debugPrint(
        'Fetched loading sheets for $loadingNo and $magazine: $result'); // Debug print
    return result;
  }

  /// Sync completed loading sheet data with API
  static Future<void> syncCompletedLoadingSheetsData() async {
    try {
      final db = await getDatabase();
      if (db == null) {
        throw Exception('Database not initialized');
      }

      // Fetch completed loading sheets
      final completedSheets = await db.query(
        'loadingsheet',
        where: 'complete_flag = ?',
        whereArgs: [1],
      );

      if (completedSheets.isEmpty) {
        debugPrint('No completed loading sheets to sync.');
        return; // No data to sync
      }

      final apiData = [];

      // Fetch barcodes for each completed loading sheet and structure data
      for (var sheet in completedSheets) {
        final loadingSheetId = sheet['id'] as int;
        final barcodes = await db.query(
          'loadingcases',
          columns: ['l1barcode'],
          where: 'loadingsheet_id = ?',
          whereArgs: [loadingSheetId],
        );

        final barcodeList = barcodes.map((b) => b['l1barcode']).toList();

        apiData.add({
          'loadingSheet': sheet, // Include all loading sheet details
          'l1Barcodes': barcodeList, // List of associated barcodes
        });
      }

      debugPrint(jsonEncode(apiData)); // Debug print to check data structure

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/DownloadUploadData/SyncCompletedLoadingSheets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(apiData),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to sync completed loading sheets data: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == true && responseData['statusCode'] == 200) {
        debugPrint('Completed loading sheets synced successfully.');

        // Delete synced data from local database
        await db.transaction((txn) async {
          final batch = txn.batch();
          for (var sheet in completedSheets) {
            final loadingSheetId = sheet['id'] as int;
            // Delete associated loading cases first
            batch.delete(
              'loadingcases',
              where: 'loadingsheet_id = ?',
              whereArgs: [loadingSheetId],
            );
            // Then delete the loading sheet record
            batch.delete(
              'loadingsheet',
              where: 'id = ?',
              whereArgs: [loadingSheetId],
            );
          }
          await batch.commit(noResult: true);
        });
        debugPrint(
            'Synced completed loading sheets data deleted from local DB.');
      } else {
        throw Exception(
            'API response status is false for completed loading sheets sync: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Failed to sync completed loading sheets data: $e');
      throw Exception('Failed to sync completed loading sheets data: $e');
    }
  }

  /// Fetch loading sheets by loading number and dispatch type 'DD'
  static Future<List<Map<String, dynamic>>> fetchDirectDispatchLoadingSheet(
      String loadingNo) async {
    final db = await getDatabase();
    if (db == null) {
      throw Exception('Database not initialized');
    }

    final result = await db.query(
      'loadingsheet',
      where: 'loadingno = ? AND typeoofdispatc = ? AND complete_flag = ?',
      whereArgs: [loadingNo, 'DD', 0],
    );
    debugPrint(
        'Fetched direct dispatch loading sheets for $loadingNo: $result'); // Debug print
    return result;
  }

  static Future<void> downloadProductionTransferCases(
      List<dynamic> productionTransferCases) async {
    try {
      await _database!.transaction((txn) async {
        final batch = txn.batch();
        for (var transferCase in productionTransferCases) {
          batch.insert(
            'productiontomagazine_loading',
            {
              'production_transfer_id': transferCase['productionTransferId'],
              'l1barcode': transferCase['l1Barcode'],
              'flag': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw Exception('Failed to save production transfer cases: $e');
    }
  }
}
