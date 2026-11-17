import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/start_ride_entity.dart';

// ── EVENTS ───────────────────────────────────────────────────────────────────

abstract class StartRideEvent extends Equatable {
  const StartRideEvent();

  @override
  List<Object?> get props => [];
}

class StartRideStarted extends StartRideEvent {
  final CarpoolRideEntity ride;
  final StartRidePassengerEntity? customPassenger;

  const StartRideStarted(this.ride, {this.customPassenger});

  @override
  List<Object?> get props => [ride, customPassenger];
}

class StartRideStepSet extends StartRideEvent {
  final StartRideStep step;

  const StartRideStepSet(this.step);

  @override
  List<Object?> get props => [step];
}

class StartRideNextStepPressed extends StartRideEvent {
  const StartRideNextStepPressed();
}

class StartRidePreviousStepPressed extends StartRideEvent {
  const StartRidePreviousStepPressed();
}

class StartRideCallPassengerPressed extends StartRideEvent {
  const StartRideCallPassengerPressed();
}

class StartRideMessagePassengerPressed extends StartRideEvent {
  const StartRideMessagePassengerPressed();
}

class StartRideShareLocationPressed extends StartRideEvent {
  const StartRideShareLocationPressed();
}

class StartRideEndRidePressed extends StartRideEvent {
  const StartRideEndRidePressed();
}

// ── STATE ────────────────────────────────────────────────────────────────────

class StartRideState extends Equatable {
  final CarpoolStatus status;
  final CarpoolRideEntity? ride;
  final StartRidePassengerEntity? passenger;
  final StartRideStep step;
  final String? message;
  final bool isCompleted;

  const StartRideState({
    this.status = CarpoolStatus.initial,
    this.ride,
    this.passenger,
    this.step = StartRideStep.todaysRide,
    this.message,
    this.isCompleted = false,
  });

  StartRideState copyWith({
    CarpoolStatus? status,
    CarpoolRideEntity? ride,
    StartRidePassengerEntity? passenger,
    StartRideStep? step,
    String? message,
    bool? isCompleted,
  }) {
    return StartRideState(
      status: status ?? this.status,
      ride: ride ?? this.ride,
      passenger: passenger ?? this.passenger,
      step: step ?? this.step,
      message: message,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ride,
        passenger,
        step,
        message,
        isCompleted,
      ];
}

// ── BLOC ─────────────────────────────────────────────────────────────────────

class StartRideBloc extends Bloc<StartRideEvent, StartRideState> {
  StartRideBloc({
    CarpoolRideEntity? initialRide,
    StartRidePassengerEntity? initialPassenger,
  }) : super(
          StartRideState(
            status: CarpoolStatus.success,
            ride: initialRide,
            passenger: initialRide != null
                ? createDefaultPassenger(
                    initialRide,
                    customPassenger: initialPassenger,
                  )
                : initialPassenger,
            step: StartRideStep.todaysRide,
          ),
        ) {
    on<StartRideStarted>(_onStarted);
    on<StartRideStepSet>(_onStepSet);
    on<StartRideNextStepPressed>(_onNextStep);
    on<StartRidePreviousStepPressed>(_onPreviousStep);
    on<StartRideCallPassengerPressed>(_onCallPassenger);
    on<StartRideMessagePassengerPressed>(_onMessagePassenger);
    on<StartRideShareLocationPressed>(_onShareLocation);
    on<StartRideEndRidePressed>(_onEndRide);
  }

