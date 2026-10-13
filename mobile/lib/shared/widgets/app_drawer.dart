import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/semesters_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/profile/providers/profile_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  final void Function(String route)? onNavigate;

  const AppDrawer({
    super.key,
    this.onNavigate,
  });

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isSemesterSelectorExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(semestersProvider).semesters.isEmpty) {
        ref.read(semestersProvider.notifier).loadSemesters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final semState = ref.watch(semestersProvider);
    final dashState = ref.watch(dashboardProvider);
    final profState = ref.watch(profileProvider);

    final activeSem = semState.activeSemester;
    final fallbackLabel = dashState.asData?.value.currentSemesterLabel ??
        profState.asData?.value.currentSemesterLabel ??
        '5th Semester';
    final activeLabel = activeSem?.label ?? fallbackLabel;
    final activeDates = activeSem != null
        ? '${activeSem.startDate} – ${activeSem.endDate}'
        : '2026-08-10 – 2026-12-20';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header: AttendHub Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.terracotta,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AttendiFy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Track • Plan • Stay Above 75%',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.inkMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  _buildNavItem(
                      icon: Icons.home_rounded,
                      title: 'Dashboard',
                      route: '/dashboard'),
                  _buildNavItem(
                      icon: Icons.schedule_rounded,
                      title: 'Routine',
                      route: '/routine'),
                  _buildNavItem(
                      icon: Icons.menu_book_rounded,
                      title: 'Subjects',
                      route: '/subjects'),
                  _buildNavItem(
                      icon: Icons.event_available_rounded,
                      title: 'Holidays',
                      route: '/holidays'),
                  _buildNavItem(
                      icon: Icons.bar_chart_rounded,
                      title: 'Analytics',
                      route: '/analytics'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      route: '/profile'),
                  _buildNavItem(
                      icon: Icons.auto_fix_high_rounded,
                      title: 'Academic Setup',
                      route: '/setup'),
                  _buildNavItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      route: '/settings'),
                  _buildNavItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      route: '/help'),
                  _buildNavItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      route: '/about'),
                ],
              ),
            ),

            // Bottom Semester Selector (expandable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3),
                border:
                    Border(top: BorderSide(color: AppColors.divider, width: 1)),
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main trigger
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isSemesterSelectorExpanded =
                            !_isSemesterSelectorExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded,
                              color: AppColors.terracotta, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeLabel,
                                  style: AppTypography.titleSmall
                                      .copyWith(fontSize: 13),
                                ),
                                Text(
                                  activeDates,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isSemesterSelectorExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded list of semesters
                  if (_isSemesterSelectorExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: semState.isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.terracotta),
                              ),
                            )
                          : semState.semesters.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No semesters configured',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: semState.semesters.length,
                                  itemBuilder: (context, index) {
                                    final sem = semState.semesters[index];
                                    final isSelected = sem.isActive;
                                    final isCompleted =
                                        sem.status == 'COMPLETED';
                                    return Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 0),
                                        title: Row(
                                          children: [
                                            Text(
                                              sem.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.terracotta
                                                    : AppColors.ink,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? const Color(0xFFF0EBE7)
                                                    : AppColors.sageLight,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isCompleted
                                                    ? 'Completed'
                                                    : (isSelected
                                                        ? 'Active'
                                                        : 'Upcoming'),
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isCompleted
                                                      ? AppColors.inkMuted
                                                      : AppColors.sageDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          '${sem.startDate} – ${sem.endDate}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.inkMuted),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_rounded,
                                                color: AppColors.terracotta,
                                                size: 18)
                                            : null,
                                        onTap: () async {
                                          setState(() {
                                            _isSemesterSelectorExpanded = false;
                                          });
                                          Navigator.of(context).pop();
                                          final success = await ref
                                              .read(semestersProvider.notifier)
                                              .switchSemester(sem.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(success
                                                    ? 'Switched to ${sem.label} context.'
                                                    : 'Failed to switch semester.'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String title, required String route}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: AppColors.inkSecondary, size: 20),
        title: Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          widget.onNavigate?.call(route);
        },
      ),
    );
  }
}
