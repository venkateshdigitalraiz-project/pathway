import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/carpool_offer_ride_bloc.dart';
import '../bloc/carpool_schedule_ride_bloc.dart';
import 'carpool_ride_summary_page.dart';

/// Clean Architecture Schedule Ride Page (Customized Calendar & Time Picker).
///
/// Workflow:
/// 1. Opened from [CarpoolStopoversPage] on forward action.
/// 2. Allows selecting an authentic travel date via a customized calendar month-view.
/// 3. Allows selecting an authentic departure time via a customized digital time picker & presets.
/// 4. Synchronizes selected departure schedule back to [CarpoolOfferRideBloc].
/// 5. Proceeds to [CarpoolRideSummaryPage] on confirmation.
class CarpoolScheduleRidePage extends StatelessWidget {
  final CarpoolOfferRideBloc offerBloc;

  const CarpoolScheduleRidePage({super.key, required this.offerBloc});

  /// Navigates to [CarpoolScheduleRidePage] safely on the root navigator.
  static Future<void> show(
    BuildContext context,
    CarpoolOfferRideBloc offerBloc,
  ) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CarpoolScheduleRidePage(offerBloc: offerBloc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: offerBloc),
        BlocProvider<CarpoolScheduleRideBloc>(
          create: (_) => CarpoolScheduleRideBloc(
            initialDeparture: offerBloc.state.departure,
          ),
        ),
      ],
      child: const _ScheduleRideView(),
    );
  }
}

class _ScheduleRideView extends StatelessWidget {
  const _ScheduleRideView();

  static const Color primaryPurple = Color(0xFF4C2BF0);
  static const Color darkPurple = Color(0xFF140D43);