  static StartRidePassengerEntity createDefaultPassenger(
    CarpoolRideEntity ride, {
    StartRidePassengerEntity? customPassenger,
  }) {
    if (customPassenger != null) return customPassenger;

    // Resolve clean vehicle model name (e.g. Sedan, Honda City, Maruti, etc.)
    String vehicleType = 'Sedan';
    if (ride.vehicleModel != null && ride.vehicleModel!.trim().isNotEmpty) {
      vehicleType = ride.vehicleModel!.trim();
    } else if (ride.vehicle.isNotEmpty) {
      final parts = ride.vehicle.split('•');
      vehicleType = parts.first.trim();
    }

    return StartRidePassengerEntity(
      id: 'pass-${ride.id.hashCode.abs() % 10000}',
      name: 'Priya Sharma',
      phone: '+91 98765 43210',
      rating: 4.8,
      totalRides: 24,
      pickupLocation: ride.from.isNotEmpty ? ride.from : 'LB Nagar, Hyderabad',
      dropoffLocation: ride.to.isNotEmpty ? ride.to : 'Miyapur, Hyderabad',
      distanceToPassengerKm: 2.8,
      etaToPassengerMin: 6,
      journeyDistanceKm:
          ride.distanceKm > 0 ? ride.distanceKm.toDouble() : 12.5,
      journeyEtaMin:
          ride.distanceKm > 0 ? (ride.distanceKm * 2).clamp(10, 60) : 25,
      vehicleType: vehicleType,
      passengerCount: 1,
      otp: '4821',
    );
  }

  void _onStarted(StartRideStarted event, Emitter<StartRideState> emit) {
    final ride = event.ride;
    final effectivePassenger = createDefaultPassenger(
      ride,
      customPassenger: event.customPassenger,
    );

    emit(
      state.copyWith(
        status: CarpoolStatus.success,
        ride: ride,
        passenger: effectivePassenger,
        step: StartRideStep.todaysRide,
        isCompleted: false,
      ),
    );
  }

  void _onStepSet(StartRideStepSet event, Emitter<StartRideState> emit) {
    emit(state.copyWith(step: event.step));
  }

  void _onNextStep(
    StartRideNextStepPressed event,
    Emitter<StartRideState> emit,
  ) {
    switch (state.step) {
      case StartRideStep.todaysRide:
        emit(
          state.copyWith(
            step: StartRideStep.navigateToPassenger,
            message: 'Navigating to pickup point...',
          ),
        );
        break;
      case StartRideStep.navigateToPassenger:
        emit(
          state.copyWith(
            step: StartRideStep.passengerPickedUp,
            message: 'Passenger reached successfully!',
          ),
        );
        break;
      case StartRideStep.passengerPickedUp:
        emit(
          state.copyWith(
            step: StartRideStep.startJourney,
            message: 'Journey started towards destination.',
          ),
        );
        break;
      case StartRideStep.startJourney:
        emit(
          state.copyWith(
            step: StartRideStep.rideInProgress,
          ),
        );
        break;
      case StartRideStep.rideInProgress:
        add(const StartRideEndRidePressed());
        break;
    }
  }

  void _onPreviousStep(
    StartRidePreviousStepPressed event,
    Emitter<StartRideState> emit,
  ) {
    switch (state.step) {
      case StartRideStep.todaysRide:
        // Already at root step
        break;
      case StartRideStep.navigateToPassenger:
        emit(state.copyWith(step: StartRideStep.todaysRide));
        break;
      case StartRideStep.passengerPickedUp:
        emit(state.copyWith(step: StartRideStep.navigateToPassenger));
        break;
      case StartRideStep.startJourney:
        emit(state.copyWith(step: StartRideStep.passengerPickedUp));
        break;
      case StartRideStep.rideInProgress:
        emit(state.copyWith(step: StartRideStep.startJourney));
        break;
    }
  }

  void _onCallPassenger(
    StartRideCallPassengerPressed event,
    Emitter<StartRideState> emit,
  ) {
    final phone = state.passenger?.phone ?? '+91 98765 43210';
    emit(state.copyWith(message: 'Calling $phone...'));
  }

  void _onMessagePassenger(
    StartRideMessagePassengerPressed event,
    Emitter<StartRideState> emit,
  ) {
    final name = state.passenger?.name ?? 'Passenger';
    emit(state.copyWith(message: 'Opening chat with $name...'));
  }

  void _onShareLocation(
    StartRideShareLocationPressed event,
    Emitter<StartRideState> emit,
  ) {
    emit(state.copyWith(message: 'Live location shared with passenger!'));
  }

  void _onEndRide(
    StartRideEndRidePressed event,
    Emitter<StartRideState> emit,
  ) {
    emit(
      state.copyWith(
        isCompleted: true,
        message: 'Ride completed successfully! Great job!',
      ),
    );
  }
}
