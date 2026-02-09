import 'package:flutter/material.dart';
import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/login_page.dart';
import 'package:explosive_android_app/core/app_theme.dart';

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
      theme: AppTheme.lightTheme,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explosive Storage & Dispatched App',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: AppTheme.borderRadiusLG,
                boxShadow: AppTheme.shadowMD,
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 40,
                color: AppTheme.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXXL),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              'Initializing Database...',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
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
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: AppTheme.paddingXXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.errorSurface,
                  borderRadius: AppTheme.borderRadiusLG,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXXL),
              Text(
                'Initialization Failed',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXXL),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await DBHandler.initDB();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Retry failed: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceXL,
                    vertical: AppTheme.spaceMD,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
