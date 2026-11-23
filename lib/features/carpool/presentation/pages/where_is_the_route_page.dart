import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/carpool_distance_calculator.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/datasources/carpool_routes_remote_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../data/repositories/carpool_routes_repository_impl.dart';
import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/entities/carpool_route_option_entity.dart';
import '../../domain/entities/carpool_temporary_ride_data.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../../domain/usecases/get_carpool_route_options_usecase.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../bloc/where_is_the_route_bloc.dart';
import '../widgets/real_google_map_picker.dart';
import 'carpool_stopovers_page.dart';

/// Screen matching 1:1 the "What is your route?" tolling map design:
/// 1. Top real Google Map displaying authentic highway route polyline & markers.
/// 2. Clean back button overlaying top-left of the map.
/// 3. White bottom sheet with "What is your route?" heading.
/// 4. Radio options for Tolls vs No Tolls with distance & duration.
/// 5. Vibrant circular blue Next button (→) at bottom right.
class WhereIsTheRoutePage extends StatelessWidget {
  final CarpoolPlaceEntity origin;
  final CarpoolPlaceEntity destination;

  const WhereIsTheRoutePage({
    super.key,
    required this.origin,
    required this.destination,
  });

  /// Navigates to [WhereIsTheRoutePage] safely on the root navigator.
  static Future<void> show(
    BuildContext context, {
    required CarpoolPlaceEntity origin,
    required CarpoolPlaceEntity destination,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) =>
            WhereIsTheRoutePage(origin: origin, destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = CarpoolRoutesRemoteDataSourceImpl();
    final repository = CarpoolRoutesRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final useCase = GetCarpoolRouteOptionsUseCase(repository);

    return BlocProvider<WhereIsTheRouteBloc>(
      create: (_) {
        // Clear any previous stale session data when starting a new route selection
        CarpoolTemporaryRideData.instance.clear();
        return WhereIsTheRouteBloc(getRouteOptionsUseCase: useCase)
          ..add(WhereIsTheRouteStarted(origin: origin, destination: destination));
      },
      child: const _WhereIsTheRouteView(),
    );
  }
}

class _WhereIsTheRouteView extends StatefulWidget {
  const _WhereIsTheRouteView();

  @override
  State<_WhereIsTheRouteView> createState() => _WhereIsTheRouteViewState();
}

class _WhereIsTheRouteViewState extends State<_WhereIsTheRouteView> {
  final GlobalKey<RealGoogleMapPickerState> _mapKey =
      GlobalKey<RealGoogleMapPickerState>();
  GoogleMapController? _mapController;
  bool _hasFittedCamera = false;
  double? _userZoom;
  double? _userCenterLat;
  double? _userCenterLng;

