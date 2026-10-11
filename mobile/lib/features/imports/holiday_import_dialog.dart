import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../shared/widgets/app_button.dart';

class HolidayImportDialog extends StatefulWidget {
  final String semesterId;
  final VoidCallback onImportSuccess;

  const HolidayImportDialog({
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
      builder: (ctx) => HolidayImportDialog(
        semesterId: semesterId,
        onImportSuccess: onImportSuccess,
      ),
    );
  }

  @override
  State<HolidayImportDialog> createState() => _HolidayImportDialogState();
}

class _HolidayImportDialogState extends State<HolidayImportDialog> {
  final ApiClient _client = ApiClient();
  final TextEditingController _csvInputCtrl = TextEditingController();

  bool _isParsing = false;
  bool _isConfirming = false;
  String? _errorMessage;
  List<String> _warnings = [];

  // In-memory draft only
  List<Map<String, dynamic>> _draftHolidays = [];
  bool _hasParsedDraft = false;

  @override
  void dispose() {
    _csvInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _parseTextOrSample() async {
    final text = _csvInputCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please paste CSV or formatted holiday text.');
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
        'file': MultipartFile.fromBytes(bytes, filename: 'holidays_import.csv'),
      });

      final resp = await _client.dio.post(
        ApiEndpoints.importHolidaysParse,
        data: formData,
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        final rawDrafts = (data['draft_holidays'] as List?) ?? [];
        final warnings = (data['warning_notes'] as List?)?.map((w) => w.toString()).toList() ?? [];

        setState(() {
          _isParsing = false;
          _hasParsedDraft = true;
          _warnings = warnings;
          _draftHolidays = rawDrafts.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Failed to parse holiday calendar. Please check format.';
      });
    }
  }

  Future<void> _confirmAndSave() async {
    if (_draftHolidays.isEmpty) {
      setState(() => _errorMessage = 'No draft holidays to confirm.');
      return;
    }

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'semester_id': widget.semesterId,
        'holidays': _draftHolidays.map((h) => {
          'title': h['title'],
          'start_date': h['start_date'],
          'end_date': h['end_date'],
          'category': h['category'] ?? 'University Holiday',
          'notes': h['notes'],
        }).toList(),
      };

      final resp = await _client.dio.post(
        ApiEndpoints.importHolidaysConfirm,
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
        _errorMessage = 'Failed to commit holidays to database.';
      });
    }
  }

  void _discardDraft() {
    setState(() {
      _draftHolidays.clear();
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
                    child: const Icon(Icons.calendar_month_outlined, color: AppColors.ocean, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Import Academic Holidays',
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
            'Draft-Only Lifecycle: Extracted holidays remain editable in memory until you confirm. Discarding creates zero database rows.',
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
            'Paste CSV or Academic Calendar Text:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Format: Title, StartDate(YYYY-MM-DD), EndDate(YYYY-MM-DD), Category, Notes',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _csvInputCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Durga Puja, 2026-10-21, 2026-10-25, Festival, Autumn recess\nDiwali, 2026-11-04, 2026-11-06, Festival, Festival of lights\nChristmas, 2026-12-25, 2026-12-25, University Holiday, Winter holiday',
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
                      'Durga Puja, 2026-10-21, 2026-10-25, Festival, 5 days break\n'
                      'Diwali, 2026-11-04, 2026-11-06, Festival, 3 days break\n'
                      'Children\'s Day, 2026-11-14, 2026-11-14, Other, University event\n'
                      'Christmas, 2026-12-25, 2026-12-25, Festival, 1 day holiday';
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
                label: const Text('Parse Holidays'),
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
              'Extracted Holiday Drafts (${_draftHolidays.length})',
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
          child: _draftHolidays.isEmpty
              ? const Center(
                  child: Text('No structured holidays found.', style: TextStyle(color: AppColors.inkMuted)),
                )
              : ListView.builder(
                  itemCount: _draftHolidays.length,
                  itemBuilder: (ctx, idx) {
                    final item = _draftHolidays[idx];
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
                                  initialValue: item['title'] ?? '',
                                  decoration: const InputDecoration(isDense: true, labelText: 'Title'),
                                  onChanged: (val) => item['title'] = val,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item['start_date'] ?? '',
                                        decoration: const InputDecoration(isDense: true, labelText: 'Start (YYYY-MM-DD)'),
                                        onChanged: (val) => item['start_date'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item['end_date'] ?? '',
                                        decoration: const InputDecoration(isDense: true, labelText: 'End (YYYY-MM-DD)'),
                                        onChanged: (val) => item['end_date'] = val,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                            onPressed: () => setState(() => _draftHolidays.removeAt(idx)),
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
                label: _isConfirming ? 'Saving...' : 'Confirm & Save (${_draftHolidays.length})',
                isLoading: _isConfirming,
                onPressed: _draftHolidays.isEmpty || _isConfirming ? null : _confirmAndSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
