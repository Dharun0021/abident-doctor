import 'dart:convert';
import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../models/availability.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_theme.dart';
import '../../utils/responsive.dart';

class TimeRange {
  TimeOfDay start;
  TimeOfDay end;

  TimeRange({required this.start, required this.end});
}

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  DateTime? _selectedDate;
  List<TimeRange> _timeRanges = [];
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  List<Availability> _availabilities = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailabilities();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────────
  Future<void> _fetchAvailabilities() async {
    setState(() => _isFetching = true);
    try {
      final response = await DoctorApiService.getAvailabilities();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['availabilities'] as List)
            .map((item) => Availability.fromJson(item))
            .toList();
        setState(() {
          _availabilities = list;
          _errorMessage = null;
        });
      } else {
        setState(() => _errorMessage = 'Failed to load availabilities');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _selectedDate = d;
        _timeRanges = [];
        _errorMessage = null;
      });
    }
  }

  // ── Time picker ──────────────────────────────────────────────────────────────
  Future<void> _pickTime({required int index, required bool isStart}) async {
    final range = _timeRanges[index];
    final initial = isStart ? range.start : range.end;
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) {
      setState(() {
        if (isStart) {
          _timeRanges[index].start = t;
        } else {
          _timeRanges[index].end = t;
        }
      });
    }
  }

  // ── Smart add: next slot picks up from previous end ──────────────────────────
  void _addTimeRange() {
    setState(() {
      if (_timeRanges.isEmpty) {
        _timeRanges.add(TimeRange(
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 0),
        ));
      } else {
        final lastEnd = _timeRanges.last.end;
        final nextEndHour = (lastEnd.hour + 1).clamp(0, 23);
        _timeRanges.add(TimeRange(
          start: lastEnd,
          end: TimeOfDay(hour: nextEndHour, minute: lastEnd.minute),
        ));
      }
    });
  }

  void _removeTimeRange(int index) {
    setState(() => _timeRanges.removeAt(index));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _saveAvailabilities() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')));
      return;
    }
    if (_timeRanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one time range')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final slots = _timeRanges
          .map((r) => {'startTime': _fmt(r.start), 'endTime': _fmt(r.end)})
          .toList();

      final response = await DoctorApiService.createBulkAvailability(
        date: _selectedDate!,
        slots: slots,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability saved!')));
        await _fetchAvailabilities();
        setState(() {
          _selectedDate = null;
          _timeRanges = [];
        });
      } else {
        final data = jsonDecode(response.body);
        final msg = data['message'] ?? 'Failed to save';
        setState(() => _errorMessage = msg);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  Future<void> _deleteAvailability(String id) async {
    try {
      final response =
          await DoctorApiService.deleteAvailability(availabilityId: id);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted successfully!')));
        await _fetchAvailabilities();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to delete')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Availability', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Create your availability slots for patients to book appointments.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),

              // Error
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_errorMessage!,
                      style: AppTextStyles.body.copyWith(color: Colors.red)),
                ),
                const SizedBox(height: 16),
              ],

              // ── Create card ──────────────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create New Availability',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),

                    // Compact date row
                    InkWell(
                      onTap: _pickDate,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : MaterialLocalizations.of(context)
                                      .formatFullDate(_selectedDate!),
                              style: AppTextStyles.body.copyWith(
                                color: _selectedDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedDate != null)
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),

                    // Time ranges
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time Ranges',
                              style: AppTextStyles.headingSmall),
                          if (_timeRanges.isNotEmpty)
                            Text(
                              '${_timeRanges.length} slot${_timeRanges.length > 1 ? 's' : ''}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_timeRanges.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No slots added. Tap "+ Add Time Range" to start.',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: _timeRanges.length,
                          itemBuilder: (context, index) {
                            final range = _timeRanges[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(
                                          AppTheme.radiusLg),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Slot label
                                    SizedBox(
                                      width: 48,
                                      child: Text(
                                        'Slot\n${index + 1}',
                                        textAlign: TextAlign.center,
                                        style:
                                            AppTextStyles.caption
                                                .copyWith(
                                          color: AppColors.primary,
                                          fontWeight:
                                              FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // From
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickTime(
                                            index: index,
                                            isStart: true),
                                        child: _timeChip(
                                            'From',
                                            range.start
                                                .format(context)),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6),
                                      child: Text('-',
                                          style:
                                              AppTextStyles.body),
                                    ),
                                    // To
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickTime(
                                            index: index,
                                            isStart: false),
                                        child: _timeChip('To',
                                            range.end.format(context)),
                                      ),
                                    ),
                                    // Delete
                                    IconButton(
                                      icon: const Icon(
                                          Icons
                                              .delete_outline_rounded,
                                          size: 20),
                                      color: Colors.red,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36),
                                      onPressed: () =>
                                          _removeTimeRange(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 10),
                      AppButton(
                        label: '+ Add Time Range',
                        variant: AppButtonVariant.outline,
                        onPressed: _addTimeRange,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: _isLoading
                            ? 'Saving...'
                            : 'Save Availability',
                        expanded: true,
                        onPressed:
                            _isLoading ? null : _saveAvailabilities,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Existing availabilities ──────────────────────────────────────
              Text('Your Availability Slots',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              if (_isFetching)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()))
              else if (_availabilities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No availability slots created yet.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availabilities.length,
                  itemBuilder: (context, index) {
                    final avail = _availabilities[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    MaterialLocalizations.of(context)
                                        .formatFullDate(avail.date),
                                    style: AppTextStyles.title,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded),
                                  color: Colors.red,
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                          'Delete Availability'),
                                      content: const Text(
                                          'Delete all slots for this date?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx),
                                          child:
                                              const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteAvailability(
                                                avail.id ?? '');
                                          },
                                          child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Render each slot as a chip row
                            ...avail.sortedSlots.map((entry) {
                              final slotLabel = entry.key; // "slot1"
                              final slot = entry.value;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        slotLabel[0].toUpperCase() +
                                            slotLabel.substring(1),
                                        style: AppTextStyles.caption
                                            .copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${slot.startTime}  →  ${slot.endTime}',
                                      style: AppTextStyles.body
                                          .copyWith(
                                              color: AppColors
                                                  .textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _timeChip(String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 10)),
          Text(time,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
