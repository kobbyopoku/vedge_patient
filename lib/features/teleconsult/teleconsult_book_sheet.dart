import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/security/safe_url_launcher.dart';

import '../../core/api/patient_teleconsult_api.dart';
import '../../core/models/availability_slot.dart';
import '../../core/models/provider_summary.dart';

/// Bottom sheet used from TeleconsultBrowseScreen to book a specific
/// provider. Fetches availability on the currently selected date, lets the
/// user pick a slot, then calls /book and launches the Paystack checkout.
class TeleconsultBookSheet extends ConsumerStatefulWidget {
  const TeleconsultBookSheet({super.key, required this.provider});
  final ProviderSummary provider;

  @override
  ConsumerState<TeleconsultBookSheet> createState() =>
      _TeleconsultBookSheetState();
}

class _TeleconsultBookSheetState extends ConsumerState<TeleconsultBookSheet> {
  late DateTime _selectedDay;
  AvailabilitySlot? _selectedSlot;
  final _reasonController = TextEditingController();
  bool _loadingSlots = false;
  bool _booking = false;
  List<AvailabilitySlot> _slots = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _fetchSlots();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _loadingSlots = true;
      _error = null;
    });
    try {
      // Query a wider window (±12h) around the selected day so we catch all
      // slots whose start is on that local-TZ day regardless of timezone.
      final from = _selectedDay.subtract(const Duration(hours: 12));
      final to = _selectedDay.add(const Duration(hours: 36));
      final slots = await ref
          .read(patientTeleconsultApiProvider)
          .listSlotsForProvider(widget.provider.userId, from, to);
      final dayStart = _selectedDay;
      final dayEnd = _selectedDay.add(const Duration(days: 1));
      final filtered = slots
          .where((s) =>
              !s.isBooked &&
              s.startTime.isAfter(DateTime.now()) &&
              !s.startTime.isBefore(dayStart) &&
              s.startTime.isBefore(dayEnd))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _slots = filtered;
        _loadingSlots = false;
        if (_selectedSlot != null &&
            !filtered.any((s) => s.id == _selectedSlot!.id)) {
          _selectedSlot = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Couldn\'t load availability. Please try again.';
        _loadingSlots = false;
      });
    }
  }

  Future<void> _confirmAndPay() async {
    final slot = _selectedSlot;
    if (slot == null) return;
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      final result = await ref.read(patientTeleconsultApiProvider).book(
            providerUserId: widget.provider.userId,
            slotId: slot.id,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );
      if (!mounted) return;

      // Launch the Paystack checkout in the device browser. We do NOT wait
      // for the webhook — the app will pick up the status transition on the
      // next list refresh.
      final checkoutUrl = result.paystackCheckoutUrl;
      if (checkoutUrl.isNotEmpty) {
        await launchSafeString(checkoutUrl);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Consult booked. Complete payment to confirm. We\'ll update the status once Paystack notifies us.'),
        ),
      );
      // Navigate to the consult list so the user sees the new session.
      GoRouter.of(context).go('/teleconsult');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Booking failed. Please try again.';
        _booking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book with ${widget.provider.displayName}',
                style: theme.textTheme.titleLarge,
              ),
              if (widget.provider.roleLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.provider.roleLabel!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text('Pick a date', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _DayStrip(
                selectedDay: _selectedDay,
                onChanged: (d) {
                  setState(() {
                    _selectedDay = d;
                    _selectedSlot = null;
                  });
                  _fetchSlots();
                },
              ),
              const SizedBox(height: 18),
              Text('Available times', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_slots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No open slots on this day.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _slots)
                      _SlotChip(
                        slot: s,
                        selected: _selectedSlot?.id == s.id,
                        onTap: () => setState(() => _selectedSlot = s),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Text('Chief complaint or question',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Persistent headache for 3 days',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedSlot == null || _booking
                      ? null
                      : _confirmAndPay,
                  icon: _booking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _booking ? 'Starting checkout…' : 'Pay & confirm',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll be redirected to Paystack in your browser to complete '
                'payment. Once we receive confirmation, your consult moves to '
                '"Scheduled" automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedDay, required this.onChanged});
  final DateTime selectedDay;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = days[i];
          final selected = d == selectedDay;
          return _DayPill(
            day: d,
            selected: selected,
            onTap: () => onChanged(d),
          );
        },
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.onTap,
  });
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final weekday = DateFormat('EEE').format(day);
    final dayNum = DateFormat('d').format(day);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  final AvailabilitySlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = DateFormat('h:mm a').format(slot.startTime);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