  void _onProceed(
    BuildContext context,
    CarpoolOfferRideBloc offerBloc,
    CarpoolScheduleRideState scheduleState,
  ) {
    // 1. Sync schedule back to CarpoolOfferRideBloc
    offerBloc.add(CarpoolOfferDateChanged(scheduleState.selectedDate));
    offerBloc.add(
      CarpoolOfferTimeChanged(
        scheduleState.selectedTime.hour,
        scheduleState.selectedTime.minute,
      ),
    );

    // 2. Proceed to CarpoolRideSummaryPage (_onContinue page)
    CarpoolRideSummaryPage.show(
      context,
      offerBloc,
      pricing: offerBloc.state.pricingCalculation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerBloc = context.read<CarpoolOfferRideBloc>();

    return BlocBuilder<CarpoolScheduleRideBloc, CarpoolScheduleRideState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Top Navigation Bar & Route Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.centerLeft,
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: primaryPurple,
                            size: 28,
                          ),
                        ),
                      ),
                      // Route badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${offerBloc.state.from} → ${offerBloc.state.to}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryPurple,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Scrollable Body: Calendar & Time Selector
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title
                        const Text(
                          'When are you going?',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: darkPurple,
                            height: 1.22,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your departure date & time for passengers',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section 1: Customized Calendar
                        _buildCustomCalendarCard(context, state),

                        const SizedBox(height: 24),

                        // Section 2: Customized Time Display & Selector
                        _buildCustomTimePickerCard(context, state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Forward Button (Identical to CarpoolStopoversPage)
          floatingActionButton: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5D24F7), Color(0xFF3815D8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4C1CDD).withOpacity(0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onProceed(context, offerBloc, state),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOMIZED CALENDAR CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCustomCalendarCard(
    BuildContext context,
    CarpoolScheduleRideState state,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = state.viewMonth;
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final daysInMonth = monthEnd.day;

    // First day of month weekday (1 = Monday, 7 = Sunday)
    final firstWeekday = monthStart.weekday;
    final leadingEmptyCells = firstWeekday - 1;

    final monthTitle = DateFormat('MMMM yyyy').format(monthStart);
    final minMonth = DateTime(now.year, now.month, 1);
    final canGoPrev = monthStart.isAfter(minMonth);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: darkPurple,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: canGoPrev
                          ? primaryPurple
                          : const Color(0xFFCBD5E1),
                      size: 26,
                    ),
                    onPressed: canGoPrev
                        ? () => context.read<CarpoolScheduleRideBloc>().add(
                            const CarpoolScheduleMonthChanged(-1),
                          )
                        : null,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: primaryPurple,
                      size: 26,
                    ),
                    onPressed: () => context
                        .read<CarpoolScheduleRideBloc>()
                        .add(const CarpoolScheduleMonthChanged(1)),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Weekdays Row (M, T, W, T, F, S, S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S', isWeekend: true),
              _WeekdayLabel('S', isWeekend: true),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1EEFC)),
          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCells + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) {
                return const SizedBox.shrink();
              }
              final day = index - leadingEmptyCells + 1;
              final cellDate = DateTime(monthStart.year, monthStart.month, day);
              final isPast = cellDate.isBefore(today);
              final isSelected =
                  cellDate.year == state.selectedDate.year &&
                  cellDate.month == state.selectedDate.month &&
                  cellDate.day == state.selectedDate.day;
              final isTodayCell =
                  cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isPast
                    ? null
                    : () {
                        context.read<CarpoolScheduleRideBloc>().add(
                          CarpoolScheduleDateSelected(cellDate),
                        );
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF5D24F7)
                        : (isTodayCell && !isSelected
                              ? const Color(0xFFF1EEFC)
                              : Colors.transparent),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF5D24F7).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                    border: isTodayCell && !isSelected
                        ? Border.all(color: primaryPurple, width: 1.4)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isTodayCell
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isPast ? const Color(0xFFCBD5E1) : darkPurple),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Selected Date Pill Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EEFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: primaryPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  state.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOMIZED TIME PICKER CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCustomTimePickerCard(
    BuildContext context,
    CarpoolScheduleRideState state,
  ) {
    final hourOfPeriod = state.selectedTime.hourOfPeriod == 0
        ? 12
        : state.selectedTime.hourOfPeriod;
    final minuteStr = state.selectedTime.minute.toString().padLeft(2, '0');
    final isPM = state.selectedTime.period == DayPeriod.pm;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pick-up Time',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What time will you leave for your journey?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          // Digital Time Display & Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Box & Stepper
              _buildTimeUnitController(
                value: hourOfPeriod.toString().padLeft(2, '0'),
                label: 'HOUR',
                onIncrement: () {
                  final newHour = (state.selectedTime.hour + 1) % 24;
                  context.read<CarpoolScheduleRideBloc>().add(
                    CarpoolScheduleTimeSelected(
                      TimeOfDay(
                        hour: newHour,
                        minute: state.selectedTime.minute,
                      ),
                    ),
                  );
                },
                onDecrement: () {
                  final newHour = (state.selectedTime.hour - 1 + 24) % 24;
                  context.read<CarpoolScheduleRideBloc>().add(
                    CarpoolScheduleTimeSelected(
                      TimeOfDay(
                        hour: newHour,
                        minute: state.selectedTime.minute,
                      ),
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryPurple,
                  ),
                ),
              ),

              // Minute Box & Stepper
              _buildTimeUnitController(
                value: minuteStr,
                label: 'MIN',
                onIncrement: () {
                  final newMin = (state.selectedTime.minute + 5) % 60;
                  context.read<CarpoolScheduleRideBloc>().add(
                    CarpoolScheduleTimeSelected(
                      TimeOfDay(hour: state.selectedTime.hour, minute: newMin),
                    ),
                  );
                },
                onDecrement: () {
                  final newMin = (state.selectedTime.minute - 5 + 60) % 60;
                  context.read<CarpoolScheduleRideBloc>().add(
                    CarpoolScheduleTimeSelected(
                      TimeOfDay(hour: state.selectedTime.hour, minute: newMin),
                    ),
                  );
                },
              ),

              const SizedBox(width: 14),

              // AM / PM Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _buildAmPmButton(
                      label: 'AM',
                      isSelected: !isPM,
                      onTap: () {
                        if (isPM) {
                          final newHour = state.selectedTime.hour - 12;
                          context.read<CarpoolScheduleRideBloc>().add(
                            CarpoolScheduleTimeSelected(
                              TimeOfDay(
                                hour: newHour,
                                minute: state.selectedTime.minute,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildAmPmButton(
                      label: 'PM',
                      isSelected: isPM,
                      onTap: () {
                        if (!isPM) {
                          final newHour = state.selectedTime.hour + 12;
                          context.read<CarpoolScheduleRideBloc>().add(
                            CarpoolScheduleTimeSelected(
                              TimeOfDay(
                                hour: newHour,
                                minute: state.selectedTime.minute,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildTimeUnitController({
    required String value,
    required String label,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: primaryPurple,
            size: 28,
          ),
          onPressed: onIncrement,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          width: 68,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE8FF), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: darkPurple,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryPurple,
            size: 28,
          ),
          onPressed: onDecrement,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A84A7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAmPmButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF6B658C),
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isWeekend;

  const _WeekdayLabel(this.label, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isWeekend
                ? const Color(0xFFEF4444)
                : const Color(0xFF8A84A7),
          ),
        ),
      ),
    );
  }
}
