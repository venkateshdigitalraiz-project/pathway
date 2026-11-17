import 'package:equatable/equatable.dart';

class AcceptedBookingEntity extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final int totalAmount;
  final String paymentStatus;
  final String bookingStatus;
  final int availableSeats;
  final String message;

  const AcceptedBookingEntity({
    required this.bookingId,
    required this.bookingCode,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.availableSeats,
    required this.message,
  });

  factory AcceptedBookingEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final b = data['booking'] is Map<String, dynamic>
        ? data['booking'] as Map<String, dynamic>
        : data;

    return AcceptedBookingEntity(
      bookingId: b['id']?.toString() ?? b['_id']?.toString() ?? '',
      bookingCode: b['bookingCode']?.toString() ?? '',
      rideId: b['rideId']?.toString() ?? '',
      passengerId: b['passengerId']?.toString() ?? '',
      seatsBooked: (b['seatsBooked'] as num?)?.toInt() ?? 1,
      totalAmount: (b['totalAmount'] as num?)?.toInt() ?? 0,
      paymentStatus: b['paymentStatus']?.toString() ?? 'paid',
      bookingStatus: b['bookingStatus']?.toString() ?? 'confirmed',
      availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? 'Booking accepted successfully',
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        rideId,
        passengerId,
        seatsBooked,
        totalAmount,
        paymentStatus,
        bookingStatus,
        availableSeats,
        message,
      ];
}
