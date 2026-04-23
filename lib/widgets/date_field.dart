import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Spec §5.9 — DOB-friendly date field.
///
/// For [DateFieldMode.dateOfBirth] the picker is a year-first wheel sheet,
/// initial year 1955 (median DOB for our market), range 1900–today. For
/// other use-cases we fall back to Material's `showDatePicker`.
enum DateFieldMode { dateOfBirth, calendar }

class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.mode = DateFieldMode.dateOfBirth,
    this.errorText,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateFieldMode mode;
  final String? errorText;

  static final DateFormat _displayFormat = DateFormat('d MMM yyyy');

  Future<void> _open(BuildContext context) async {
    // Dismiss any soft-keyboard before opening the sheet — if a
    // TextFormField (first/last name) is still focused, the IME can
    // render above the modal and make it look like "nothing happened"
    // when the user taps DOB.
    FocusManager.instance.primaryFocus?.unfocus();
    if (kDebugMode) debugPrint('[date_field] open mode=$mode value=$value');
    // Wait a frame so the keyboard has time to collapse before the
    // bottom sheet lays out — avoids the sheet opening inside the
    // former keyboard inset on some Android builds.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!context.mounted) return;
    if (mode == DateFieldMode.dateOfBirth) {
      final picked = await _showYearFirstSheet(context, value);
      if (picked != null) onChanged(picked);
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (picked != null) onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final hasValue = value != null;

    final body = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
        border: Border.all(
          color: errorText != null ? cs.error : cs.outline,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  hasValue ? _displayFormat.format(value!) : 'DD MMM YYYY',
                  style: t.titleMedium?.copyWith(
                    color: hasValue ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.calendar_today_rounded, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '$label, ${hasValue ? _displayFormat.format(value!) : 'empty'}',
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _open(context),
                borderRadius: BorderRadius.circular(VedgeSpacing.radiusMd),
                child: body,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: t.bodySmall?.copyWith(color: VedgeColors.critical),
          ),
        ],
      ],
    );
  }
}

Future<DateTime?> _showYearFirstSheet(
  BuildContext context,
  DateTime? initial,
) {
  // Per spec §5.9 — the year column scrolls first and starts at 1955.
  final defaultYear = 1955;
  final init = initial ??
      DateTime(defaultYear, 1, 1);
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _YearFirstDatePickerSheet(initial: init),
  );
}

class _YearFirstDatePickerSheet extends StatefulWidget {
  const _YearFirstDatePickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_YearFirstDatePickerSheet> createState() =>
      _YearFirstDatePickerSheetState();
}

class _YearFirstDatePickerSheetState
    extends State<_YearFirstDatePickerSheet> {
  static const int _firstYear = 1900;

  late int _year = widget.initial.year;
  late int _month = widget.initial.month;
  late int _day = widget.initial.day;

  late final FixedExtentScrollController _yearCtrl = FixedExtentScrollController(
    initialItem: _year - _firstYear,
  );
  late final FixedExtentScrollController _monthCtrl = FixedExtentScrollController(
    initialItem: _month - 1,
  );
  late final FixedExtentScrollController _dayCtrl = FixedExtentScrollController(
    initialItem: _day - 1,
  );

  int get _lastYear => DateTime.now().year;

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  void _onChanged() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      _dayCtrl.jumpToItem(_day - 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final months = const [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final maxDay = _daysInMonth(_year, _month);
    final screenWidth = MediaQuery.of(context).size.width;

    // Anchor the sheet to a finite width. showModalBottomSheet's child
    // otherwise propagates unbounded width into the button Row below,
    // which breaks TextButton / FilledButton's internal tap-target
    // sizing on Flutter 3.32+ — the Row sees BoxConstraints(w=Infinity)
    // and the button's RenderPhysicalShape asserts.
    return SizedBox(
      width: screenWidth,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Date of birth', style: t.titleLarge),
              ),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    // YEAR column rendered FIRST per spec.
                    Expanded(
                      flex: 4,
                      child: _Wheel(
                        controller: _yearCtrl,
                        childCount: _lastYear - _firstYear + 1,
                        label: 'Year',
                        onChanged: (i) {
                          _year = _firstYear + i;
                          _onChanged();
                        },
                        builder: (i) => '${_firstYear + i}',
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _Wheel(
                        controller: _monthCtrl,
                        childCount: 12,
                        label: 'Month',
                        onChanged: (i) {
                          _month = i + 1;
                          _onChanged();
                        },
                        builder: (i) => months[i],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Wheel(
                        controller: _dayCtrl,
                        childCount: maxDay,
                        label: 'Day',
                        onChanged: (i) {
                          _day = i + 1;
                          _onChanged();
                        },
                        builder: (i) => '${i + 1}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Each button wrapped in Expanded — defensive so the
              // Row doesn't hand MainAxisSize.max infinite space to
              // the buttons' internal input-padding render boxes.
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(
                        DateTime(_year, _month, _day),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.childCount,
    required this.label,
    required this.onChanged,
    required this.builder,
  });

  final FixedExtentScrollController controller;
  final int childCount;
  final String label;
  final ValueChanged<int> onChanged;
  final String Function(int index) builder;

  /// Must match {@code itemExtent} on the wheel so the center band
  /// aligns with the row that {@code FixedExtentScrollPhysics} snaps to.
  static const double _itemExtent = 38;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection band — a subtle filled pill behind the center row
          // so the user can tell which value is currently selected.
          // Non-interactive (IgnorePointer) so scroll gestures still
          // reach the wheel underneath.
          IgnorePointer(
            child: Container(
              height: _itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: cs.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            physics: const FixedExtentScrollPhysics(),
            itemExtent: _itemExtent,
            diameterRatio: 1.6,
            perspective: 0.005,
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: childCount,
              builder: (context, i) => Center(
                child: Text(
                  builder(i),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
