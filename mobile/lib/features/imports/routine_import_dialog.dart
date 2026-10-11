import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../shared/widgets/app_button.dart';

class RoutineImportDialog extends StatefulWidget {
  final String semesterId;
  final VoidCallback onImportSuccess;

  const RoutineImportDialog({
    super.key,
    required this.semesterId,
    required this.onImportSuccess,
  });

  static Future<void> show(BuildContext context, {
    required String semesterId,
    required VoidCallback onImportSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoutineImportDialog(
        semesterId: semesterId,
        onImportSuccess: onImportSuccess,
      ),
    );
  }

  @override
  State<RoutineImportDialog> createState() => _RoutineImportDialogState();
}

class _RoutineImportDialogState extends State<RoutineImportDialog> {
  final ApiClient _client = ApiClient();
  final TextEditingController _csvInputCtrl = TextEditingController();

  bool _isParsing = false;
  bool _isConfirming = false;
  String? _errorMessage;
  List<String> _warnings = [];

  // Draft items in memory only (never saved to database until confirmed)
  List<Map<String, dynamic>> _draftEntries = [];
  bool _hasParsedDraft = false;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void dispose() {
    _csvInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _parseTextOrSample() async {
    final text = _csvInputCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please paste CSV or formatted routine text.');
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = null;
      _warnings = [];
    });

    try {
      final bytes = utf8.encode(text);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'routine_import.csv'),
      });

      final resp = await _client.dio.post(
        ApiEndpoints.importRoutineParse,
        data: formData,
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        final rawDrafts = (data['draft_routine'] as List?) ?? [];
        final warnings = (data['warning_notes'] as List?)?.map((w) => w.toString()).toList() ?? [];

        setState(() {
          _isParsing = false;
          _hasParsedDraft = true;
          _warnings = warnings;
          _draftEntries = rawDrafts.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Failed to parse document. Please check the format.';
      });
    }
  }

  Future<void> _confirmAndSave() async {
    if (_draftEntries.isEmpty) {
      setState(() => _errorMessage = 'No draft entries to confirm.');
      return;
    }

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'semester_id': widget.semesterId,
        'entries': _draftEntries.map((e) => {
          'subject_name': e['subject_name'],
          'subject_code': e['subject_code'],
          'faculty_name': e['faculty_name'],
          'day_of_week': e['day_of_week'] ?? 0,
          'start_time': e['start_time'],
          'end_time': e['end_time'],
          'room': e['room'],
        }).toList(),
      };

      final resp = await _client.dio.post(
        ApiEndpoints.importRoutineConfirm,
        data: payload,
      );

      if (resp.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          widget.onImportSuccess();
        }
      }
    } catch (e) {
      setState(() {
        _isConfirming = false;
        _errorMessage = 'Failed to commit routine to database.';
      });
    }
  }

  void _discardDraft() {
    setState(() {
      _draftEntries.clear();
      _hasParsedDraft = false;
      _warnings.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 20,
        top: 20,
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ocean.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: AppColors.ocean, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Import Routine',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Draft-Only Lifecycle: Extracted records remain in editable review until you explicitly confirm. Discarding writes 0 records to the database.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 14),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

          // Content: Parser Input vs Editable Review Draft
          Expanded(
            child: _hasParsedDraft ? _buildDraftReview() : _buildInputView(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste CSV or Structured Timetable Text:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Format: Subject, Code, Faculty, Day(0=Mon..6=Sun), StartTime, EndTime, Room',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _csvInputCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Software Engineering, CS-501, Prof. Sharma, 0, 09:00, 10:00, Room 101\nOperating Systems, CS-502, Prof. Das, 1, 11:00, 12:00, Room 203',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              TextButton(
                onPressed: () {
                  _csvInputCtrl.text =
                      'Software Engineering, CS-501, Prof. A. Sharma, 0, 09:00, 10:00, Room 101\n'
                      'Operating Systems, CS-502, Prof. R. Das, 1, 11:00, 12:00, Room 203\n'
                      'Mathematics, MA-501, Prof. K. Deka, 2, 14:00, 15:00, Room 305\n'
                      'Database Management, CS-503, Prof. M. Ali, 3, 16:00, 17:00, Lab 1';
                },
                child: const Text('Insert Sample Template', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ocean,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isParsing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Parse Into Draft'),
                onPressed: _isParsing ? null : _parseTextOrSample,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_warnings.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _warnings.join(' '),
                    style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extracted Draft Entries (${_draftEntries.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Discard Draft', style: TextStyle(color: AppColors.coral)),
              onPressed: _discardDraft,
            ),
          ],
        ),

        Expanded(
          child: _draftEntries.isEmpty
              ? const Center(
                  child: Text('No structured entries found. Try adjusting input.', style: TextStyle(color: AppColors.inkMuted)),
                )
              : ListView.builder(
                  itemCount: _draftEntries.length,
                  itemBuilder: (ctx, idx) {
                    final item = _draftEntries[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: item['subject_name'] ?? '',
                                  decoration: const InputDecoration(isDense: true, labelText: 'Subject'),
                                  onChanged: (val) => item['subject_name'] = val,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButton<int>(
                                        value: (item['day_of_week'] as int?) ?? 0,
                                        isExpanded: true,
                                        isDense: true,
                                        items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(_days[i], style: const TextStyle(fontSize: 12)))),
                                        onChanged: (val) => setState(() => item['day_of_week'] = val ?? 0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item['start_time'] ?? '',
                                        decoration: const InputDecoration(isDense: true, labelText: 'Start'),
                                        onChanged: (val) => item['start_time'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item['end_time'] ?? '',
                                        decoration: const InputDecoration(isDense: true, labelText: 'End'),
                                        onChanged: (val) => item['end_time'] = val,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                            onPressed: () => setState(() => _draftEntries.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel & Discard',
                isSecondary: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: _isConfirming ? 'Saving...' : 'Confirm & Save (${_draftEntries.length})',
                isLoading: _isConfirming,
                onPressed: _draftEntries.isEmpty || _isConfirming ? null : _confirmAndSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
