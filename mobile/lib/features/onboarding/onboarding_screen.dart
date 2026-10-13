import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleCreateAccount();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),

            // Interactive Page View
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
            // Left: Logo on Page 1, or Back Button on Pages 2 & 3
            if (_currentPage == 0)
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(201, 110, 91, 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AttendiFy',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 6,
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

            // Right: Skip button on Page 1, or Page indicator on Pages 2 & 3
            if (_currentPage == 0)
              InkWell(
                onTap: _handleSkip,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.03),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'Skip',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
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
  // SLIDE 1: Track Today, Stay Above 75% Always
  // -------------------------------------------------------------
  Widget _buildPageOne() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 560;
        final imageHeight = isShort ? 145.0 : 180.0;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title & Subtitle with horizontal padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isShort ? 2 : 6),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: isShort ? 27 : 31,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'serif',
                          color: AppColors.ink,
                        ),
                        children: const [
                          TextSpan(text: 'Track Today,\nStay Above\n'),
                          TextSpan(
                            text: '75% ',
                            style: TextStyle(
                              color: Color(0xFFDE6854),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: 'Always'),
                        ],
                      ),
                    ),
                    SizedBox(height: isShort ? 4 : 8),
                    Text(
                      'Manage your classes, track attendance, get smart insights and never miss your academic goals.',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: isShort ? 12.5 : 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isShort ? 8 : 12),

              // 2. Seamless full-width campus illustration
              // Integrated directly into page background with NO boundary and feathered sideways/vertical gradients
              SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Master campus illustration
                    Image.asset(
                      'assets/images/landing.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(-0.35, 0.0),
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/landing_hero.png',
                          fit: BoxFit.cover,
                          alignment: const Alignment(-0.35, 0.0),
                        );
                      },
                    ),

                    // Atmospheric theme wash
                    Container(
                      color: const Color(0xFFF7F1EC).withValues(alpha: 0.08),
                    ),

                    // Sideways gradient vignette (feathers left and right edges seamlessly into the BG)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.14, 0.86, 1.0],
                          colors: [
                            AppColors.background,
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),

                    // Vertical vignette (softly fades top and bottom edges into the page background)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.16, 0.80, 1.0],
                          colors: [
                            AppColors.background,
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isShort ? 8 : 12),

              // 3. 4 Feature Cards (2x2 Grid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isShort ? 1.55 : 1.35,
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
              ),
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
      padding: EdgeInsets.all(isCompact ? 9 : 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE5DC), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.025),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 28 : 32,
            height: isCompact ? 28 : 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isCompact ? 16 : 18, color: iconColor),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 12 : 13,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: isCompact ? 9.5 : 10.5,
                color: AppColors.inkMuted,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SLIDE 2: Smart Analytics for Better Decisions
  // (Universal subjects relatable for B.Tech, School, BCA, etc.)
  // -------------------------------------------------------------
  Widget _buildPageTwo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 560;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 2 : 6),

              Text(
                'Smart Analytics\nfor Better Decisions',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: isShort ? 26 : 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: isShort ? 4 : 8),

              Text(
                'Get subject-wise attendance, know how many classes you can still miss, and stay on track automatically.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 14,
                  height: 1.25,
                ),
              ),
              SizedBox(height: isShort ? 8 : 14),

              // Phone Graphic Container with Universal Subject Cards
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, isShort ? 10 : 14, 14, isShort ? 10 : 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EE),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFEADBCE),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(58, 35, 25, 0.06),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Mock Phone Top Speaker Pill
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD2C6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: isShort ? 8 : 12),

                    // Card 1: Mathematics
                    _buildInteractiveSubjectCard(
                      iconBadge: const Text(
                        'Σ',
                        style: TextStyle(
                          color: Color(0xFF7E64A5),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      iconBg: const Color(0xFFF1ECF8),
                      title: 'Mathematics',
                      percentage: '68.2%',
                      barValue: 0.682,
                      barColor: const Color(0xFFDE6854),
                      chipBg: const Color(0xFFFDEEEB),
                      chipBorder: const Color(0xFFF7D1CA),
                      chipIcon: Icons.warning_amber_rounded,
                      chipIconColor: const Color(0xFFDE6854),
                      chipText: 'Below target. Need 2 more classes to reach 75%.',
                      chipTextColor: const Color(0xFFC7513E),
                    ),
                    SizedBox(height: isShort ? 8 : 10),

                    // Card 2: Computer Applications
                    _buildInteractiveSubjectCard(
                      iconBadge: const Icon(
                        Icons.code_rounded,
                        color: Color(0xFFDE6854),
                        size: 18,
                      ),
                      iconBg: const Color(0xFFFDF0ED),
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
                    ),
                    SizedBox(height: isShort ? 8 : 10),

                    // Card 3: General English & Communication
                    _buildInteractiveSubjectCard(
                      iconBadge: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFD9A35B),
                        size: 17,
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
                      chipText: 'Approaching 75%. Attend next class to stay safe.',
                      chipTextColor: const Color(0xFF9E6E2B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveSubjectCard({
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4DB), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: iconBadge,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: barColor.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),

          // Status Alert Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chipBorder, width: 0.9),
            ),
            child: Row(
              children: [
                Icon(chipIcon, size: 13, color: chipIconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: chipTextColor,
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

  // -------------------------------------------------------------
  // SLIDE 3: Plan Your Semester Effortlessly
  // -------------------------------------------------------------
  Widget _buildPageThree() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isShort = availableHeight < 560;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isShort ? 2 : 6),

              Text(
                'Plan Your Semester\nEffortlessly',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: isShort ? 26 : 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: isShort ? 4 : 8),

              Text(
                'Add your subjects, upload your routine or holiday list, and let the app handle the rest.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: isShort ? 12.5 : 14,
                  height: 1.25,
                ),
              ),
              SizedBox(height: isShort ? 8 : 14),

              // Mockup Shell with Semester Dropdown & Subjects
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EE),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFEADBCE),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(58, 35, 25, 0.05),
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Term Pill & Floating Calendar Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5DDD2)),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Current Semester',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.ink,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.inkMuted),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEEEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF7D1CA)),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 17,
                            color: Color(0xFFDE6854),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick list of subjects
                    _buildSemesterSubjectItem(
                        icon: Icons.code_rounded,
                        color: const Color(0xFFDE6854),
                        title: 'Computer Applications'),
                    const SizedBox(height: 6),
                    _buildSemesterSubjectItem(
                        icon: Icons.settings_suggest_rounded,
                        color: AppColors.ocean,
                        title: 'Digital Systems'),
                    const SizedBox(height: 6),
                    _buildSemesterSubjectItem(
                        icon: Icons.functions_rounded,
                        color: AppColors.lavender,
                        title: 'Mathematics'),
                    const SizedBox(height: 6),
                    _buildSemesterSubjectItem(
                        icon: Icons.menu_book_rounded,
                        color: AppColors.amber,
                        title: 'English & Communication'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Cards: Upload Routine vs Add Manually
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4E3EF)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.04),
                                  blurRadius: 4,
                                ),
                              ],
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
                        color: const Color(0xFFFDF0ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF5D6CE)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.04),
                                  blurRadius: 4,
                                ),
                              ],
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
                            '(Subject, Time, Faculty)',
                            style:
                                AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Checklist Points
              _buildCheckItem('Quick and easy setup'),
              const SizedBox(height: 8),
              _buildCheckItem('Supports image/PDF upload (OCR)'),
              const SizedBox(height: 8),
              _buildCheckItem('Works for all semesters & curriculums'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterSubjectItem({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE4DC)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
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
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.sage,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
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
          const SizedBox(height: 18),

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
