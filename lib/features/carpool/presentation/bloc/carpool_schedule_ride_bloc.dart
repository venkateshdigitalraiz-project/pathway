import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/carpool_date_time_validator.dart';

// ════════════════════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════════════════════
abstract class CarpoolScheduleRideEvent extends Equatable {
  const CarpoolScheduleRideEvent();

  @override
  List<Object?> get props => [];
}

class CarpoolScheduleStarted extends CarpoolScheduleRideEvent {
  final DateTime? initialDeparture;

  const CarpoolScheduleStarted({this.initialDeparture});

  @override
  List<Object?> get props => [initialDeparture];
}

class CarpoolScheduleDateSelected extends CarpoolScheduleRideEvent {
  final DateTime date;

  const CarpoolScheduleDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

class CarpoolScheduleTimeSelected extends CarpoolScheduleRideEvent {
  final TimeOfDay time;

  const CarpoolScheduleTimeSelected(this.time);

  @override
  List<Object?> get props => [time];
}

class CarpoolScheduleMonthChanged extends CarpoolScheduleRideEvent {
  final int monthDelta;

  const CarpoolScheduleMonthChanged(this.monthDelta);

  @override
  List<Object?> get props => [monthDelta];
}

class CarpoolScheduleQuickSlotSelected extends CarpoolScheduleRideEvent {
  final TimeOfDay time;

  const CarpoolScheduleQuickSlotSelected(this.time);

  @override
  List<Object?> get props => [time];
}

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════
class CarpoolScheduleRideState extends Equatable {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final DateTime viewMonth;
  final bool isValid;
  final String? validationError;

  const CarpoolScheduleRideState({
    required this.selectedDate,
    required this.selectedTime,
    required this.viewMonth,
    this.isValid = true,
    this.validationError,
  });

  factory CarpoolScheduleRideState.initial({DateTime? initialDeparture}) {
    final now = DateTime.now();
    DateTime departure = initialDeparture ?? now;

    // Ensure initial departure is not in the past
    if (CarpoolDateTimeValidator.isPastDate(departure, now: now)) {
      departure = now;
    }

    final date = DateTime(departure.year, departure.month, departure.day);
    final time = TimeOfDay(hour: departure.hour, minute: departure.minute);

    return CarpoolScheduleRideState(
      selectedDate: date,
      selectedTime: time,
      viewMonth: DateTime(date.year, date.month, 1),
      isValid: true,
    );
  }

  bool get isToday => CarpoolDateTimeValidator.isToday(selectedDate);

  DateTime get combinedDateTime => DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );

  String get formattedDate {
    if (isToday) return 'Today, ${DateFormat('d MMM').format(selectedDate)}';
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (selectedDate.year == tomorrow.year &&
        selectedDate.month == tomorrow.month &&
        selectedDate.day == tomorrow.day) {
      return 'Tomorrow, ${DateFormat('d MMM').format(selectedDate)}';
    }
    return DateFormat('EEE, d MMMM yyyy').format(selectedDate);
  }

  String get formattedTime {
    final hour = selectedTime.hourOfPeriod == 0
        ? 12
        : selectedTime.hourOfPeriod;
    final minute = selectedTime.minute.toString().padLeft(2, '0');
    final period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  CarpoolScheduleRideState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    DateTime? viewMonth,
    bool? isValid,
    String? validationError,
    bool clearError = false,
  }) {
    return CarpoolScheduleRideState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      viewMonth: viewMonth ?? this.viewMonth,
      isValid: isValid ?? this.isValid,
      validationError: clearError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    selectedTime,
    viewMonth,
    isValid,
    validationError,
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════
class CarpoolScheduleRideBloc
    extends Bloc<CarpoolScheduleRideEvent, CarpoolScheduleRideState> {
  CarpoolScheduleRideBloc({DateTime? initialDeparture})
    : super(
        CarpoolScheduleRideState.initial(initialDeparture: initialDeparture),
      ) {
    on<CarpoolScheduleStarted>(_onStarted);
    on<CarpoolScheduleDateSelected>(_onDateSelected);
    on<CarpoolScheduleTimeSelected>(_onTimeSelected);
    on<CarpoolScheduleMonthChanged>(_onMonthChanged);
    on<CarpoolScheduleQuickSlotSelected>(_onQuickSlotSelected);
  }

  void _onStarted(
    CarpoolScheduleStarted event,
    Emitter<CarpoolScheduleRideState> emit,
  ) {
    if (event.initialDeparture != null) {
      emit(
        CarpoolScheduleRideState.initial(
          initialDeparture: event.initialDeparture,
        ),
      );
    }
  }

  void _onDateSelected(
    CarpoolScheduleDateSelected event,
    Emitter<CarpoolScheduleRideState> emit,
  ) {
    final now = DateTime.now();
    if (CarpoolDateTimeValidator.isPastDate(event.date, now: now)) {
      return;
    }

    final newDate = DateTime(event.date.year, event.date.month, event.date.day);
    emit(
      state.copyWith(
        selectedDate: newDate,
        isValid: true,
        clearError: true,
      ),
    );
  }

  void _onTimeSelected(
    CarpoolScheduleTimeSelected event,
    Emitter<CarpoolScheduleRideState> emit,
  ) {
    emit(
      state.copyWith(
        selectedTime: event.time,
        isValid: true,
        clearError: true,
      ),
    );
  }

  void _onMonthChanged(
    CarpoolScheduleMonthChanged event,
    Emitter<CarpoolScheduleRideState> emit,
  ) {
    final current = state.viewMonth;
    final newMonth = DateTime(
      current.year,
      current.month + event.monthDelta,
      1,
    );

    // Don't navigate to months prior to current month
    final now = DateTime.now();
    final minMonth = DateTime(now.year, now.month, 1);
    if (newMonth.isBefore(minMonth)) return;

    emit(state.copyWith(viewMonth: newMonth));
  }

  void _onQuickSlotSelected(
    CarpoolScheduleQuickSlotSelected event,
    Emitter<CarpoolScheduleRideState> emit,
  ) {
    add(CarpoolScheduleTimeSelected(event.time));
  }
}
