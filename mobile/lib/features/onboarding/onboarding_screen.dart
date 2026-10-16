import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onSignIn;
  final VoidCallback? onSkip;
  final VoidCallback? onCreateAccount;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onSignIn,
    this.onSkip,
    this.onCreateAccount,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  DateTime? _lastBackPressTime;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _handleCreateAccount();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleBackPress() {
    if (_currentPage > 0) {
      _previousPage();
      return;
    }
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit AttendHub'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  void _handleSkip() async {
    await LocalStorage().setOnboarded(true);
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onFinish();
    }
  }

  void _handleCreateAccount() async {
    await LocalStorage().setOnboarded(true);
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
    } else {
      widget.onFinish();
    }
  }

  void _handleSignIn() async {
    await LocalStorage().setOnboarded(true);
    widget.onSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-screen campus illustration backdrop spanning the WHOLE screen
            Image.asset(
              'assets/images/landing_vertical.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/landing.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                );
              },
            ),

            // 2. Delicate luminous warm scrim overlay:
            // Keeps the campus illustration visibly clear and lookable,
            // while guaranteeing crystal-clear WCAG AA contrast for text & cards.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.28, 0.65, 1.0],
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.35),
                    const Color(0xFFF7F1EC).withValues(alpha: 0.72),
                    const Color(0xFFF7F1EC).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),

            // 3. Foreground interactive UI in SafeArea
            SafeArea(
              child: Column(
                children: [
                  // Top App Bar
                  _buildTopBar(),

                  // High-performance interactive PageView
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      children: [
                        _buildPageOne(),
                        _buildPageTwo(),
                        _buildPageThree(),
                      ],
                    ),
                  ),

                  // Bottom Navigation & Controls
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Logo on Page 1, or Frosted Back Button on Pages 2 & 3
            if (_currentPage == 0)
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(201, 110, 91, 0.25),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AttendiFy',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _previousPage,
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
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),

            // Right: Frosted Skip button on Page 1, or Page indicator on Pages 2 & 3
            if (_currentPage == 0)
              InkWell(
                onTap: _handleSkip,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Skip',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.inkSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_currentPage + 1} / 3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 1: Track Every Class, Stay Ahead of 75% Always
  // Cards placed lower with all inner text and card contents horizontally centered
  // -------------------------------------------------------------
  Widget _buildPageOne() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;
        final isUltraShort = availableHeight < 520;
        final cardAspectRatio = isUltraShort ? 1.35 : (isShort ? 1.22 : 1.16);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 4 : 8),

              // Title - 3-Line punchy headline with theme-colored 75%
              Text.rich(
                TextSpan(
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: isUltraShort ? 24 : (isShort ? 26 : 30),
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    color: AppColors.ink,
                  ),
                  children: const [
                    TextSpan(text: 'Track Every Class,\n'),
                    TextSpan(text: 'Stay Ahead of\n'),
                    TextSpan(
                      text: '75%',
                      style: TextStyle(
                        color: Color(0xFFDE6854),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(text: ' Always'),
                  ],
                ),
              ),

              SizedBox(height: isShort ? 6 : 10),

              // Subtitle
              Text(
                'Manage your classes, track attendance, get smart insights and never miss your academic goals.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 13.5,
                  height: 1.35,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Cards placed visibly lower as requested
              SizedBox(height: isUltraShort ? 24 : (isShort ? 38 : 54)),

              // 2x2 Feature Grid - Horizontally centered inner contents with zero clipping
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cardAspectRatio,
                children: [
                  _buildFeatureBadge(
                    icon: Icons.calendar_today_rounded,
                    iconBg: const Color(0xFFFDEEEB),
                    iconColor: const Color(0xFFDE6854),
                    title: 'Track Attendance',
                    subtitle: 'Know your progress in real time',
                    isCompact: isShort,
                  ),
                  _buildFeatureBadge(
                    icon: Icons.insights_rounded,
                    iconBg: const Color(0xFFEBF5EF),
                    iconColor: AppColors.sage,
                    title: 'Smart Analytics',
                    subtitle: 'Stay above 75% with insights',
                    isCompact: isShort,
                  ),
                  _buildFeatureBadge(
                    icon: Icons.event_note_rounded,
                    iconBg: const Color(0xFFEBF3F8),
                    iconColor: AppColors.ocean,
                    title: 'Manage Holidays',
                    subtitle: 'Add or upload holiday lists',
                    isCompact: isShort,
                  ),
                  _buildFeatureBadge(
                    icon: Icons.school_outlined,
                    iconBg: const Color(0xFFF2EDF8),
                    iconColor: AppColors.lavender,
                    title: 'Organize Subjects',
                    subtitle: 'Manage all your semester subjects',
                    isCompact: isShort,
                  ),
                ],
              ),

              SizedBox(height: isShort ? 8 : 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(50, 30, 20, 0.05),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 34 : 38,
            height: isCompact ? 34 : 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isCompact ? 18 : 20, color: iconColor),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 12 : 13.5,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              color: AppColors.inkMuted,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 2: Smart Analytics for Safe Decisions
  // -------------------------------------------------------------
  // SLIDE 2: Smart Analytics for Safe Decisions
  // Mathematics & Computer Applications Side-by-Side and Vertically Centered
  // Clean, uncluttered, focused promotional cards with background visible
  // -------------------------------------------------------------
  Widget _buildPageTwo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;
        final isUltraShort = availableHeight < 520;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 4 : 8),

              // Title with themed colored words
              Text.rich(
                TextSpan(
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: isUltraShort ? 24 : (isShort ? 26 : 30),
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    color: AppColors.ink,
                  ),
                  children: const [
                    TextSpan(text: 'Smart Analytics\nfor '),
                    TextSpan(
                      text: 'Safe Decisions',
                      style: TextStyle(
                        color: Color(0xFFDE6854),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isShort ? 6 : 10),

              Text(
                'Predict your attendance beforehand. Know exactly how many classes you need to attend or can safely miss.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 13.5,
                  height: 1.35,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isUltraShort ? 24 : (isShort ? 38 : 54)),

              // Side-by-Side Cards: Mathematics & Computer Applications
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Mathematics (Target Recovery)
                  Expanded(
                    child: _buildSideBySideForecastCard(
                      subject: 'Mathematics',
                      percentage: '68.2%',
                      progress: 0.682,
                      themeColor: const Color(0xFFDE6854),
                      icon: Icons.calculate_rounded,
                      iconBg: const Color(0xFFFDEEEB),
                      badgeIcon: Icons.track_changes_rounded,
                      badgeHeadline: 'Need 2 classes',
                      badgeDetail: 'for 75% target',
                      isWarning: true,
                      isShort: isShort,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Card 2: Computer Applications (Safe Absences)
                  Expanded(
                    child: _buildSideBySideForecastCard(
                      subject: 'Computer Apps',
                      percentage: '84.0%',
                      progress: 0.840,
                      themeColor: AppColors.sageDark,
                      icon: Icons.code_rounded,
                      iconBg: const Color(0xFFEDF6F1),
                      badgeIcon: Icons.shield_outlined,
                      badgeHeadline: '3 safe absences',
                      badgeDetail: 'above 75% margin',
                      isWarning: false,
                      isShort: isShort,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isShort ? 14 : 20),

              // Promotional feature highlights
              Row(
                children: [
                  Expanded(
                    child: _buildMiniPromoPill(
                      icon: Icons.auto_graph_rounded,
                      iconColor: const Color(0xFFDE6854),
                      text: 'Live Target Forecaster',
                      isShort: isShort,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniPromoPill(
                      icon: Icons.security_rounded,
                      iconColor: AppColors.sageDark,
                      text: 'Zero Shortage Guarantee',
                      isShort: isShort,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isShort ? 8 : 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideBySideForecastCard({
    required String subject,
    required String percentage,
    required double progress,
    required Color themeColor,
    required IconData icon,
    required Color iconBg,
    required IconData badgeIcon,
    required String badgeHeadline,
    required String badgeDetail,
    required bool isWarning,
    required bool isShort,
  }) {
    final bannerBg =
        isWarning ? const Color(0xFFFDEEEB) : const Color(0xFFEDF6F1);
    final bannerBorder =
        isWarning ? const Color(0xFFF7D1CA) : const Color(0xFFCFE8D9);
    final headlineColor =
        isWarning ? const Color(0xFFC7513E) : AppColors.sageDark;

    return Container(
      padding: EdgeInsets.all(isShort ? 10 : 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(50, 30, 20, 0.05),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge + Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: isShort ? 28 : 32,
                height: isShort ? 28 : 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: isShort ? 16 : 18, color: themeColor),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isShort ? 13.5 : 15,
                  color: themeColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isShort ? 8 : 10),

          // Subject name
          Text(
            subject,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: isShort ? 12 : 13.5,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isShort ? 6 : 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: themeColor.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: isShort ? 4.5 : 5.5,
            ),
          ),
          SizedBox(height: isShort ? 9 : 11),

          // Promotion Pill
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isShort ? 7 : 9,
              vertical: isShort ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bannerBorder, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(badgeIcon,
                        size: isShort ? 13 : 15, color: headlineColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        badgeHeadline,
                        style: TextStyle(
                          fontSize: isShort ? 10.5 : 11.5,
                          fontWeight: FontWeight.w800,
                          color: headlineColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  badgeDetail,
                  style: TextStyle(
                    fontSize: isShort ? 9.5 : 10.5,
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPromoPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isShort,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isShort ? 8 : 12,
        vertical: isShort ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isShort ? 14 : 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isShort ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 3: Smart Routine & Holiday Sync
  // Clean, uncluttered showcase of routine import, holiday exclusions, and fast tracking
  // -------------------------------------------------------------
  Widget _buildPageThree() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;
        final isUltraShort = availableHeight < 520;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 4 : 8),

              // Title with themed colored word
              Text.rich(
                TextSpan(
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: isUltraShort ? 24 : (isShort ? 26 : 30),
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    color: AppColors.ink,
                  ),
                  children: const [
                    TextSpan(text: 'Smart Routine &\n'),
                    TextSpan(
                      text: 'Holiday Sync',
                      style: TextStyle(
                        color: Color(0xFFDE6854),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isShort ? 6 : 10),

              Text(
                'Upload your timetable once. AttendHub automatically maps your schedule and excludes all college holidays from conducted totals.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 13.5,
                  height: 1.35,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isUltraShort ? 24 : (isShort ? 38 : 54)),

              // Single Spacious Automation Showcase Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isShort ? 14 : 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(50, 30, 20, 0.05),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSyncFeatureRow(
                      icon: Icons.document_scanner_rounded,
                      iconBg: const Color(0xFFEBF3F8),
                      iconColor: AppColors.ocean,
                      title: 'Smart Timetable Import',
                      subtitle:
                          'Upload timetable image or PDF to auto-map daily class slots',
                      isShort: isShort,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: isShort ? 10 : 14),
                      child: const Divider(color: Color(0xFFEDE4DB), height: 1),
                    ),
                    _buildSyncFeatureRow(
                      icon: Icons.event_available_rounded,
                      iconBg: const Color(0xFFFAF3E8),
                      iconColor: AppColors.amber,
                      title: 'Automatic Holiday Exclusions',
                      subtitle:
                          'College holidays & cancelled sessions never reduce your percentage',
                      isShort: isShort,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: isShort ? 10 : 14),
                      child: const Divider(color: Color(0xFFEDE4DB), height: 1),
                    ),
                    _buildSyncFeatureRow(
                      icon: Icons.touch_app_rounded,
                      iconBg: const Color(0xFFEDF6F1),
                      iconColor: AppColors.sageDark,
                      title: '1-Tap Daily Marking',
                      subtitle:
                          'Quickly mark Attended, Absent, or Class Not Held in seconds',
                      isShort: isShort,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isShort ? 16 : 22),

              // Setup in under 2 minutes reassurance pill
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFEADBCE), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 17,
                        color: Color(0xFFDE6854),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Takes less than 2 minutes to get started',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isShort ? 8 : 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncFeatureRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isShort,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isShort ? 36 : 42,
          height: isShort ? 36 : 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: isShort ? 20 : 22, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isShort ? 13 : 14,
                  color: AppColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isShort ? 10.5 : 11.5,
                  color: AppColors.inkSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // BOTTOM CONTROLS (Dots + Main Button + Sign In footer)
  // -------------------------------------------------------------
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDE6854)
                      : const Color(0xFFE2D9CF),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Primary CTA Button
          AppButton(
            label: _currentPage == 0
                ? 'Get Started'
                : _currentPage == 1
                    ? 'Next'
                    : 'Create Account',
            onPressed: _nextPage,
          ),
          const SizedBox(height: 12),

          // Footer Sign In link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: AppTypography.bodySmall,
              ),
              GestureDetector(
                onTap: _handleSignIn,
                child: Text(
                  'Sign In',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFDE6854),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
