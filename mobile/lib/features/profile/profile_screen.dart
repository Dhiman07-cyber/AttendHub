import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/providers/dashboard_provider.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback? onOpenSetup;

  const ProfileScreen({
    super.key,
    required this.onBack,
    this.onOpenSetup,
  });

  void _showEditFieldSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String initialValue,
    required String fieldKey,
    String? hintText,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.inkMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      final newVal = ctrl.text.trim();
                      if (newVal.isNotEmpty) {
                        Navigator.pop(ctx);
                        try {
                          final client = ApiClient();
                          await client.dio.patch(
                            ApiEndpoints.profile,
                            data: {fieldKey: newVal},
                          );
                          ref.invalidate(profileProvider);
                          ref.invalidate(dashboardProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$title updated successfully'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update field. Please retry.'),
                                backgroundColor: AppColors.coral,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.ink),
          onPressed: onBack,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        // No edit button in actions as requested
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.terracotta)),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your academic details and preferences',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),

              // Compact User Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A2421),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _showEditFieldSheet(
                                  context: context,
                                  ref: ref,
                                  title: 'Edit Full Name',
                                  initialValue: profile.fullName,
                                  fieldKey: 'full_name',
                                  hintText: 'Enter your full name',
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: AppColors.terracotta,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (profile.studentIdNumber != null &&
                              profile.studentIdNumber!.isNotEmpty)
                            Text(
                              profile.studentIdNumber!,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            profile.courseName,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.terracotta,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Academic Information Section
              _buildSectionHeader(Icons.school_rounded, 'Academic Information'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.account_balance_outlined,
                      label: 'University',
                      value: profile.universityName,
                      isEditable: true,
                      onTap: () => _showEditFieldSheet(
                        context: context,
                        ref: ref,
                        title: 'Edit University Name',
                        initialValue: profile.universityName,
                        fieldKey: 'university_name',
                        hintText: 'Enter university name',
                      ),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Course',
                      value: profile.courseName,
                      isEditable: true,
                      onTap: () => _showEditFieldSheet(
                        context: context,
                        ref: ref,
                        title: 'Edit Course Name',
                        initialValue: profile.courseName,
                        fieldKey: 'course_name',
                        hintText: 'Enter course name',
                      ),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.badge_outlined,
                      label: 'Student ID',
                      value: profile.studentIdNumber ?? 'Not Set',
                      isEditable: true,
                      onTap: () => _showEditFieldSheet(
                        context: context,
                        ref: ref,
                        title: 'Edit Student ID / Roll',
                        initialValue: profile.studentIdNumber ?? '',
                        fieldKey: 'student_id_number',
                        hintText: 'Enter student ID or roll number',
                      ),
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.date_range_outlined,
                      label: 'Total Years',
                      value: '${profile.academicDurationYears} Years',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.layers_outlined,
                      label: 'Current Semester',
                      value: profile.currentSemesterLabel ?? 'Active Semester',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Semester changes are managed via Academic Setup Wizard below.',
                            ),
                            action: onOpenSetup != null
                                ? SnackBarAction(
                                    label: 'Open Wizard',
                                    textColor: AppColors.amber,
                                    onPressed: onOpenSetup!,
                                  )
                                : null,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Academic Session',
                      value:
                          '${profile.academicSessionStart ?? 2024} – ${profile.academicSessionEnd ?? 2028}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Attendance Settings Section
              _buildSectionHeader(
                  Icons.track_changes_rounded, 'Attendance Settings'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.timer_outlined,
                      label: 'Target Attendance',
                      value:
                          '${profile.personalTarget.toStringAsFixed(0)}% (Default)',
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    _buildRowItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Low Attendance Alert',
                      value:
                          '${profile.lowAttendanceAlert.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Logout Button
              InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.coral.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.coral, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title,
      {Color color = AppColors.terracotta}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required String label,
    required String value,
    bool isEditable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon & label with dedicated fixed width for clean alignment
            Icon(icon, size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Right value aligned to the rightmost edge with multi-line wrapping
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                  if (isEditable) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: AppColors.terracotta,
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
}
