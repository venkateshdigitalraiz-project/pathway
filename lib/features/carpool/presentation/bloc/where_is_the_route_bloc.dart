import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/entities/carpool_route_option_entity.dart';
import '../../domain/usecases/get_carpool_route_options_usecase.dart';

// ════════════════════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════════════════════

abstract class WhereIsTheRouteEvent extends Equatable {
  const WhereIsTheRouteEvent();

  @override
  List<Object?> get props => [];
}

class WhereIsTheRouteStarted extends WhereIsTheRouteEvent {
  final CarpoolPlaceEntity origin;
  final CarpoolPlaceEntity destination;

  const WhereIsTheRouteStarted({
    required this.origin,
    required this.destination,
  });

  @override
  List<Object?> get props => [origin, destination];
}

class WhereIsTheRouteOptionSelected extends WhereIsTheRouteEvent {
  final int index;

  const WhereIsTheRouteOptionSelected(this.index);

  @override
  List<Object?> get props => [index];
}

// ════════════════════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════════════════════

enum WhereIsTheRouteStatus { initial, loading, success, failure }

class WhereIsTheRouteState extends Equatable {
  final WhereIsTheRouteStatus status;
  final CarpoolPlaceEntity? origin;
  final CarpoolPlaceEntity? destination;
  final List<CarpoolRouteOptionEntity> routes;
  final int selectedIndex;
  final String? errorMessage;

  const WhereIsTheRouteState({
    this.status = WhereIsTheRouteStatus.initial,
    this.origin,
    this.destination,
    this.routes = const [],
    this.selectedIndex = 0,
    this.errorMessage,
  });

  CarpoolRouteOptionEntity? get selectedRoute =>
      (routes.isNotEmpty && selectedIndex < routes.length)
          ? routes[selectedIndex]
          : null;

  WhereIsTheRouteState copyWith({
    WhereIsTheRouteStatus? status,
    CarpoolPlaceEntity? origin,
    CarpoolPlaceEntity? destination,
    List<CarpoolRouteOptionEntity>? routes,
    int? selectedIndex,
    String? errorMessage,
  }) {
    return WhereIsTheRouteState(
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      routes: routes ?? this.routes,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        origin,
        destination,
        routes,
        selectedIndex,
        errorMessage,
      ];
}

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════

class WhereIsTheRouteBloc
    extends Bloc<WhereIsTheRouteEvent, WhereIsTheRouteState> {
  final GetCarpoolRouteOptionsUseCase getRouteOptionsUseCase;

  WhereIsTheRouteBloc({required this.getRouteOptionsUseCase})
      : super(const WhereIsTheRouteState()) {
    on<WhereIsTheRouteStarted>(_onStarted);
    on<WhereIsTheRouteOptionSelected>(_onOptionSelected);
  }

  Future<void> _onStarted(
    WhereIsTheRouteStarted event,
    Emitter<WhereIsTheRouteState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WhereIsTheRouteStatus.loading,
        origin: event.origin,
        destination: event.destination,
      ),
    );

    try {
      final routeOptions = await getRouteOptionsUseCase(
        origin: event.origin,
        destination: event.destination,
      );

      emit(
        state.copyWith(
          status: WhereIsTheRouteStatus.success,
          routes: routeOptions,
          selectedIndex: 0,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WhereIsTheRouteStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onOptionSelected(
    WhereIsTheRouteOptionSelected event,
    Emitter<WhereIsTheRouteState> emit,
  ) {
    emit(state.copyWith(selectedIndex: event.index));
  }
}
