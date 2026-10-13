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
  // 3-Line Headline & Well-Proportioned 2x2 Grid (No center void, No clipping)
  // -------------------------------------------------------------
  Widget _buildPageOne() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;
        final isUltraShort = availableHeight < 520;
        final cardAspectRatio = isUltraShort ? 1.35 : (isShort ? 1.20 : 1.14);

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

              SizedBox(height: isShort ? 16 : 22),

              // 2x2 Feature Grid - Taller cards, comfortably proportioned with zero clipping
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
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 10 : 12,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 32 : 36,
            height: isCompact ? 32 : 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isCompact ? 17 : 19, color: iconColor),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            title,
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
  // Lightweight Frosted Glass Cards (Campus background clearly visible)
  // 5 Universal Subjects with clean calculator icon
  // -------------------------------------------------------------
  Widget _buildPageTwo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;

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
                    fontSize: isShort ? 26 : 30,
                    height: 1.15,
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
              SizedBox(height: isShort ? 6 : 8),

              Text(
                'Get subject-wise attendance, know how many classes you can still miss, and stay on track automatically.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 13.5,
                  height: 1.3,
                  color: AppColors.inkSecondary,
                ),
              ),
              SizedBox(height: isShort ? 12 : 16),

              // 5 Lightweight Frosted Glass Subject Cards - letting campus backdrop show through
              Column(
                children: [
                  // Card 1: Mathematics (Clean calculator icon, Class 10 / college)
                  _buildLightweightSubjectCard(
                    iconBadge: const Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFFDE6854),
                      size: 18,
                    ),
                    iconBg: const Color(0xFFFDEEEB),
                    title: 'Mathematics',
                    percentage: '68.2%',
                    barValue: 0.682,
                    barColor: const Color(0xFFDE6854),
                    chipBg: const Color(0xFFFDEEEB),
                    chipBorder: const Color(0xFFF7D1CA),
                    chipIcon: Icons.warning_amber_rounded,
                    chipIconColor: const Color(0xFFDE6854),
                    chipText: 'Below target • Need 2 more classes for 75%',
                    chipTextColor: const Color(0xFFC7513E),
                    isCompact: isShort,
                  ),
                  SizedBox(height: isShort ? 7 : 9),

                  // Card 2: Computer Applications
                  _buildLightweightSubjectCard(
                    iconBadge: const Icon(
                      Icons.code_rounded,
                      color: AppColors.sageDark,
                      size: 18,
                    ),
                    iconBg: const Color(0xFFEDF6F1),
                    title: 'Computer Applications',
                    percentage: '82.5%',
                    barValue: 0.825,
                    barColor: AppColors.sage,
                    chipBg: const Color(0xFFEDF6F1),
                    chipBorder: const Color(0xFFCFE8D9),
                    chipIcon: Icons.check_circle_outline_rounded,
                    chipIconColor: AppColors.sageDark,
                    chipText: 'On track! You can miss up to 2 classes safely.',
                    chipTextColor: AppColors.sageDark,
                    isCompact: isShort,
                  ),
                  SizedBox(height: isShort ? 7 : 9),

                  // Card 3: English & Communication
                  _buildLightweightSubjectCard(
                    iconBadge: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFD9A35B),
                      size: 18,
                    ),
                    iconBg: const Color(0xFFFAF3E8),
                    title: 'English & Communication',
                    percentage: '74.1%',
                    barValue: 0.741,
                    barColor: AppColors.amber,
                    chipBg: const Color(0xFFFAF3E8),
                    chipBorder: const Color(0xFFF5E4CA),
                    chipIcon: Icons.info_outline_rounded,
                    chipIconColor: const Color(0xFFB8853E),
                    chipText: 'Approaching 75% • Attend next class to stay safe.',
                    chipTextColor: const Color(0xFF9E6E2B),
                    isCompact: isShort,
                  ),
                  SizedBox(height: isShort ? 7 : 9),

                  // Card 4: Science & Lab
                  _buildLightweightSubjectCard(
                    iconBadge: const Icon(
                      Icons.science_rounded,
                      color: AppColors.ocean,
                      size: 18,
                    ),
                    iconBg: const Color(0xFFEBF3F8),
                    title: 'Science & Lab',
                    percentage: '78.6%',
                    barValue: 0.786,
                    barColor: AppColors.ocean,
                    chipBg: const Color(0xFFEBF3F8),
                    chipBorder: const Color(0xFFD4E3EF),
                    chipIcon: Icons.check_circle_outline_rounded,
                    chipIconColor: AppColors.ocean,
                    chipText: 'Safe margin • 1 safe absence available.',
                    chipTextColor: AppColors.ocean,
                    isCompact: isShort,
                  ),
                  SizedBox(height: isShort ? 7 : 9),

                  // Card 5: Social Studies
                  _buildLightweightSubjectCard(
                    iconBadge: const Icon(
                      Icons.public_rounded,
                      color: AppColors.lavender,
                      size: 18,
                    ),
                    iconBg: const Color(0xFFF2EDF8),
                    title: 'Social Studies',
                    percentage: '85.0%',
                    barValue: 0.850,
                    barColor: AppColors.lavender,
                    chipBg: const Color(0xFFF2EDF8),
                    chipBorder: const Color(0xFFDFD4EE),
                    chipIcon: Icons.verified_rounded,
                    chipIconColor: AppColors.lavender,
                    chipText: 'Excellent • 3 safe absences available.',
                    chipTextColor: AppColors.lavender,
                    isCompact: isShort,
                  ),
                ],
              ),

              SizedBox(height: isShort ? 10 : 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLightweightSubjectCard({
    required Widget iconBadge,
    required Color iconBg,
    required String title,
    required String percentage,
    required double barValue,
    required Color barColor,
    required Color chipBg,
    required Color chipBorder,
    required IconData chipIcon,
    required Color chipIconColor,
    required String chipText,
    required Color chipTextColor,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: isCompact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(50, 30, 20, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 28 : 30,
                height: isCompact ? 28 : 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: iconBadge,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 12.5 : 13.5,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 12.5 : 13.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: isShort(isCompact) ? 5 : 7),

          // Progress Bar with rounded ends
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: barColor.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: isCompact ? 4.5 : 5.5,
            ),
          ),
          SizedBox(height: isShort(isCompact) ? 5 : 7),

          // Status Alert Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: chipBorder, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(chipIcon, size: 12, color: chipIconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 10.5,
                      fontWeight: FontWeight.w600,
                      color: chipTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isShort(bool compact) => compact;

  // -------------------------------------------------------------
  // SLIDE 3: Plan Your Semester Effortlessly
  // Themed header, cohesive Wednesday schedule, Upload Routine & Add Manually
  // -------------------------------------------------------------
  Widget _buildPageThree() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 620;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 2 : 6),

              // Title with themed colored word
              Text.rich(
                TextSpan(
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: isShort ? 26 : 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    color: AppColors.ink,
                  ),
                  children: const [
                    TextSpan(text: 'Plan Your Semester\n'),
                    TextSpan(
                      text: 'Effortlessly',
                      style: TextStyle(
                        color: Color(0xFFDE6854),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isShort ? 6 : 8),

              Text(
                'Add your subjects, upload your routine or holiday list, and let AttendHub handle all the math.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 13.5,
                  height: 1.3,
                  color: AppColors.inkSecondary,
                ),
              ),
              SizedBox(height: isShort ? 12 : 16),

              // Themed Wednesday Timetable Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isShort ? 12 : 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(58, 35, 25, 0.04),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with deep Ink title & terracotta accent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEEEB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: Color(0xFFDE6854),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Wednesday Schedule',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: AppColors.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEEEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF7D1CA)),
                          ),
                          child: const Text(
                            '3 Classes Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDE6854),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Routine Items with clear contrast
                    _buildThemedRoutineItem(
                      time: '09:30 AM',
                      title: 'Computer Applications',
                      venue: 'Lab 3',
                      status: 'Attended',
                      statusColor: AppColors.sageDark,
                      statusBg: const Color(0xFFEDF6F1),
                    ),
                    const SizedBox(height: 8),

                    _buildThemedRoutineItem(
                      time: '11:15 AM',
                      title: 'Mathematics',
                      venue: 'Room 302',
                      status: 'Current',
                      statusColor: const Color(0xFFDE6854),
                      statusBg: const Color(0xFFFDEEEB),
                    ),
                    const SizedBox(height: 8),

                    _buildThemedRoutineItem(
                      time: '02:00 PM',
                      title: 'English & Communication',
                      venue: 'Hall A',
                      status: 'Upcoming',
                      statusColor: AppColors.inkSecondary,
                      statusBg: const Color(0xFFF2ECE4),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isShort ? 12 : 16),

              // Action Cards: Upload Routine vs Add Manually
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFD4E3EF), width: 1.1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.03),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBF3F8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppColors.ocean,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload Routine',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '(Image / PDF)',
                            style:
                                AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFF5D6CE), width: 1.1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.03),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDEEEB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Color(0xFFDE6854),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add Manually',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '(Subject, Time, Venue)',
                            style:
                                AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isShort ? 12 : 16),

              // Checklist Item
              _buildCheckItem('Quick and easy setup'),

              SizedBox(height: isShort ? 10 : 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemedRoutineItem({
    required String time,
    required String title,
    required String venue,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE4DB)),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  venue,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.sage,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.ink,
            ),
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
