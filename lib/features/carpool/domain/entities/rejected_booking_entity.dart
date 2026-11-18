import 'package:equatable/equatable.dart';

class RejectedBookingEntity extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final String bookingStatus;
  final int availableSeats;
  final String message;

  const RejectedBookingEntity({
    required this.bookingId,
    required this.bookingCode,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.bookingStatus,
    required this.availableSeats,
    required this.message,
  });

  factory RejectedBookingEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final b = data['booking'] is Map<String, dynamic>
        ? data['booking'] as Map<String, dynamic>
        : data;

    return RejectedBookingEntity(
      bookingId: b['id']?.toString() ?? b['_id']?.toString() ?? '',
      bookingCode: b['bookingCode']?.toString() ?? '',
      rideId: b['rideId']?.toString() ?? '',
      passengerId: b['passengerId']?.toString() ?? '',
      seatsBooked: (b['seatsBooked'] as num?)?.toInt() ?? 1,
      bookingStatus: b['bookingStatus']?.toString() ?? 'cancelled',
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? 'Booking request declined',
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        rideId,
        passengerId,
        seatsBooked,
        bookingStatus,
        availableSeats,
        message,
      ];
}
