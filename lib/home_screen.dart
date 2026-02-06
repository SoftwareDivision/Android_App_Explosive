import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter/services.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/DirectDispatchLoad/index.dart';
import 'package:explosive_android_app/Reports/Index.dart';
import 'package:explosive_android_app/Production_Magzine_Transfer/Index.dart';
import 'package:explosive_android_app/MagzineLoad/index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0.0;

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncStatus = 'Starting synchronization...';
      _syncProgress = 0.0;
    });

    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Sync'),
            content:
                const Text('Do you want to synchronize data with the server?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sync'),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      // Start sync process
      await DBHandler.syncDataWithApi(
        onProgress: (progress, status) {
          setState(() {
            _syncProgress = progress;
            _syncStatus = status;
          });
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data synchronized successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Explosive Storage & Dispatched App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'logout') {
                SystemNavigator.pop();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            icon: const Icon(Icons.more_vert_outlined),
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
          Column(
            children: [
              if (_isSyncing)
                LinearProgressIndicator(
                  value: _syncProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildCard(
                        context,
                        title: 'Production-Magzine Transfer',
                        subtitle: 'Production-Magzine Transfer',
                        color: Colors.blue[800],
                        icon: Icons.local_shipping,
                        destination: const TransferDetailsPage(),
                      ),
                      _buildCard(
                        context,
                        title: 'Direct Dispatch Loading',
                        subtitle: 'Load directly for Plants',
                        color: Colors.orange[800],
                        icon: Icons.directions_car_filled_outlined,
                        destination: DirectDispatchLoadIndex(),
                      ),
                      _buildCard(
                        context,
                        title: 'Loading from Magazine',
                        subtitle: 'Load from magazine stock',
                        color: Colors.purple[800],
                        icon: Icons.warehouse_outlined,
                        destination: const MagzineLoadIndex(),
                      ),
                      _buildCard(
                        context,
                        title: 'Reports',
                        subtitle: 'See All Reports',
                        color: Colors.brown[800],
                        icon: Icons.assessment_outlined,
                        destination: const ReportsIndex(),
                      ),
                      _syncCard(context),
                      _resetCard(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _syncProgress < 0 ? null : _syncProgress,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _syncStatus,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (_syncProgress > 0)
                            Text(
                              '${(_syncProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color? color,
    required IconData icon,
    Widget? destination,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: color,
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: onTap ??
              () {
                if (destination != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => destination),
                  );
                }
              },
        ),
      ),
    );
  }

  Widget _syncCard(BuildContext context) {
    return _buildCard(
      context,
      title: 'Sync Data',
      subtitle: 'Synchronize with server',
      color: Colors.green[800],
      icon: Icons.sync,
      onTap: _syncData,
    );
  }

  Widget _resetCard(BuildContext context) {
    return _buildCard(
      context,
      title: 'Reset Database',
      subtitle: 'Clear all data',
      color: Colors.red[800],
      icon: Icons.delete_forever,
      onTap: () async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Reset'),
            content: const Text(
                'Are you sure you want to reset the database? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        final passwordController = TextEditingController();
        final bool? passwordOk = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter Password'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(passwordController.text == '1234');
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (passwordOk != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect password. Reset cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        try {
          await DBHandler.resetAllData();

          if (!mounted) return;

          // Close the loading dialog
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database reset successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Optional: Navigate to a fresh instance of your app
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } catch (e) {
          if (!mounted) return;

          // Close the loading dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting database: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
