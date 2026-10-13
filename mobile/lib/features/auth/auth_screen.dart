import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/brand_icons.dart';
import '../../core/storage/local_storage.dart';
import '../../core/network/api_endpoints.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback? onBack;
  final bool initialIsSignUp;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
    this.onBack,
    this.initialIsSignUp = false,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignUp;
  bool _obscurePassword = true;

  final _emailController = TextEditingController(text: 'dhiman@adtu.edu.in');
  final _passwordController = TextEditingController(text: 'Password123!');
  final _nameController = TextEditingController(text: 'Dhiman Saikia');

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_isSignUp) {
      final success = await ref.read(authProvider.notifier).register(
            email: email,
            password: password,
            fullName: name.isNotEmpty ? name : 'New Student',
          );
      if (success) widget.onLoginSuccess();
    } else {
      final success =
          await ref.read(authProvider.notifier).login(email, password);
      if (success) widget.onLoginSuccess();
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // -----------------------------------------------------------
            // TOP HEADER: Campus Graphic + Native Frosted Back Button + Curve
            // -----------------------------------------------------------
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Campus banner graphic
                SizedBox(
                  width: double.infinity,
                  height: 230 + topPadding,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/login_header.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          );
                        },
                      ),
                      // Soft warm theme overlay
                      Container(
                        color: const Color(0xFFF7F1EC).withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                ),

                // Top gradient overlay to protect status bar & controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topPadding + 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Frosted glass back button
                Positioned(
                  top: topPadding + 10,
                  left: 18,
                  child: InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),

                // Frosted glass Server URL settings button (for Render / custom backend URL)
                Positioned(
                  top: topPadding + 10,
                  right: 18,
                  child: InkWell(
                    onTap: () => _showServerConfigDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.08),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dns_outlined,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),

                // Floating AttendHub logo squircle badge centered vertically in the campus banner
                Positioned(
                  top: topPadding,
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.12),
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Smooth curved cutout at bottom of banner
                Positioned(
                  bottom: -1,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------
            // FORM BODY
            // -----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  Center(
                    child: Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _isSignUp
                          ? 'Register to track your attendance independently'
                          : 'Log in to continue to AttendiFy',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Error message banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.coral.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.coral, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  if (_isSignUp) ...[
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    label: 'Email / University ID',
                    hint: 'Enter your email or university ID',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.inkMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  // Forgot Password Link (Log In mode only)
                  if (!_isSignUp) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Password reset instructions sent to registered email.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFDE6854),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit Button
                  AppButton(
                    label: _isSignUp ? 'Create Account' : 'Log In',
                    isLoading: authState.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 22),

                  // "or" Divider
                  const Row(
                    children: [
                      Expanded(
                          child:
                              Divider(color: Color(0xFFEADBCE), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                          child:
                              Divider(color: Color(0xFFEADBCE), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Social Login Buttons
                  _buildSocialButton(
                    logo: BrandIcons.google(size: 20),
                    label: 'Continue with Google',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 10),
                  _buildSocialButton(
                    logo: BrandIcons.github(size: 20),
                    label: 'Continue with GitHub',
                    onTap: _submit,
                  ),
                  const SizedBox(height: 10),
                  _buildSocialButton(
                    logo: BrandIcons.microsoft(size: 18),
                    label: 'Continue with Microsoft',
                    onTap: _submit,
                  ),

                  const SizedBox(height: 24),

                  // Switch between Log In and Sign Up
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: AppTypography.bodySmall.copyWith(fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFDE6854),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget logo,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radiusXl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.radiusXl,
          border: Border.all(color: const Color(0xFFEDE4DB), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showServerConfigDialog(BuildContext context) async {
    final currentCustom = await LocalStorage().getCustomApiBaseUrl();
    final controller = TextEditingController(
      text: currentCustom ?? ApiEndpoints.baseUrl,
    );
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns_rounded, color: AppColors.terracotta, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Backend API Server',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your Render backend URL (e.g. https://attendify-li14.onrender.com) or local server address.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'https://attendify-li14.onrender.com/api/v1',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      controller.text = ApiEndpoints.renderDefaultUrl;
                    },
                    child: const Text('Use Render Default', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final raw = controller.text.trim();
                      if (raw.isEmpty) {
                        await LocalStorage().saveCustomApiBaseUrl(null);
                      } else {
                        await LocalStorage().saveCustomApiBaseUrl(
                          ApiEndpoints.normalizeBaseUrl(raw),
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Endpoint'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
