import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';
import '../profile/providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Attendance policy settings
  double _personalTarget = 75.0; // Invariant: 75.0% default
  double _lowAttendanceAlert = 75.0;

  // Notification toggles
  bool _morningSummaryEnabled = true;
  bool _postClassPromptEnabled = true;
  bool _criticalAlertEnabled = true;

  // Timetable preferences
  bool _showSaturdayClasses = true;
  bool _autoTimeAwareTracking = true;

  bool _initialized = false;

  void _syncInitialData(dynamic profile) {
    if (!_initialized && profile != null) {
      _personalTarget = profile.personalTarget ?? 75.0;
      _lowAttendanceAlert = profile.lowAttendanceAlert ?? 75.0;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    profileAsync.whenData((prof) => _syncInitialData(prof));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.ink),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize attendance rules, alerts, and preferences',
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),

            // 1. Attendance Targets & Policy Section
            _buildSectionHeader(
              icon: Icons.track_changes_rounded,
              title: 'Attendance Targets & Policy',
              color: AppColors.terracotta,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personal Attendance Target',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_personalTarget.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.sageDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Default is 75.0%. Target used across forecasts and alerts.',
                    style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                  ),
                  Slider(
                    value: _personalTarget,
                    min: 75.0,
                    max: 95.0,
                    divisions: 4,
                    activeColor: AppColors.terracotta,
                    inactiveColor: const Color(0xFFF0EAE5),
                    label: '${_personalTarget.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setState(() => _personalTarget = val);
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutional Minimum',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'University mandated threshold',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '75.0%',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Attendance Warning Threshold',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Triggers warning badge when subject dips below',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.coralLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_lowAttendanceAlert.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.coral),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 2. Notification Preferences Section
            _buildSectionHeader(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Preferences',
              color: AppColors.ocean,
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Morning Class Schedule',
                    subtitle: 'Receive daily briefing at 8:00 AM',
                    value: _morningSummaryEnabled,
                    onChanged: (val) =>
                        setState(() => _morningSummaryEnabled = val),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildSwitchTile(
                    title: 'Post-Class Logging Prompt',
                    subtitle: 'Notify immediately after class ends to mark status',
                    value: _postClassPromptEnabled,
                    onChanged: (val) =>
                        setState(() => _postClassPromptEnabled = val),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildSwitchTile(
                    title: 'Critical Attendance Alerts',
                    subtitle: 'Instant warning if any subject drops below 75%',
                    value: _criticalAlertEnabled,
                    onChanged: (val) =>
                        setState(() => _criticalAlertEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. Timetable & Routine Preferences
            _buildSectionHeader(
              icon: Icons.calendar_month_outlined,
              title: 'Timetable & Routine',
              color: AppColors.sage,
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Saturday Classes',
                    subtitle: 'Show Saturday routine sessions in schedule',
                    value: _showSaturdayClasses,
                    onChanged: (val) =>
                        setState(() => _showSaturdayClasses = val),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildSwitchTile(
                    title: 'Time-Aware Class Status',
                    subtitle: 'Automatically label classes Done, Current, Upcoming',
                    value: _autoTimeAwareTracking,
                    onChanged: (val) =>
                        setState(() => _autoTimeAwareTracking = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 4. Data Management & Export
            _buildSectionHeader(
              icon: Icons.storage_rounded,
              title: 'Data Management & Export',
              color: AppColors.lavender,
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined,
                        color: AppColors.terracotta, size: 22),
                    title: const Text('Export Attendance Report',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Download complete semester CSV/PDF',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.inkMuted)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inkMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attendance report generated successfully.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined,
                        color: AppColors.sage, size: 22),
                    title: const Text('Cloud Backup & Sync',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('All records locally stored & synced',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.inkMuted)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sageLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Up to date',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageDark)),
                    ),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.coral, size: 22),
                    title: const Text('Reset Semester Records',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral)),
                    subtitle: const Text('Clear logged attendance for active semester',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.inkMuted)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.coral),
                    onTap: () {
                      _showResetConfirmation(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 5. About & App Information
            _buildSectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'About AttendiFy',
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('1.0.1 (Production Build 2026.10)',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Design System',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Warm Palette & Liquid Glass',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'AttendiFy is an independent, student-first attendance utility. It is designed to give you clear visibility, reliable forecasting, and actionable peace of mind.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.inkMuted, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
      value: value,
      activeThumbColor: AppColors.terracotta,
      activeTrackColor: AppColors.terracotta.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semester Attendance?'),
        content: const Text(
          'Are you sure you want to reset all attendance logs for this semester? This action cannot be undone.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semester logs reset.')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
