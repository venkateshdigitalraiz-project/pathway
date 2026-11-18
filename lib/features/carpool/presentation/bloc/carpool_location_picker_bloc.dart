import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../data/datasources/carpool_routes_remote_data_source.dart';
import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/usecases/get_place_from_coords_usecase.dart';
import '../../domain/usecases/search_carpool_places_usecase.dart';

// ════════════════════════════════════════════════════════════════════════════
// STEPS & EVENTS
// ════════════════════════════════════════════════════════════════════════════

enum CarpoolLocationStep { pickup, dropoff, routeReady }

abstract class CarpoolLocationPickerEvent extends Equatable {
  const CarpoolLocationPickerEvent();

  @override
  List<Object?> get props => [];
}

class CarpoolLocationPickerStarted extends CarpoolLocationPickerEvent {
  final CarpoolLocationStep initialStep;
  final CarpoolPlaceEntity? initialPickup;
  final CarpoolPlaceEntity? initialDropoff;

  const CarpoolLocationPickerStarted({
    this.initialStep = CarpoolLocationStep.pickup,
    this.initialPickup,
    this.initialDropoff,
  });

  @override
  List<Object?> get props => [initialStep, initialPickup, initialDropoff];
}

class CarpoolLocationPickerStepChanged extends CarpoolLocationPickerEvent {
  final CarpoolLocationStep step;

  const CarpoolLocationPickerStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}

class CarpoolLocationPickerQueryChanged extends CarpoolLocationPickerEvent {
  final String query;
  final CarpoolLocationStep? step;

  const CarpoolLocationPickerQueryChanged(this.query, {this.step});

  @override
  List<Object?> get props => [query, step];
}

class CarpoolLocationPickerPlaceSelected extends CarpoolLocationPickerEvent {
  final CarpoolPlaceEntity place;
  final CarpoolLocationStep? step;

  const CarpoolLocationPickerPlaceSelected(this.place, {this.step});

  @override
  List<Object?> get props => [place, step];
}

class CarpoolLocationPickerConfirmPickup extends CarpoolLocationPickerEvent {
  const CarpoolLocationPickerConfirmPickup();
}

class CarpoolLocationPickerSwapLocations extends CarpoolLocationPickerEvent {
  const CarpoolLocationPickerSwapLocations();
}

class CarpoolLocationPickerMapTapped extends CarpoolLocationPickerEvent {
  final double lat;
  final double lng;