  void _fitCameraToBounds(List<RouteCoordinate> waypoints) {
    if (waypoints.isEmpty) return;

    _mapKey.currentState?.fitBounds(
      waypoints.map((w) => (lat: w.lat, lng: w.lng)).toList(),
    );

    if (_mapController == null) return;

    double minLat = waypoints.first.lat;
    double maxLat = waypoints.first.lat;
    double minLng = waypoints.first.lng;
    double maxLng = waypoints.first.lng;

    for (final pt in waypoints) {
      if (pt.lat < minLat) minLat = pt.lat;
      if (pt.lat > maxLat) maxLat = pt.lat;
      if (pt.lng < minLng) minLng = pt.lng;
      if (pt.lng > maxLng) maxLng = pt.lng;
    }

    // Ensure non-zero delta to prevent LatLngBounds crashes on Android
    final double latDelta = (maxLat - minLat).abs();
    final double lngDelta = (maxLng - minLng).abs();
    if (latDelta < 0.02) {
      final pad = (0.02 - latDelta) / 2;
      minLat -= pad;
      maxLat += pad;
    }
    if (lngDelta < 0.02) {
      final pad = (0.02 - lngDelta) / 2;
      minLng -= pad;
      maxLng += pad;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    } catch (_) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(centerLat, centerLng), zoom: 11.5),
        ),
      );
    }
  }

  void _onNextPressed(BuildContext context) {
    final routeBloc = context.read<WhereIsTheRouteBloc>();
    final state = routeBloc.state;
    if (state.origin == null || state.destination == null) return;

    final origin = state.origin!;
    final destination = state.destination!;
    final selectedRoute = (state.routes.isNotEmpty &&
            state.selectedIndex >= 0 &&
            state.selectedIndex < state.routes.length)
        ? state.routes[state.selectedIndex]
        : (state.selectedRoute ??
            CarpoolTemporaryRideData.instance.selectedRoute ??
            (state.routes.isNotEmpty ? state.routes.first : null));

    final remoteDataSource = CarpoolMockDataSource();
    final repository = CarpoolRepositoryImpl(remoteDataSource);
    final offerBloc = CarpoolOfferRideBloc(
      publishRide: CarpoolPublishRideUseCase(repository),
    );

    offerBloc.add(
      CarpoolOfferFromChanged(origin.name, lat: origin.lat, lng: origin.lng),
    );
    offerBloc.add(
      CarpoolOfferToChanged(
        destination.name,
        lat: destination.lat,
        lng: destination.lng,
      ),
    );

    // Pass the single user-selected radio route details to CarpoolStopoversPage
    if (selectedRoute != null) {
      // Save toll object (distance/Km, duration, toll type) in temporary storage
      CarpoolTemporaryRideData.instance.saveTollRoute(
        type: selectedRoute.hasTolls ? 'toll' : 'no_toll',
        duration: selectedRoute.durationText,
        distance: selectedRoute.distanceKm.toDouble(),
        hasTolls: selectedRoute.hasTolls,
        routeOption: selectedRoute,
      );

      offerBloc.add(
        CarpoolOfferRoutesInitialized(
          routes: [selectedRoute],
          selectedRoute: selectedRoute,
        ),
      );

      offerBloc.add(
        CarpoolOfferCalculatePricing(
          originLat: origin.lat,
          originLng: origin.lng,
          destinationLat: destination.lat,
          destinationLng: destination.lng,
          selectedDistanceKm: selectedRoute.distanceKm.toDouble(),
          selectedDurationText: selectedRoute.durationText,
        ),
      );
    }

    CarpoolStopoversPage.show(context, offerBloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhereIsTheRouteBloc, WhereIsTheRouteState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.status == WhereIsTheRouteStatus.success,
      listener: (context, state) {
        if (state.status == WhereIsTheRouteStatus.success &&
            state.routes.isNotEmpty) {
          // Immediately save the active selected route into session cache
          final activeRoute = (state.selectedIndex >= 0 &&
                  state.selectedIndex < state.routes.length)
              ? state.routes[state.selectedIndex]
              : state.routes.first;
          CarpoolTemporaryRideData.instance.saveTollRoute(
            type: activeRoute.hasTolls ? 'toll' : 'no_toll',
            duration: activeRoute.durationText,
            distance: activeRoute.distanceKm.toDouble(),
            hasTolls: activeRoute.hasTolls,
            routeOption: activeRoute,
          );

          if (!_hasFittedCamera) {
            _hasFittedCamera = true;
            final allPoints = <RouteCoordinate>[];
            for (final r in state.routes) {
              allPoints.addAll(r.waypoints);
            }
            if (state.origin != null) {
              allPoints.add(
                RouteCoordinate(state.origin!.lat, state.origin!.lng),
              );
            }
            if (state.destination != null) {
              allPoints.add(
                RouteCoordinate(state.destination!.lat, state.destination!.lng),
              );
            }
            _fitCameraToBounds(allPoints);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // 1. Top Section: 6/10 (60%) screen height for Map
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    _buildGoogleMap(context, state),

                    // Top-Left Overlay Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 14,
                      child: SafeArea(
                        top: false,
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: Color(0xFF0066FF),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Bottom Section: 4/10 (40%) screen height for Route Options Sheet (where is your route, tolls, no tolls)
              Expanded(
                flex: 4,
                child: _buildRouteOptionsContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIVE REAL GOOGLE MAP WITH BLUE HIGHWAY POLYLINE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGoogleMap(BuildContext context, WhereIsTheRouteState state) {
    final origin = state.origin;
    final destination = state.destination;

    // Centered midpoint calculation for initial camera position
    final LatLng center = (origin != null && destination != null)
        ? LatLng(
            (origin.lat + destination.lat) / 2,
            (origin.lng + destination.lng) / 2,
          )
        : (origin != null
              ? LatLng(origin.lat, origin.lng)
              : const LatLng(17.3850, 78.4867));

    double initialZoom = 11.5;
    if (origin != null && destination != null) {
      final distKm = CarpoolDistanceCalculator.calculateDistanceKm(
        origin.name,
        destination.name,
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: destination.lat,
        toLng: destination.lng,
      );
      if (distKm > 200) {
        initialZoom = 7.0;
      } else if (distKm > 80) {
        initialZoom = 8.5;
      } else if (distKm > 30) {
        initialZoom = 10.0;
      } else if (distKm > 10) {
        initialZoom = 11.5;
      } else {
        initialZoom = 13.0;
      }
    }

    return RealGoogleMapPicker(
      key: _mapKey,
      centerLat: _userCenterLat ?? center.latitude,
      centerLng: _userCenterLng ?? center.longitude,
      zoom: _userZoom ?? initialZoom,
      pickupPlace: origin,
      dropoffPlace: destination,
      routes: state.routes,
      selectedRouteIndex: state.selectedIndex,
      onRouteSelected: (idx) {
        context.read<WhereIsTheRouteBloc>().add(
          WhereIsTheRouteOptionSelected(idx),
        );
        if (idx >= 0 && idx < state.routes.length) {
          final r = state.routes[idx];
          CarpoolTemporaryRideData.instance.saveTollRoute(
            type: r.hasTolls ? 'toll' : 'no_toll',
            duration: r.durationText,
            distance: r.distanceKm.toDouble(),
            hasTolls: r.hasTolls,
            routeOption: r,
          );
        }
      },
      onCameraMove: (lat, lng) {
        _userCenterLat = lat;
        _userCenterLng = lng;
      },
      onCameraIdle: (lat, lng) {
        _userCenterLat = lat;
        _userCenterLng = lng;
        final zoom = _mapKey.currentState?.currentZoomLevel;
        if (zoom != null) {
          _userZoom = zoom.toDouble();
        }
      },
      showCenterPin: false,
      showControls: false,
      showGoogleWatermark: false,
      showRouteDurationBadges: false,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCROLLABLE ROUTE OPTIONS CONTENT (4/10 Screen Height Scrolling Data)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRouteOptionsContent(
    BuildContext context,
    WhereIsTheRouteState state,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Stack(
        children: [
          // Scrollable route details (Scrolling data; map above remains fixed at 6/10)
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              16,
              22,
              MediaQuery.of(context).padding.bottom + 76, // Room for floating next button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Duration Displayed ABOVE "What is your route?" Header
                if (state.selectedRoute != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFF0066FF),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                state.selectedRoute!.durationText,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0066FF),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•  ${state.selectedRoute!.distanceKm} km',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: state.selectedRoute!.hasTolls
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  state.selectedRoute!.hasTolls ? 'Tolls' : 'No tolls',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w700,
                                    color: state.selectedRoute!.hasTolls
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bold Header: "What is your route?"
                const Text(
                  'What is your route?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Route Options List or Loading Indicator
                if (state.status == WhereIsTheRouteStatus.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(color: Color(0xFF0066FF)),
                    ),
                  )
                else
                  ...List.generate(state.routes.length, (index) {
                    final route = state.routes[index];
                    final isSelected = index == state.selectedIndex;

                    return InkWell(
                      onTap: () {
                        context.read<WhereIsTheRouteBloc>().add(
                          WhereIsTheRouteOptionSelected(index),
                        );
                        CarpoolTemporaryRideData.instance.saveTollRoute(
                          type: route.hasTolls ? 'toll' : 'no_toll',
                          duration: route.durationText,
                          distance: route.distanceKm.toDouble(),
                          hasTolls: route.hasTolls,
                          routeOption: route,
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Custom Radio Indicator (Matches Screenshot exactly)
                            _buildRadioIndicator(isSelected),

                            const SizedBox(width: 16),

                            // Route Details (Duration - Tolls / Distance - Highway / Corridor Cities Path)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.title,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    route.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Pinned Floating Next Button at Bottom Right (Matches Screenshot)
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: InkWell(
              onTap: () => _onNextPressed(context),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withOpacity(0.38),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOM RADIO BUTTON MATCHING SCREENSHOT EXACTLY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRadioIndicator(bool isSelected) {
    if (isSelected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0066FF), width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0066FF),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0066FF), width: 2.2),
      ),
    );
  }
}
