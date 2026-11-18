import 'package:equatable/equatable.dart';

enum RiderBookingStatus { confirmed, completed, cancelled }

/// Entity representing a booking made by a rider/passenger.
class RiderBookingEntity extends Equatable {
  const RiderBookingEntity({
    required this.id,
    required this.rideId,
    required this.driverName,
    required this.driverPhone,
    required this.driverRating,
    required this.vehicle,
    required this.from,
    required this.to,
    required this.departure,
    required this.seatsBooked,
    required this.pricePerSeat,
    required this.totalAmount,
    required this.status,
    required this.bookingDate,
    this.vehicleNumber,
    this.vehicleModel,
    this.otpCode,
    this.passengerNotes,
  });

  final String id;
  final String rideId;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String vehicle;
  final String from;
  final String to;
  final DateTime departure;
  final int seatsBooked;
  final int pricePerSeat;
  final int totalAmount;
  final RiderBookingStatus status;
  final DateTime bookingDate;
  final String? vehicleNumber;
  final String? vehicleModel;
  final String? otpCode;
  final String? passengerNotes;

  /// Alias for totalAmount
  int get totalPrice => totalAmount;

  /// Returns the clean vehicle model name (e.g. "Hgigih", "Maruti")
  String get displayVehicleModel {
    if (vehicleModel != null && vehicleModel!.trim().isNotEmpty) {
      return vehicleModel!.trim();
    }
    if (vehicle.isNotEmpty) {
      final parts = vehicle.split('•');
      final first = parts.first.trim();
      if (first.isNotEmpty) return first;
    }
    return '';
  }

  /// Returns the vehicle registration number (e.g. "GVJVHCY", "TS45 AK6535")
  String get displayVehicleNumber {
    if (vehicleNumber != null && vehicleNumber!.trim().isNotEmpty) {
      return vehicleNumber!.trim();
    }
    if (vehicle.contains('•')) {
      final parts = vehicle.split('•');
      if (parts.length > 1) {
        return parts.last.trim();
      }
    }
    return '';
  }

  RiderBookingEntity copyWith({
    RiderBookingStatus? status,
    String? passengerNotes,
    String? vehicleModel,
    String? vehicleNumber,
  }) {
    return RiderBookingEntity(
      id: id,
      rideId: rideId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicle: vehicle,
      from: from,
      to: to,
      departure: departure,
      seatsBooked: seatsBooked,
      pricePerSeat: pricePerSeat,
      totalAmount: totalAmount,
      status: status ?? this.status,
      bookingDate: bookingDate,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      otpCode: otpCode,
      passengerNotes: passengerNotes ?? this.passengerNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        rideId,
        driverName,
        driverPhone,
        driverRating,
        vehicle,
        from,
        to,
        departure,
        seatsBooked,
        pricePerSeat,
        totalAmount,
        status,
        bookingDate,
        vehicleNumber,
        vehicleModel,
        otpCode,
        passengerNotes,
      ];
}

