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
    super.vehicleModel,
    super.otpCode,
    super.passengerNotes,
  });

  factory RiderBookingModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? rideMap;
    if (json['ride'] is Map<String, dynamic>) {
      rideMap = json['ride'] as Map<String, dynamic>;
    }

    // 1. Driver info
    String driverName = 'Driver';
    String driverPhone = '';
    double driverRating = 0.0;
    if (json['driver'] is Map<String, dynamic>) {
      final d = json['driver'] as Map<String, dynamic>;
      driverName = d['name']?.toString() ?? driverName;
      driverPhone = d['phone']?.toString() ?? driverPhone;
      driverRating = (d['rating'] as num?)?.toDouble() ?? driverRating;
    } else if (rideMap != null && rideMap['driver'] is Map<String, dynamic>) {
      final d = rideMap['driver'] as Map<String, dynamic>;
      driverName = d['name']?.toString() ?? driverName;
      driverPhone = d['phone']?.toString() ?? driverPhone;
      driverRating = (d['rating'] as num?)?.toDouble() ?? driverRating;
    } else {
      driverName =
          json['driverName']?.toString() ??
          rideMap?['driverName']?.toString() ??
          driverName;
      driverPhone =
          json['driverPhone']?.toString() ??
          rideMap?['driverPhone']?.toString() ??
          driverPhone;
      driverRating =
          (json['driverRating'] as num?)?.toDouble() ??
          (rideMap?['driverRating'] as num?)?.toDouble() ??
          driverRating;
    }

    // 2. Locations (supports both object with address/city/locality or plain string)
    String extractLocation(dynamic loc) {
      if (loc == null) return '';
      if (loc is Map<String, dynamic>) {
        final addr = loc['address']?.toString().trim();
        if (addr != null && addr.isNotEmpty) return addr;
        final city = loc['city']?.toString().trim();
        if (city != null && city.isNotEmpty) return city;
        final locality = loc['locality']?.toString().trim();
        if (locality != null && locality.isNotEmpty) return locality;
        final name = loc['name']?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
        return '';
      }
      if (loc is String) return loc.trim();
      return loc.toString().trim();
    }

    String from = extractLocation(json['from']);
    if (from.isEmpty) from = extractLocation(json['origin']);
    if (from.isEmpty) from = extractLocation(json['pickup']);
    if (from.isEmpty && rideMap != null) {
      from = extractLocation(rideMap['origin']);
      if (from.isEmpty) from = rideMap['originCity']?.toString() ?? '';
    }

    String to = extractLocation(json['to']);
    if (to.isEmpty) to = extractLocation(json['destination']);
    if (to.isEmpty) to = extractLocation(json['dropoff']);
    if (to.isEmpty && rideMap != null) {
      to = extractLocation(rideMap['destination']);
      if (to.isEmpty) to = rideMap['destinationCity']?.toString() ?? '';
    }

    // 3. Timestamps
    DateTime departure = DateTime.now().add(const Duration(hours: 3));
    final depRaw =
        json['departure'] ??
        json['departureTime'] ??
        rideMap?['departureTime'] ??
        json['date'] ??
        rideMap?['date'];
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
    final seatsBooked =
        (json['seatsBooked'] as num?)?.toInt() ??
        (json['seats'] as num?)?.toInt() ??
        1;
    final totalAmount =
        (json['totalAmount'] as num?)?.toInt() ??
        (json['totalPrice'] as num?)?.toInt() ??
        (json['fare'] as num?)?.toInt() ??
        0;
    final pricePerSeat =
        (json['pricePerSeat'] as num?)?.toInt() ??
        (rideMap?['pricePerSeat'] as num?)?.toInt() ??
        (json['price'] as num?)?.toInt() ??
        (seatsBooked > 0 && totalAmount > 0 ? (totalAmount ~/ seatsBooked) : 0);

    // 5. Vehicle & Registration (supports "vehicleModel": "Hgigih" and "vehicleNumber": "GVJVHCY")
    final vehicleModel = json['vehicleModel']?.toString().trim() ??
        rideMap?['vehicleModel']?.toString().trim() ??
        json['vehicle']?.toString().trim() ??
        rideMap?['vehicle']?.toString().trim() ??
        '';
    final vehicleNumber = json['vehicleNumber']?.toString().trim() ??
        rideMap?['vehicleNumber']?.toString().trim();
    final vehicle = vehicleModel.isNotEmpty
        ? (vehicleNumber != null && vehicleNumber.isNotEmpty
            ? '$vehicleModel • $vehicleNumber'
            : vehicleModel)
        : (vehicleNumber ?? '');
    final otpCode = json['otpCode']?.toString() ?? json['otp']?.toString();
    final passengerNotes =
        json['passengerNotes']?.toString() ??
        json['notes']?.toString() ??
        rideMap?['notes']?.toString();

    // 6. Status: check 'bookingStatus' first (API sends "bookingStatus": "confirmed" / "cancelled"), then 'status'
    RiderBookingStatus status = RiderBookingStatus.confirmed;
    final statusStr = (json['bookingStatus'] ?? json['status'])
        ?.toString()
        .toLowerCase()
        .trim();
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
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          'bk-${DateTime.now().millisecondsSinceEpoch}',
      rideId: json['rideId']?.toString() ?? 'ride-default',
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      vehicle: vehicle,
      vehicleModel: vehicleModel.isNotEmpty ? vehicleModel : null,
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
    'vehicleModel': vehicleModel,
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
    String? vehicleModel,
    String? vehicleNumber,
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
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      otpCode: otpCode,
      passengerNotes: passengerNotes ?? this.passengerNotes,
    );
  }
}
