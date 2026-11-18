import 'package:equatable/equatable.dart';

/// Entity representing a passenger booking on this published ride
class MyPublishRidePassengerEntity extends Equatable {
  final String id;
  final String bookingCode;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String? passengerAvatar;
  final int seatsBooked;
  final int totalAmount;
  final String paymentStatus;
  final String bookingStatus;
  final String fromAddress;
  final String toAddress;
  final DateTime createdAt;

  const MyPublishRidePassengerEntity({
    required this.id,
    required this.bookingCode,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerAvatar,
    required this.seatsBooked,
    required this.totalAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.fromAddress,
    required this.toAddress,
    required this.createdAt,
  });

  MyPublishRidePassengerEntity copyWith({
    String? id,
    String? bookingCode,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    String? passengerAvatar,
    int? seatsBooked,
    int? totalAmount,
    String? paymentStatus,
    String? bookingStatus,
    String? fromAddress,
    String? toAddress,
    DateTime? createdAt,
  }) {
    return MyPublishRidePassengerEntity(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerAvatar: passengerAvatar ?? this.passengerAvatar,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        passengerId,
        passengerName,
        passengerPhone,
        passengerAvatar,
        seatsBooked,
        totalAmount,
        paymentStatus,
        bookingStatus,
        fromAddress,
        toAddress,
        createdAt,
      ];
}

/// Entity representing full published ride details for the driver
class MyPublishRideDetailsEntity extends Equatable {
  final String id;
  final String rideCode;
  final String publisherId;
  final String publisherName;
  final String publisherPhone;
  final String? publisherAvatar;
  final String originAddress;
  final String originCity;
  final double? originLat;
  final double? originLng;
  final String destinationAddress;
  final String destinationCity;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final int totalSeatsOccupied;
  final int totalPassengers;
  final int pricePerSeat;
  final String vehicleModel;
  final String vehicleNumber;
  final String notes;
  final String status;
  final DateTime? createdAt;
  final List<MyPublishRidePassengerEntity> bookings;

  const MyPublishRideDetailsEntity({
    required this.id,
    required this.rideCode,
    required this.publisherId,
    required this.publisherName,
    required this.publisherPhone,
    this.publisherAvatar,
    required this.originAddress,
    required this.originCity,
    this.originLat,
    this.originLng,
    required this.destinationAddress,
    required this.destinationCity,
    this.destinationLat,
    this.destinationLng,
    required this.departureTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.totalSeatsOccupied,
    required this.totalPassengers,
    required this.pricePerSeat,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.notes,
    required this.status,
    this.createdAt,
    this.bookings = const [],
  });

  /// Total potential earnings if all seats were booked
  int get potentialEarnings => pricePerSeat * totalSeats;

  /// Current confirmed earnings from booked seats
  int get currentEarnings {
    int total = 0;
    for (final b in bookings) {
      total += b.totalAmount;
    }
    if (total == 0 && totalSeatsOccupied > 0) {
      total = totalSeatsOccupied * pricePerSeat;
    }
    return total;
  }

  MyPublishRideDetailsEntity copyWith({
    String? id,
    String? rideCode,
    String? publisherId,
    String? publisherName,
    String? publisherPhone,
    String? publisherAvatar,
    String? originAddress,
    String? originCity,
    double? originLat,
    double? originLng,
    String? destinationAddress,
    String? destinationCity,
    double? destinationLat,
    double? destinationLng,
    DateTime? departureTime,
    int? availableSeats,
    int? totalSeats,
    int? totalSeatsOccupied,
    int? totalPassengers,
    int? pricePerSeat,
    String? vehicleModel,
    String? vehicleNumber,
    String? notes,
    String? status,
    DateTime? createdAt,
    List<MyPublishRidePassengerEntity>? bookings,
  }) {
    return MyPublishRideDetailsEntity(
      id: id ?? this.id,
      rideCode: rideCode ?? this.rideCode,
      publisherId: publisherId ?? this.publisherId,
      publisherName: publisherName ?? this.publisherName,
      publisherPhone: publisherPhone ?? this.publisherPhone,
      publisherAvatar: publisherAvatar ?? this.publisherAvatar,
      originAddress: originAddress ?? this.originAddress,
      originCity: originCity ?? this.originCity,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      totalSeatsOccupied: totalSeatsOccupied ?? this.totalSeatsOccupied,
      totalPassengers: totalPassengers ?? this.totalPassengers,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bookings: bookings ?? this.bookings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        rideCode,
        publisherId,
        publisherName,
        publisherPhone,
        publisherAvatar,
        originAddress,
        originCity,
        originLat,
        originLng,
        destinationAddress,
        destinationCity,
        destinationLat,
        destinationLng,
        departureTime,
        availableSeats,
        totalSeats,
        totalSeatsOccupied,
        totalPassengers,
        pricePerSeat,
        vehicleModel,
        vehicleNumber,
        notes,
        status,
        createdAt,
        bookings,
      ];
}
