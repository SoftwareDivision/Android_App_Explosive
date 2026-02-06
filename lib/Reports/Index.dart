import 'package:explosive_android_app/Reports/TruckLoadReport.dart';
import 'package:explosive_android_app/Reports/UnloadingReport.dart';
import 'package:explosive_android_app/Reports/LoadingSheetReport.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class ReportsIndex extends StatelessWidget {
  const ReportsIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Reports Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pexels-hngstrm-1939485.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: [
                // Truck Load Report Card
                _buildReportCard(
                  context,
                  title: 'Truck Load',
                  subtitle: 'Loading Reports',
                  icon: Icons.local_shipping,
                  color: Colors.blue[700]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TruckLoadReport(),
                      ),
                    );
                  },
                ),
                // Unloading Report Card
                _buildReportCard(
                  context,
                  title: 'Unloading',
                  subtitle: 'Magazine Unloading',
                  icon: Icons.inventory_2,
                  color: Colors.green[700]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnloadingReport(),
                      ),
                    );
                  },
                ),
                // Loading Sheet Report Card
                _buildReportCard(
                  context,
                  title: 'Loading Sheet',
                  subtitle: 'Detailed Reports',
                  icon: Icons.description,
                  color: Colors.orange[700]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoadingSheetReport(),
                      ),
                    );
                  },
                ),
                // Summary Report Card
                _buildReportCard(
                  context,
                  title: 'Summary',
                  subtitle: 'Overview Reports',
                  icon: Icons.analytics,
                  color: Colors.purple[700]!,
                  onTap: () {
                    // TODO: Implement Summary Report
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Summary Report coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
