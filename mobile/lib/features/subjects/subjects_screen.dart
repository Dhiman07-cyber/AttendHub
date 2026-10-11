import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/landscape_header.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/models/subject_model.dart';
import '../../shared/providers/semesters_provider.dart';
import 'providers/subjects_provider.dart';
import 'subject_detail_screen.dart';
import '../imports/routine_import_dialog.dart';


class SubjectsScreen extends ConsumerWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback? onNavigateToProfile;

  const SubjectsScreen({
    super.key,
    required this.onOpenDrawer,
    this.onNavigateToProfile,
  });

  void _showAddSubjectSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final facultyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Subject',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Subject Name',
                hint: 'e.g. Distributed Systems',
                controller: nameCtrl),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Subject Code (Optional)',
                hint: 'e.g. CS-505',
                controller: codeCtrl),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Faculty Name (Optional)',
                hint: 'e.g. Prof. R. Verma',
                controller: facultyCtrl),
            const SizedBox(height: 24),
            AppButton(
              label: 'Save Subject',
              showArrow: false,
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(subjectsProvider.notifier).addSubject(
                        nameCtrl.text.trim(),
                        codeCtrl.text.trim().isEmpty
                            ? null
                            : codeCtrl.text.trim(),
                        facultyCtrl.text.trim().isEmpty
                            ? null
                            : facultyCtrl.text.trim(),
                        '#C96E5B',
                        'book',
                      );
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider);
    final semState = ref.watch(semestersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LandscapeHeaderWidget(
              greeting: 'Curriculum',
              userName: 'Your Subjects',
              semesterInfo:
                  '${semState.activeSemester?.label ?? 'Active Semester'} • Courses',
              showActions: false,
              topOffset: 76,
              isLoading: state.isLoading && state.subjects.isEmpty,
            ),

            const SizedBox(height: 18),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  onChanged: (val) =>
                      ref.read(subjectsProvider.notifier).setSearchQuery(val),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search_rounded,
                        color: AppColors.inkMuted, size: 20),
                    hintText: 'Search subjects...',
                    border: InputBorder.none,
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.inkLight),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2 Action Cards: Add Subject & Upload Routine (EQUAL HEIGHT VIA IntrinsicHeight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Add Subject (Manual)
                    Expanded(
                      child: InkWell(
                        onTap: () => _showAddSubjectSheet(context, ref),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.terracotta.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.terracotta,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Add Subject',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.terracotta),
                                    ),
                                    Text(
                                      'Manual Entry',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Upload Routine (OCR / Draft)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final activeSem = semState.activeSemester;
                          if (activeSem != null) {
                            RoutineImportDialog.show(
                              context,
                              semesterId: activeSem.id,
                              onImportSuccess: () {
                                ref.read(subjectsProvider.notifier).loadSubjects();
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an active semester first.'),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),

                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD4E3EF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.ocean,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.file_upload_outlined,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Upload Routine',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.ocean),
                                    ),
                                    Text(
                                      'Image / PDF (OCR)',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Active / Inactive tabs & Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildFilterPill(
                        label:
                            'Active (${state.subjects.where((s) => s.isActive).length})',
                        isActive: !state.showInactive,
                        onTap: () => ref
                            .read(subjectsProvider.notifier)
                            .toggleFilter(false),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label:
                            'Inactive (${state.subjects.where((s) => !s.isActive).length})',
                        isActive: state.showInactive,
                        onTap: () => ref
                            .read(subjectsProvider.notifier)
                            .toggleFilter(true),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.swap_vert_rounded,
                          size: 16, color: AppColors.inkMuted),
                      SizedBox(width: 4),
                      Text('Sort',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkMuted)),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.inkMuted),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Subject Cards List (or Skeleton Loading / Empty State)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: state.isLoading && state.subjects.isEmpty
                  ? ShimmerLoading(
                      child: Column(
                        children: List.generate(
                          4,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSubjectSkeletonCard(),
                          ),
                        ),
                      ),
                    )
                  : state.filteredSubjects.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 36),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.sandLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.book_outlined,
                                    size: 24, color: AppColors.inkMuted),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No subjects found',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Add a subject or upload your class routine to start tracking.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.inkMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.filteredSubjects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sub = state.filteredSubjects[index];
                            return _buildSubjectCard(context, sub);
                          },
                        ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
      {required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.terracottaLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.terracotta.withValues(alpha: 0.5)
                : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.terracotta : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectModel sub) {
    IconData icon = Icons.book_rounded;
    if (sub.icon == 'code') icon = Icons.code_rounded;
    if (sub.icon == 'settings') icon = Icons.settings_rounded;
    if (sub.icon == 'functions') icon = Icons.functions_rounded;
    if (sub.icon == 'database') icon = Icons.storage_rounded;
    if (sub.icon == 'wifi') icon = Icons.wifi_rounded;
    if (sub.icon == 'chat') icon = Icons.chat_bubble_outline_rounded;

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SubjectDetailScreen(subject: sub)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.getSubjectColor(sub.color)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 22, color: AppColors.getSubjectColor(sub.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  if (sub.facultyName != null)
                    Text(
                      sub.facultyName!,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  const SizedBox(height: 3),
                  if (sub.scheduleSummary != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: AppColors.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          sub.scheduleSummary!,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded,
                size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.inkMuted),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSubjectSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          SkeletonBox(
            width: 42,
            height: 42,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox.text(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonBox.text(width: 90, height: 11),
                SizedBox(height: 6),
                SkeletonBox.text(width: 110, height: 10),
              ],
            ),
          ),
          SizedBox(width: 8),
          SkeletonBox(
            width: 16,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