  const CarpoolLocationPickerMapTapped({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

class CarpoolLocationPickerCameraMoved extends CarpoolLocationPickerEvent {
  final double lat;
  final double lng;

  const CarpoolLocationPickerCameraMoved({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

class CarpoolLocationPickerToggleMap extends CarpoolLocationPickerEvent {
  final bool? isFullscreen;

  const CarpoolLocationPickerToggleMap([this.isFullscreen]);

  @override
  List<Object?> get props => [isFullscreen];
}

class CarpoolLocationPickerSelectCurrentLocation extends CarpoolLocationPickerEvent {
  final double lat;
  final double lng;

  const CarpoolLocationPickerSelectCurrentLocation({
    this.lat = 17.3850,
    this.lng = 78.4867,
  });

  @override
  List<Object?> get props => [lat, lng];
}

// ════════════════════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════════════════════

enum CarpoolLocationPickerStatus { initial, loading, success, failure }

class CarpoolLocationPickerState extends Equatable {
  final CarpoolLocationPickerStatus status;
  final CarpoolLocationStep step;
  final String pickupQuery;
  final String dropoffQuery;
  final List<CarpoolPlaceEntity> places;
  final CarpoolPlaceEntity? pickupPlace;
  final CarpoolPlaceEntity? dropoffPlace;
  final double mapCenterLat;
  final double mapCenterLng;
  final double zoomLevel;
  final bool isMapFullscreen;
  final String? errorMessage;
  final int cameraUpdateToken;
  final int routeDistanceKm;
  final String routeDurationText;
  final List<({double lat, double lng})> routeWaypoints;

  const CarpoolLocationPickerState({
    this.status = CarpoolLocationPickerStatus.initial,
    this.step = CarpoolLocationStep.pickup,
    this.pickupQuery = '',
    this.dropoffQuery = '',
    this.places = const [],
    this.pickupPlace,
    this.dropoffPlace,
    this.mapCenterLat = 17.3850,
    this.mapCenterLng = 78.4867,
    this.zoomLevel = 12.0,
    this.isMapFullscreen = false,
    this.errorMessage,
    this.cameraUpdateToken = 0,
    this.routeDistanceKm = 0,
    this.routeDurationText = '',
    this.routeWaypoints = const [],
  });

  /// The actively selected place based on the current step
  CarpoolPlaceEntity? get selectedPlace =>
      step == CarpoolLocationStep.dropoff ? dropoffPlace : pickupPlace;

  String get query =>
      step == CarpoolLocationStep.dropoff ? dropoffQuery : pickupQuery;

  bool get hasBothLocations => pickupPlace != null && dropoffPlace != null;

  CarpoolLocationPickerState copyWith({
    CarpoolLocationPickerStatus? status,
    CarpoolLocationStep? step,
    String? pickupQuery,
    String? dropoffQuery,
    List<CarpoolPlaceEntity>? places,
    CarpoolPlaceEntity? pickupPlace,
    CarpoolPlaceEntity? dropoffPlace,
    bool clearDropoffPlace = false,
    double? mapCenterLat,
    double? mapCenterLng,
    double? zoomLevel,
    bool? isMapFullscreen,
    String? errorMessage,
    int? cameraUpdateToken,
    int? routeDistanceKm,
    String? routeDurationText,
    List<({double lat, double lng})>? routeWaypoints,
  }) {
    return CarpoolLocationPickerState(
      status: status ?? this.status,
      step: step ?? this.step,
      pickupQuery: pickupQuery ?? this.pickupQuery,
      dropoffQuery: dropoffQuery ?? this.dropoffQuery,
      places: places ?? this.places,
      pickupPlace: pickupPlace ?? this.pickupPlace,
      dropoffPlace: clearDropoffPlace
          ? null
          : (dropoffPlace ?? this.dropoffPlace),
      mapCenterLat: mapCenterLat ?? this.mapCenterLat,
      mapCenterLng: mapCenterLng ?? this.mapCenterLng,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isMapFullscreen: isMapFullscreen ?? this.isMapFullscreen,
      errorMessage: errorMessage ?? this.errorMessage,
      cameraUpdateToken: cameraUpdateToken ?? this.cameraUpdateToken,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      routeDurationText: routeDurationText ?? this.routeDurationText,
      routeWaypoints: routeWaypoints ?? this.routeWaypoints,
    );
  }

  @override
  List<Object?> get props => [
        status,
        step,
        pickupQuery,
        dropoffQuery,
        places,
        pickupPlace,
        dropoffPlace,
        mapCenterLat,
        mapCenterLng,
        zoomLevel,
        isMapFullscreen,
        errorMessage,
        cameraUpdateToken,
        routeDistanceKm,
        routeDurationText,
        routeWaypoints,
      ];
}

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════

class CarpoolLocationPickerBloc
    extends Bloc<CarpoolLocationPickerEvent, CarpoolLocationPickerState> {
  final SearchCarpoolPlacesUseCase searchPlacesUseCase;
  final GetPlaceFromCoordsUseCase getPlaceFromCoordsUseCase;
  final CarpoolRoutesRemoteDataSource routesDataSource;

  CarpoolLocationPickerBloc({
    required this.searchPlacesUseCase,
    required this.getPlaceFromCoordsUseCase,
    CarpoolRoutesRemoteDataSource? routesDataSource,
  })  : routesDataSource =
            routesDataSource ?? CarpoolRoutesRemoteDataSourceImpl(),
        super(const CarpoolLocationPickerState()) {
    on<CarpoolLocationPickerStarted>(_onStarted);
    on<CarpoolLocationPickerStepChanged>(_onStepChanged);
    on<CarpoolLocationPickerQueryChanged>(_onQueryChanged);
    on<CarpoolLocationPickerPlaceSelected>(_onPlaceSelected);
    on<CarpoolLocationPickerConfirmPickup>(_onConfirmPickup);
    on<CarpoolLocationPickerSwapLocations>(_onSwapLocations);
    on<CarpoolLocationPickerMapTapped>(_onMapTapped);
    on<CarpoolLocationPickerToggleMap>(_onToggleMap);
    on<CarpoolLocationPickerSelectCurrentLocation>(_onSelectCurrentLocation);
    on<CarpoolLocationPickerCameraMoved>(_onCameraMoved);
  }

  Future<void> _onStarted(
    CarpoolLocationPickerStarted event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolLocationPickerStatus.loading));
    try {
      final initialPlaces = await searchPlacesUseCase('');
      final defaultPlace = event.initialPickup ??
          (initialPlaces.isNotEmpty
              ? initialPlaces.first
              : const CarpoolPlaceEntity(
                  id: 'default_hyd',
                  name: 'Hyderabad',
                  formattedAddress: 'Telangana, India',
                  type: CarpoolPlaceType.city,
                  lat: 17.3850,
                  lng: 78.4867,
                ));

      if (event.initialStep == CarpoolLocationStep.dropoff) {
        final dropoffTarget = event.initialDropoff;
        final double centerLat = dropoffTarget?.lat ?? (defaultPlace.lat + 0.04);
        final double centerLng = dropoffTarget?.lng ?? (defaultPlace.lng + 0.04);

        emit(
          state.copyWith(
            status: CarpoolLocationPickerStatus.success,
            step: CarpoolLocationStep.dropoff,
            places: initialPlaces,
            pickupPlace: defaultPlace,
            pickupQuery: defaultPlace.name,
            dropoffPlace: dropoffTarget,
            dropoffQuery: dropoffTarget?.name ?? '',
            mapCenterLat: centerLat,
            mapCenterLng: centerLng,
            zoomLevel: 14.5,
            cameraUpdateToken: state.cameraUpdateToken + 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: CarpoolLocationPickerStatus.success,
            step: CarpoolLocationStep.pickup,
            places: initialPlaces,
            pickupPlace: defaultPlace,
            pickupQuery: defaultPlace.name,
            dropoffPlace: event.initialDropoff,
            dropoffQuery: event.initialDropoff?.name ?? '',
            mapCenterLat: defaultPlace.lat,
            mapCenterLng: defaultPlace.lng,
            zoomLevel: 15.0,
            cameraUpdateToken: state.cameraUpdateToken + 1,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: CarpoolLocationPickerStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStepChanged(
    CarpoolLocationPickerStepChanged event,
    Emitter<CarpoolLocationPickerState> emit,
  ) {
    double targetLat = state.mapCenterLat;
    double targetLng = state.mapCenterLng;
    double zoom = state.zoomLevel;

    if (event.step == CarpoolLocationStep.pickup && state.pickupPlace != null) {
      targetLat = state.pickupPlace!.lat;
      targetLng = state.pickupPlace!.lng;
      zoom = 15.0;
    } else if (event.step == CarpoolLocationStep.dropoff &&
        state.dropoffPlace != null) {
      targetLat = state.dropoffPlace!.lat;
      targetLng = state.dropoffPlace!.lng;
      zoom = 15.0;
    }

    emit(
      state.copyWith(
        step: event.step,
        mapCenterLat: targetLat,
        mapCenterLng: targetLng,
        zoomLevel: zoom,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      ),
    );
  }

  Future<void> _onQueryChanged(
    CarpoolLocationPickerQueryChanged event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    final queryText = event.query.trim();
    final activeStep = event.step ?? state.step;
    final updatedPickupQuery = activeStep == CarpoolLocationStep.pickup
        ? event.query
        : state.pickupQuery;
    final updatedDropoffQuery = activeStep == CarpoolLocationStep.dropoff
        ? event.query
        : state.dropoffQuery;

    emit(
      state.copyWith(
        pickupQuery: updatedPickupQuery,
        dropoffQuery: updatedDropoffQuery,
        status: CarpoolLocationPickerStatus.loading,
      ),
    );

    if (queryText.isEmpty) {
      final defaultPlaces = await searchPlacesUseCase('');
      emit(
        state.copyWith(
          status: CarpoolLocationPickerStatus.success,
          places: defaultPlaces,
        ),
      );
      return;
    }

    try {
      final results = await searchPlacesUseCase(queryText);
      emit(
        state.copyWith(
          status: CarpoolLocationPickerStatus.success,
          places: results,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CarpoolLocationPickerStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCameraMoved(
    CarpoolLocationPickerCameraMoved event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        mapCenterLat: event.lat,
        mapCenterLng: event.lng,
      ),
    );

    if (state.step == CarpoolLocationStep.routeReady) return;

    try {
      final place = await getPlaceFromCoordsUseCase(event.lat, event.lng);
      if (place != null) {
        if (state.step == CarpoolLocationStep.pickup) {
          emit(
            state.copyWith(
              pickupPlace: place,
              pickupQuery: place.name,
            ),
          );
        } else if (state.step == CarpoolLocationStep.dropoff) {
          emit(
            state.copyWith(
              dropoffPlace: place,
              dropoffQuery: place.name,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _onPlaceSelected(
    CarpoolLocationPickerPlaceSelected event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    final activeStep = event.step ?? state.step;

    if (activeStep == CarpoolLocationStep.pickup) {
      final updatedPickup = event.place;

      CarpoolLocationPickerState next = state.copyWith(
        pickupPlace: updatedPickup,
        pickupQuery: updatedPickup.name,
        mapCenterLat: updatedPickup.lat,
        mapCenterLng: updatedPickup.lng,
        zoomLevel: 15.5,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      );

      emit(next);

      if (state.dropoffPlace != null) {
        await _fetchDirectionsRoute(next.pickupPlace!, state.dropoffPlace!, emit);
      }
    } else {
      // Setting Dropoff
      final updatedDropoff = event.place;
      CarpoolLocationPickerState next = state.copyWith(
        dropoffPlace: updatedDropoff,
        dropoffQuery: updatedDropoff.name,
        mapCenterLat: updatedDropoff.lat,
        mapCenterLng: updatedDropoff.lng,
        zoomLevel: 15.5,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      );

      emit(next);

      if (state.pickupPlace != null) {
        await _fetchDirectionsRoute(state.pickupPlace!, next.dropoffPlace!, emit);
      }
    }
  }

  Future<void> _onConfirmPickup(
    CarpoolLocationPickerConfirmPickup event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    CarpoolPlaceEntity? pickup = state.pickupPlace;
    if (pickup == null) {
      pickup = CarpoolPlaceEntity(
        id: 'pickup_${state.mapCenterLat}_${state.mapCenterLng}',
        name: state.pickupQuery.isNotEmpty ? state.pickupQuery : 'Pick-up Point',
        formattedAddress:
            'Coordinates: ${state.mapCenterLat.toStringAsFixed(4)}, ${state.mapCenterLng.toStringAsFixed(4)}',
        type: CarpoolPlaceType.locality,
        lat: state.mapCenterLat,
        lng: state.mapCenterLng,
      );
    }

    CarpoolLocationPickerState next = state.copyWith(
      pickupPlace: pickup,
      pickupQuery: pickup.name,
      step: CarpoolLocationStep.dropoff,
      cameraUpdateToken: state.cameraUpdateToken + 1,
    );

    emit(next);

    if (next.dropoffPlace != null) {
      await _fetchDirectionsRoute(next.pickupPlace!, next.dropoffPlace!, emit);
    }
  }

  Future<void> _onSwapLocations(
    CarpoolLocationPickerSwapLocations event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    final tempPickup = state.pickupPlace;
    final tempDropoff = state.dropoffPlace;
    final tempPickupQuery = state.pickupQuery;
    final tempDropoffQuery = state.dropoffQuery;

    CarpoolLocationPickerState next = state.copyWith(
      pickupPlace: tempDropoff,
      dropoffPlace: tempPickup,
      pickupQuery: tempDropoffQuery,
      dropoffQuery: tempPickupQuery,
      cameraUpdateToken: state.cameraUpdateToken + 1,
    );

    emit(next);

    if (next.pickupPlace != null && next.dropoffPlace != null) {
      await _fetchDirectionsRoute(next.pickupPlace!, next.dropoffPlace!, emit);
    }
  }

  Future<void> _fetchDirectionsRoute(
    CarpoolPlaceEntity origin,
    CarpoolPlaceEntity destination,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    try {
      final routes = await routesDataSource.getRouteOptions(
        origin: origin,
        destination: destination,
      );

      if (routes.isNotEmpty) {
        final primaryRoute = routes.first;
        final waypoints = primaryRoute.waypoints
            .map((w) => (lat: w.lat, lng: w.lng))
            .toList();

        emit(
          state.copyWith(
            routeDistanceKm: primaryRoute.distanceKm,
            routeDurationText: primaryRoute.durationText,
            routeWaypoints: waypoints,
            step: CarpoolLocationStep.routeReady,
            cameraUpdateToken: state.cameraUpdateToken + 1,
          ),
        );
        return;
      }
    } catch (_) {}

    // Fallback: Haversine distance and corridor waypoints
    final dist = CarpoolDistanceCalculator.calculateDistanceKm(
      origin.name,
      destination.name,
      fromLat: origin.lat,
      fromLng: origin.lng,
      toLat: destination.lat,
      toLng: destination.lng,
    );
    final duration = CarpoolDistanceCalculator.estimateDuration(dist);
    final waypoints = CarpoolDistanceCalculator.generateDrivingRouteWaypoints(
      fromLat: origin.lat,
      fromLng: origin.lng,
      toLat: destination.lat,
      toLng: destination.lng,
    );

    emit(
      state.copyWith(
        routeDistanceKm: dist,
        routeDurationText: duration,
        routeWaypoints: waypoints,
        step: CarpoolLocationStep.routeReady,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      ),
    );
  }

  Future<void> _onMapTapped(
    CarpoolLocationPickerMapTapped event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        mapCenterLat: event.lat,
        mapCenterLng: event.lng,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      ),
    );

    try {
      final place = await getPlaceFromCoordsUseCase(event.lat, event.lng);
      if (place != null) {
        add(CarpoolLocationPickerPlaceSelected(place, step: state.step));
      }
    } catch (_) {}
  }

  void _onToggleMap(
    CarpoolLocationPickerToggleMap event,
    Emitter<CarpoolLocationPickerState> emit,
  ) {
    final nextFullscreen = event.isFullscreen ?? !state.isMapFullscreen;
    emit(state.copyWith(isMapFullscreen: nextFullscreen));
  }

  Future<void> _onSelectCurrentLocation(
    CarpoolLocationPickerSelectCurrentLocation event,
    Emitter<CarpoolLocationPickerState> emit,
  ) async {
    emit(
      state.copyWith(
        mapCenterLat: event.lat,
        mapCenterLng: event.lng,
        zoomLevel: 14.5,
        cameraUpdateToken: state.cameraUpdateToken + 1,
      ),
    );

    final place = await getPlaceFromCoordsUseCase(event.lat, event.lng);
    if (place != null) {
      add(
        CarpoolLocationPickerPlaceSelected(
          place,
          step: CarpoolLocationStep.pickup,
        ),
      );
    }
  }

  CarpoolLocationPickerState _calculateRouteData(
    CarpoolLocationPickerState cur,
  ) {
    if (cur.pickupPlace == null || cur.dropoffPlace == null) return cur;

    final p = cur.pickupPlace!;
    final d = cur.dropoffPlace!;

    final dist = CarpoolDistanceCalculator.calculateDistanceKm(
      p.name,
      d.name,
      fromLat: p.lat,
      fromLng: p.lng,
      toLat: d.lat,
      toLng: d.lng,
    );

    final duration = CarpoolDistanceCalculator.estimateDuration(dist);
    final waypoints = CarpoolDistanceCalculator.generateDrivingRouteWaypoints(
      fromLat: p.lat,
      fromLng: p.lng,
      toLat: d.lat,
      toLng: d.lng,
    );

    return cur.copyWith(
      routeDistanceKm: dist,
      routeDurationText: duration,
      routeWaypoints: waypoints,
    );
  }
}
