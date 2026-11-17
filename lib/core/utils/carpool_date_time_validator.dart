import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Comprehensive date and time validation helper for Carpool ride publishing and searching.
/// Ensures all date and time selections are strictly in the future.
class CarpoolDateTimeValidator {
  CarpoolDateTimeValidator._();

  /// Checks if a given date is strictly before today (ignoring hours/minutes).
  static bool isPastDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  /// Checks if a given date is today (ignoring hours/minutes).
  static bool isToday(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return date.year == current.year &&
        date.month == current.month &&
        date.day == current.day;
  }

  /// Checks if a given date is strictly in the future (after today).
  static bool isFutureDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  /// Checks whether there are any future time slots left for today.
  static bool hasAvailableTimeSlotsToday({DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.hour < 23 || (current.hour == 23 && current.minute < 59);
  }

  /// Combines a [DateTime] date with a [TimeOfDay] into a single [DateTime].
  static DateTime combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Checks whether a specific [TimeOfDay] is valid for the given [DateTime] date.
  /// - If the date is in the past: returns false.
  /// - If the date is today: time must be strictly after the current time.
  /// - If the date is a future date: all times are valid (returns true).
  static bool isTimeSlotValidForDate({
    required DateTime date,
    required TimeOfDay time,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (isPastDate(date, now: current)) {
      return false;
    }
    if (isToday(date, now: current)) {
      final combined = combine(date, time);
      return combined.isAfter(current);
    }
    // Future dates allow any valid time of day
    return true;
  }

  /// Calculates the next available hourly slot based on current time and date.
  /// Requirement examples:
  /// - Current time 1:00 PM -> first selectable time 2:00 PM.
  /// - Current time 1:30 PM -> next available hourly slot 2:00 PM.
  /// - Future dates -> returns standard daytime (09:00 AM).
  static TimeOfDay getNextAvailableTime(DateTime forDate, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (!isToday(forDate, now: current)) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    // For today:
    // If current is 1:00 PM (13:00) or 1:30 PM (13:30), next available hourly slot is 2:00 PM (14:00).
    final nextHour = current.hour + 1;
    if (nextHour < 24) {
      return TimeOfDay(hour: nextHour, minute: 0);
    } else {
      // Near midnight (after 23:00)
      if (current.minute < 55) {
        return TimeOfDay(hour: 23, minute: current.minute + 5);
      }
      return const TimeOfDay(hour: 23, minute: 59);
    }
  }

  /// Earliest selectable date for the date picker (today).
  static DateTime getFirstSelectableDate({DateTime? now}) {
    final current = now ?? DateTime.now();
    return DateTime(current.year, current.month, current.day);
  }

  /// Latest selectable date for the date picker (default 180 days).
  static DateTime getLatestSelectableDate({DateTime? now, int daysAhead = 180}) {
    final current = now ?? DateTime.now();
    return DateTime(current.year, current.month, current.day)
        .add(Duration(days: daysAhead));
  }

  /// Initial date for date picker: ensures it's never a past date.
  static DateTime getInitialDate({
    DateTime? selectedDate,
    bool hasSelectedDate = false,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    if (!hasSelectedDate || selectedDate == null) {
      return today;
    }
    final target =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return target.isBefore(today) ? today : target;
  }

  /// Initial time for time picker:
  /// - If date is today, ensures the initial time is strictly in the future
  ///   (e.g., next available hourly slot).
  /// - If date is in the future, preserves selected time or returns default.
  static TimeOfDay getInitialTime({
    required DateTime selectedDate,
    TimeOfDay? selectedTime,
    bool hasSelectedTime = false,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (isToday(selectedDate, now: current)) {
      if (hasSelectedTime && selectedTime != null) {
        final combined = combine(selectedDate, selectedTime);
        if (combined.isAfter(current)) {
          return selectedTime;
        }
      }
      return getNextAvailableTime(selectedDate, now: current);
    }

    if (hasSelectedTime && selectedTime != null) {
      return selectedTime;
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  /// Full validation before publishing or searching a ride.
  /// Revalidates against real-time [DateTime.now()].
  /// If the selected date or time has become invalid because time has passed,
  /// returns a descriptive error message requiring the user to select a new time.
  static CarpoolDateTimeValidationResult validate({
    required DateTime? date,
    required TimeOfDay? time,
    required bool hasSelectedDate,
    required bool hasSelectedTime,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (!hasSelectedDate || date == null) {
      return const CarpoolDateTimeValidationResult(
        isValid: false,
        errorMessage: 'Please select a date for the ride',
      );
    }

    if (isPastDate(date, now: current)) {
      return const CarpoolDateTimeValidationResult(
        isValid: false,
        errorMessage:
            'Selected date has already passed. Please select today or a future date.',
      );
    }

    if (!hasSelectedTime || time == null) {
      return const CarpoolDateTimeValidationResult(
        isValid: false,
        errorMessage: 'Please select a departure time for the ride',
      );
    }

    final combined = combine(date, time);
    if (!combined.isAfter(current)) {
      final formattedNow = DateFormat('hh:mm a').format(current);
      if (isToday(date, now: current)) {
        return CarpoolDateTimeValidationResult(
          isValid: false,
          errorMessage:
              'Selected departure time has passed. Please select a time later than $formattedNow.',
        );
      } else {
        return const CarpoolDateTimeValidationResult(
          isValid: false,
          errorMessage:
              'Departure date and time cannot be in the past. Please select a valid future time.',
        );
      }
    }

    return CarpoolDateTimeValidationResult(
      isValid: true,
      validatedDateTime: combined,
    );
  }
}

class CarpoolDateTimeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime? validatedDateTime;

  const CarpoolDateTimeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.validatedDateTime,
  });
}
