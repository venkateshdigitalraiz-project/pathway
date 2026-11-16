import '../../domain/entities/rider_booking_entity.dart';

class RiderBookingModel extends RiderBookingEntity {
  const RiderBookingModel({
    required super.id,
    required super.rideId,
    required super.driverName,
    required super.driverPhone,
    required super.driverRating,
    required super.vehicle,
    required super.from,
    required super.to,
    required super.departure,
    required super.seatsBooked,
    required super.pricePerSeat,
    required super.totalAmount,
    required super.status,
    required super.bookingDate,
    super.vehicleNumber,
    super.otpCode,
    super.passengerNotes,
  });

  factory RiderBookingModel.fromJson(Map<String, dynamic> json) {
    // 1. Driver info
    String driverName = 'Driver';
    String driverPhone = '';
    double driverRating = 0.0;
    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverName = d['name']?.toString() ?? driverName;
      driverPhone = d['phone']?.toString() ?? driverPhone;
      driverRating = (d['rating'] as num?)?.toDouble() ?? driverRating;
    } else {
      driverName = json['driverName']?.toString() ?? driverName;
      driverPhone = json['driverPhone']?.toString() ?? driverPhone;
      driverRating =
          (json['driverRating'] as num?)?.toDouble() ?? driverRating;
    }

    // 2. Locations
    final from = json['from']?.toString() ??
        json['origin']?.toString() ??
        json['pickup']?.toString() ??
        '';
    final to = json['to']?.toString() ??
        json['destination']?.toString() ??
        json['dropoff']?.toString() ??
        '';

    // 3. Timestamps
    DateTime departure = DateTime.now().add(const Duration(hours: 3));
    final depRaw = json['departure'] ?? json['departureTime'] ?? json['date'];
    if (depRaw != null) {
      final parsed = DateTime.tryParse(depRaw.toString());
      if (parsed != null) departure = parsed.toLocal();
    }

    DateTime bookingDate = DateTime.now();
    final bookRaw = json['bookingDate'] ?? json['createdAt'];
    if (bookRaw != null) {
      final parsed = DateTime.tryParse(bookRaw.toString());
      if (parsed != null) bookingDate = parsed.toLocal();
    }

    // 4. Seats & Pricing
    final seatsBooked = (json['seatsBooked'] as num?)?.toInt() ??
        (json['seats'] as num?)?.toInt() ??
        1;
    final totalAmount = (json['totalAmount'] as num?)?.toInt() ??
        (json['totalPrice'] as num?)?.toInt() ??
        (json['fare'] as num?)?.toInt() ??
        0;
    final pricePerSeat = (json['pricePerSeat'] as num?)?.toInt() ??
        (json['price'] as num?)?.toInt() ??
        (seatsBooked > 0 && totalAmount > 0
            ? (totalAmount ~/ seatsBooked)
            : 0);

    // 5. Vehicle
    final vehicle = json['vehicle']?.toString() ??
        json['vehicleModel']?.toString() ??
        '';
    final vehicleNumber = json['vehicleNumber']?.toString();
    final otpCode = json['otpCode']?.toString() ?? json['otp']?.toString();
    final passengerNotes = json['passengerNotes']?.toString() ??
        json['notes']?.toString();

    // 6. Status
    RiderBookingStatus status = RiderBookingStatus.confirmed;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr != null) {
      if (statusStr == 'completed') {
        status = RiderBookingStatus.completed;
      } else if (statusStr == 'cancelled' || statusStr == 'canceled') {
        status = RiderBookingStatus.cancelled;
      } else {
        status = RiderBookingStatus.confirmed;
      }
    }

    return RiderBookingModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          'bk-${DateTime.now().millisecondsSinceEpoch}',
      rideId: json['rideId']?.toString() ?? 'ride-default',
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
      status: status,
      bookingDate: bookingDate,
      vehicleNumber: vehicleNumber,
      otpCode: otpCode,
      passengerNotes: passengerNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'driverRating': driverRating,
        'vehicle': vehicle,
        'from': from,
        'to': to,
        'departure': departure.toIso8601String(),
        'seatsBooked': seatsBooked,
        'pricePerSeat': pricePerSeat,
        'totalAmount': totalAmount,
        'status': status.name,
        'bookingDate': bookingDate.toIso8601String(),
        'vehicleNumber': vehicleNumber,
        'otpCode': otpCode,
        'passengerNotes': passengerNotes,
      };

  @override
  RiderBookingModel copyWith({
    RiderBookingStatus? status,
    String? passengerNotes,
  }) {
    return RiderBookingModel(
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
      vehicleNumber: vehicleNumber,
      otpCode: otpCode,
      passengerNotes: passengerNotes ?? this.passengerNotes,
    );
  }
}

