import 'package:flutter/material.dart';

/// Centralized App Theme Configuration
/// Provides consistent design tokens across the entire application
class AppTheme {
  AppTheme._();

  // ============================================================
  // COLOR PALETTE (Modern Material 3 inspired)
  // ============================================================

  // Primary Colors - Deep Blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primarySurface = Color(0xFFE3F2FD);

  // Secondary Colors - Teal Accent
  static const Color secondaryDark = Color(0xFF00695C);
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF80CBC4);

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successSurface = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFEF6C00);
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningSurface = Color(0xFFFFF3E0);

  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorSurface = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFF03A9F4);
  static const Color infoSurface = Color(0xFFE1F5FE);

  // Neutral Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundAlt = Color(0xFFEEEEEE);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A68);
  static const Color textTertiary = Color(0xFF8E8EA9);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8E8F0);

  // Module-specific Colors (for visual distinction)
  static const Color moduleProduction = Color(0xFF2E7D32); // Green
  static const Color moduleDirectDispatch = Color(0xFFE65100); // Orange
  static const Color moduleMagazine = Color(0xFF6A1B9A); // Purple
  static const Color moduleReports = Color(0xFF4E342E); // Brown
  static const Color moduleSync = Color(0xFF1B5E20); // Dark Green
  static const Color moduleReset = Color(0xFFB71C1C); // Dark Red

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningLight, warning],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [errorLight, error],
  );

  static LinearGradient moduleGradient(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
      );

  // ============================================================
  // TYPOGRAPHY (Consistent scale)
  // ============================================================

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  // Titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.5,
  );

  // Special Styles
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  // ============================================================
  // SPACING (Consistent rhythm - 4px base)
  // ============================================================

  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;

  // Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSM = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMD = EdgeInsets.all(12.0);
  static const EdgeInsets paddingLG = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXL = EdgeInsets.all(20.0);
  static const EdgeInsets paddingXXL = EdgeInsets.all(24.0);

  static const EdgeInsets paddingHorizontalMD =
      EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets paddingHorizontalLG =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingVerticalMD =
      EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets paddingVerticalLG =
      EdgeInsets.symmetric(vertical: 16.0);

  // ============================================================
  // BORDER RADIUS (Consistent curves)
  // ============================================================

  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircle = 100.0;

  static BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);

  // ============================================================
  // ELEVATION & SHADOWS
  // ============================================================

  static const double elevationNone = 0.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 6.0;
  static const double elevationXL = 8.0;

  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================
  // ACCESSIBILITY
  // ============================================================

  // Minimum touch target size (48x48 per Material guidelines)
  static const double minTouchTarget = 48.0;

  // ============================================================
  // THEME DATA
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),

      // Scaffold
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appBarTitle,
        iconTheme: const IconThemeData(color: textOnPrimary),
        actionsIconTheme: const IconThemeData(color: textOnPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: elevationMD,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMD,
        ),
        margin: const EdgeInsets.symmetric(vertical: spaceSM),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: elevationSM,
          padding: const EdgeInsets.symmetric(
              horizontal: spaceLG, vertical: spaceMD),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMD,
          ),
          textStyle: buttonText,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
              horizontal: spaceMD, vertical: spaceSM),
          textStyle: buttonText,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: BorderSide(color: backgroundAlt, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        contentPadding: paddingLG,
        hintStyle: bodyMedium.copyWith(color: textTertiary),
        labelStyle: labelMedium,
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: paddingHorizontalLG,
        minVerticalPadding: spaceMD,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMD,
        ),
        titleTextStyle: cardTitle,
        subtitleTextStyle: cardSubtitle,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primarySurface,
        labelStyle: labelMedium,
        padding: paddingSM,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusSM,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMD,
        ),
        contentTextStyle: bodyMedium.copyWith(color: textOnPrimary),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLG,
        ),
        titleTextStyle: headlineSmall,
        contentTextStyle: bodyMedium,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primarySurface,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: backgroundAlt,
        thickness: 1,
        space: spaceLG,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
    );
  }
}

/// Extension for easy color manipulation
extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}
