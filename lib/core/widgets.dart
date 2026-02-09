import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:explosive_android_app/core/app_theme.dart';

/// Reusable UI Components for consistent design across the app
/// All components preserve original callbacks and logic

// ============================================================
// CUSTOM APP BAR
// ============================================================

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.backgroundColor,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.appBarTitle,
      ),
      backgroundColor: backgroundColor ?? AppTheme.primaryDark,
      centerTitle: centerTitle,
      elevation: elevation,
      actions: actions,
      leading: leading,
      iconTheme: const IconThemeData(color: AppTheme.textOnPrimary),
      actionsIconTheme: const IconThemeData(color: AppTheme.textOnPrimary),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================
// BACKGROUND CONTAINER
// ============================================================

class GradientBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final double overlayOpacity;

  const GradientBackground({
    Key? key,
    required this.child,
    this.imagePath = 'assets/images/pexels-hngstrm-1939485.jpg',
    this.overlayOpacity = 0.3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with gradient overlay
        Container(
          decoration: BoxDecoration(
            image: imagePath != null
                ? DecorationImage(
                    image: AssetImage(imagePath!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(overlayOpacity),
                      BlendMode.darken,
                    ),
                  )
                : null,
            gradient: imagePath == null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryDark.withOpacity(0.1),
                      AppTheme.background,
                    ],
                  )
                : null,
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

// ============================================================
// ENHANCED CARD
// ============================================================

class EnhancedCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Border? border;

  const EnhancedCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = AppTheme.elevationMD,
    this.borderRadius,
    this.gradient,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius = borderRadius ?? AppTheme.borderRadiusMD;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        borderRadius: cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: elevation * 1.5,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: cardBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: cardBorderRadius,
              border: border,
            ),
            padding: padding ?? AppTheme.paddingMD,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODULE NAVIGATION CARD (Home Screen)
// ============================================================

class ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const ModuleCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowMD,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.borderRadiusMD,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.85),
              ],
            ),
            borderRadius: AppTheme.borderRadiusMD,
          ),
          child: InkWell(
            onTap: isLoading ? null : onTap,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG,
                vertical: AppTheme.spaceMD,
              ),
              child: Row(
                children: [
                  // Icon with circle background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: AppTheme.spaceLG),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTheme.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          subtitle,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATS/SUMMARY CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData? icon;
  final bool compact;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.moduleGradient(color),
        borderRadius: AppTheme.borderRadiusMD,
        boxShadow: AppTheme.shadowSM,
      ),
      padding: EdgeInsets.all(compact ? AppTheme.spaceMD : AppTheme.spaceLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: compact ? 20 : 24),
            SizedBox(height: compact ? AppTheme.spaceXS : AppTheme.spaceSM),
          ],
          Text(
            value,
            style: (compact ? AppTheme.titleLarge : AppTheme.headlineMedium)
                .copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: compact ? AppTheme.spaceXXS : AppTheme.spaceXS),
          Text(
            title,
            style: AppTheme.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENHANCED TEXT FIELD
// ============================================================

class EnhancedTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int? maxLines;
  final String? semanticLabel;

  const EnhancedTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.maxLines = 1,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        enabled: enabled,
        maxLines: maxLines,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: enabled ? AppTheme.surfaceVariant : AppTheme.backgroundAlt,
          border: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusMD,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusMD,
            borderSide: BorderSide(color: AppTheme.backgroundAlt, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.borderRadiusMD,
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          contentPadding: AppTheme.paddingLG,
          hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          labelStyle: AppTheme.labelMedium,
        ),
      ),
    );
  }
}

// ============================================================
// ENHANCED BUTTON
// ============================================================

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primary,
        foregroundColor: foregroundColor ?? AppTheme.textOnPrimary,
        disabledBackgroundColor: AppTheme.backgroundAlt,
        disabledForegroundColor: AppTheme.textTertiary,
        elevation: AppTheme.elevationSM,
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXL,
              vertical: AppTheme.spaceLG,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMD,
        ),
        minimumSize:
            const Size(AppTheme.minTouchTarget, AppTheme.minTouchTarget),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22),
                  const SizedBox(width: AppTheme.spaceSM),
                ],
                Text(text, style: AppTheme.buttonText),
              ],
            ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isCompact;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.color,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppTheme.spaceSM : AppTheme.spaceMD,
        vertical: isCompact ? AppTheme.spaceXS : AppTheme.spaceSM,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
      ),
      child: Text(
        text,
        style:
            (isCompact ? AppTheme.labelSmall : AppTheme.labelMedium).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.paddingMD,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryDark,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusMD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    subtitle!,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ============================================================
// DATA ROW (for detail displays)
// ============================================================

class DataRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;
  final bool boldLabel;

  const DataRow({
    Key? key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
    this.boldLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: boldLabel
                  ? AppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold)
                  : AppTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;

  const EmptyState({
    Key? key,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.paddingXXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spaceLG),
            ],
            Text(
              message,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spaceLG),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SYNC OVERLAY
// ============================================================

class SyncOverlay extends StatelessWidget {
  final double progress;
  final String status;
  final bool isVisible;

  const SyncOverlay({
    Key? key,
    required this.progress,
    required this.status,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: EnhancedCard(
            padding: AppTheme.paddingXXL,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: progress < 0 ? null : progress,
                  strokeWidth: 3,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Text(
                  status,
                  style: AppTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (progress > 0) ...[
                  const SizedBox(height: AppTheme.spaceSM),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
