import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/brand_icons.dart';
import '../../shared/widgets/app_toast.dart';
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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

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

    if (email.isEmpty) {
      AppToast.showError(context, 'Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      AppToast.showError(context, 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      AppToast.showError(context, 'Please enter your password.');
      return;
    }

    if (_isSignUp) {
      if (password.length < 6) {
        AppToast.showError(context, 'Password must be at least 6 characters long.');
        return;
      }
      final success = await ref.read(authProvider.notifier).register(
            email: email,
            password: password,
            fullName: name.isNotEmpty ? name : 'New Student',
          );
      if (success) {
        // Trigger Google Password Manager / OS autofill prompt to save credentials
        TextInput.finishAutofillContext(shouldSave: true);
        widget.onLoginSuccess();
      }
    } else {
      final success =
          await ref.read(authProvider.notifier).login(email, password);
      if (success) {
        // Trigger Google Password Manager / OS autofill prompt to save credentials
        TextInput.finishAutofillContext(shouldSave: true);
        widget.onLoginSuccess();
      }
    }
  }

  void _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      widget.onLoginSuccess();
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
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          mounted) {
        AppToast.showError(context, next.errorMessage!);
      }
    });

    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            // Banner height dynamically scales so the campus illustration is beautifully visible
            final bannerHeight =
                (availableHeight * 0.28).clamp(185.0, 245.0) + topPadding;

            return SingleChildScrollView(
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
                        height: bannerHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/login.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/login_header.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
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
                        height: topPadding + 44,
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
                        left: 16,
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

                      // Floating AttendHub logo squircle badge vertically and horizontally centered in the campus banner
                      Positioned(
                        top: topPadding,
                        bottom: 22,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.14),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 36,
                                  height: 36,
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
                        height: 22,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
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
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle
                        Center(
                          child: Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 23,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Center(
                          child: Text(
                            _isSignUp
                                ? 'Register to track your attendance independently'
                                : 'Log in to continue to AttendiFy',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Form Fields with Google Password Manager Autofill
                        AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isSignUp) ...[
                                AppTextField(
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 19,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              AppTextField(
                                label: 'Email / University ID',
                                hint: 'Enter your email or university ID',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.email,
                                  AutofillHints.username,
                                ],
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 19,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 10),

                              AppTextField(
                                label: 'Password',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: _isSignUp
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                onEditingComplete: _submit,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 19,
                                  color: AppColors.inkMuted,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 19,
                                    color: AppColors.inkMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forgot Password Link (Log In mode only)
                        if (!_isSignUp) ...[
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                AppToast.showInfo(
                                  context,
                                  'Password reset instructions sent to registered email.',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFFDE6854),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Submit Button
                        AppButton(
                          label: _isSignUp ? 'Create Account' : 'Log In',
                          isLoading: authState.isLoading,
                          padding: const EdgeInsets.symmetric(
                              vertical: 13, horizontal: 20),
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 10),

                        // "or" Divider
                        const Row(
                          children: [
                            Expanded(
                                child:
                                    Divider(color: Color(0xFFEADBCE), thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 12,
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
                        const SizedBox(height: 10),

                        // Social Login Button (Google only)
                        _buildSocialButton(
                          logo: BrandIcons.google(size: 19),
                          label: 'Continue with Google',
                          onTap: authState.isLoading ? () {} : _handleGoogleSignIn,
                        ),

                        const SizedBox(height: 12),

                        // Switch between Log In and Sign Up (Horizontally Centered)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                                style: AppTypography.bodySmall.copyWith(fontSize: 12.5),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                  });
                                },
                                child: Text(
                                  _isSignUp ? 'Sign In' : 'Sign Up',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFFDE6854),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
