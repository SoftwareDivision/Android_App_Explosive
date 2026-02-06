import 'package:explosive_android_app/Production_Magzine_Transfer/ProductionLoading.dart';
import 'package:explosive_android_app/Production_Magzine_Transfer/MagzineUnload.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class TransferDetailsPage extends StatelessWidget {
  const TransferDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text(
          'Truck-Magzine Transfer Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[800],
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
          // Foreground content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Loading Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoadingPage(),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 6,
                    color: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const ListTile(
                      leading: Icon(
                        Icons.upload_file,
                        color: Colors.white,
                        size: 30,
                      ),
                      title: Text(
                        "Loading",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        "Details about loading the truck.",
                        style: TextStyle(color: Colors.white),
                      ),
                      contentPadding: EdgeInsets.all(16),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Unloading Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnloadingOperation(),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 6,
                    color: Colors.red[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const ListTile(
                      leading: Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 30,
                      ),
                      title: Text(
                        "Unloading",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "Details about unloading at the magazine.",
                        style: TextStyle(color: Colors.white),
                      ),
                      contentPadding: EdgeInsets.all(16),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
