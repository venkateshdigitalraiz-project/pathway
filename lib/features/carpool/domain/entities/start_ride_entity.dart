import 'package:equatable/equatable.dart';
import 'carpool_entities.dart';

/// The 5 visual sub-screens of the Start Ride lifecycle
enum StartRideStep {
  todaysRide,          // 1. Today's Ride overview
  navigateToPassenger, // 2. Navigate to Passenger map screen
  passengerPickedUp,   // 4. Passenger Picked Up celebration screen
  startJourney,        // 5. In Journey navigation route screen
  rideInProgress,      // 6. Heading to Destination scenic view screen
}

/// Information about the passenger for the active ride.
class StartRidePassengerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int totalRides;
  final String? avatarUrl;
  final String pickupLocation;
  final String dropoffLocation;
  final double distanceToPassengerKm;
  final int etaToPassengerMin;
  final double journeyDistanceKm;
  final int journeyEtaMin;
  final String vehicleType;
  final int passengerCount;
  final String? otp;

  const StartRidePassengerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.totalRides,
    this.avatarUrl,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceToPassengerKm,
    required this.etaToPassengerMin,
    required this.journeyDistanceKm,
    required this.journeyEtaMin,
    this.vehicleType = 'Sedan',
    this.passengerCount = 1,
    this.otp,
  });

  StartRidePassengerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    double? rating,
    int? totalRides,
    String? avatarUrl,
    String? pickupLocation,
    String? dropoffLocation,
    double? distanceToPassengerKm,
    int? etaToPassengerMin,
    double? journeyDistanceKm,
    int? journeyEtaMin,
    String? vehicleType,
    int? passengerCount,
    String? otp,
  }) {
    return StartRidePassengerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      distanceToPassengerKm:
          distanceToPassengerKm ?? this.distanceToPassengerKm,
      etaToPassengerMin: etaToPassengerMin ?? this.etaToPassengerMin,
      journeyDistanceKm: journeyDistanceKm ?? this.journeyDistanceKm,
      journeyEtaMin: journeyEtaMin ?? this.journeyEtaMin,
      vehicleType: vehicleType ?? this.vehicleType,
      passengerCount: passengerCount ?? this.passengerCount,
      otp: otp ?? this.otp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        rating,
        totalRides,
        avatarUrl,
        pickupLocation,
        dropoffLocation,
        distanceToPassengerKm,
        etaToPassengerMin,
        journeyDistanceKm,
        journeyEtaMin,
        vehicleType,
        passengerCount,
        otp,
      ];
}

/// Entity holding complete state for the Start Ride screen.
class StartRideEntity extends Equatable {
  final CarpoolRideEntity ride;
  final StartRidePassengerEntity passenger;
  final StartRideStep step;

  const StartRideEntity({
    required this.ride,
    required this.passenger,
    this.step = StartRideStep.todaysRide,
  });

  StartRideEntity copyWith({
    CarpoolRideEntity? ride,
    StartRidePassengerEntity? passenger,
    StartRideStep? step,
  }) {
    return StartRideEntity(
      ride: ride ?? this.ride,
      passenger: passenger ?? this.passenger,
      step: step ?? this.step,
    );
  }

  @override
  List<Object?> get props => [ride, passenger, step];
}
