import 'package:explosive_android_app/Database/db_handler.dart';
import 'package:explosive_android_app/home_screen.dart';
import 'package:explosive_android_app/core/app_theme.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ============ BUSINESS LOGIC (PRESERVED) ============
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter both username and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = await DBHandler.getDatabase();
      final List<Map<String, dynamic>> users = await db!.query(
        'user',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (users.isNotEmpty) {
        // Login successful
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // Login failed
        _showError('Invalid credentials');
      }
    } catch (e) {
      _showError('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // ============ END BUSINESS LOGIC ============

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMD,
        ),
        margin: AppTheme.paddingLG,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/loginand2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark gradient overlay for better readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isSmallScreen ? AppTheme.spaceLG : AppTheme.spaceXXL,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginCard(isSmallScreen),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isSmallScreen) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusXL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
            isSmallScreen ? AppTheme.spaceLG : AppTheme.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              padding: AppTheme.paddingMD,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: AppTheme.borderRadiusMD,
              ),
              child: Image.asset(
                'assets/images/aarkayLogo.png',
                height: isSmallScreen ? 60 : 80,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 60 : 80,
                    width: isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: AppTheme.borderRadiusMD,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
                height: isSmallScreen ? AppTheme.spaceMD : AppTheme.spaceLG),

            // Welcome Text
            Text(
              'Welcome Back!',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Sign in to continue',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(
                height: isSmallScreen ? AppTheme.spaceLG : AppTheme.spaceXXL),

            // Username Field
            _buildTextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              labelText: 'Username',
              hintText: 'Enter your username',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            SizedBox(
                height: isSmallScreen ? AppTheme.spaceLG : AppTheme.spaceXXL),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: AppTheme.textOnPrimary,
                  disabledBackgroundColor: AppTheme.backgroundAlt,
                  elevation: AppTheme.elevationSM,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusMD,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 22),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text('Sign In', style: AppTheme.buttonText),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Version info
            Text(
              'Version 1.0.0',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceVariant,
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
        labelStyle: AppTheme.labelMedium,
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
      ),
    );
  }
}
