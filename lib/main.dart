import 'package:flutter/material.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: FutureBuilder(
        future: DBHandler.initDB(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return ErrorScreen(error: snapshot.error.toString());
            }
            return const MyApp();
          }
          return const LoadingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explosive Storage & Dispatched App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing Database...'),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            const Text('Initialization Failed', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await DBHandler.initDB();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Retry failed: $e')),
                  );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
