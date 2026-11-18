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
        builder: (_) => WhereIsTheRoutePage(
          origin: origin,
          destination: destination,
        ),
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
      create: (_) => WhereIsTheRouteBloc(getRouteOptionsUseCase: useCase)
        ..add(
          WhereIsTheRouteStarted(origin: origin, destination: destination),
        ),
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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    } catch (_) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(centerLat, centerLng),
            zoom: 11.5,
          ),
        ),
      );
    }
  }

  void _onNextPressed(
    BuildContext context,
    WhereIsTheRouteState state,
  ) {
    if (state.origin == null || state.destination == null) return;

    final origin = state.origin!;
    final destination = state.destination!;
    final selectedRoute = state.selectedRoute;

    final remoteDataSource = CarpoolMockDataSource();
    final repository = CarpoolRepositoryImpl(remoteDataSource);
    final offerBloc = CarpoolOfferRideBloc(
      publishRide: CarpoolPublishRideUseCase(repository),
    );

    offerBloc.add(
      CarpoolOfferFromChanged(
        origin.name,
        lat: origin.lat,
        lng: origin.lng,
      ),
    );
    offerBloc.add(
      CarpoolOfferToChanged(
        destination.name,
        lat: destination.lat,
        lng: destination.lng,
      ),
    );

    if (selectedRoute != null) {
      offerBloc.add(
        CarpoolOfferCalculatePricing(
          originLat: origin.lat,
          originLng: origin.lng,
          destinationLat: destination.lat,
          destinationLng: destination.lng,
        ),
      );
    }

    CarpoolStopoversPage.show(context, offerBloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhereIsTheRouteBloc, WhereIsTheRouteState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.selectedIndex != curr.selectedIndex,
      listener: (context, state) {
        if (state.status == WhereIsTheRouteStatus.success &&
            state.selectedRoute != null) {
          _fitCameraToBounds(state.selectedRoute!.waypoints);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // 1. Top Section: Google Map covering available screen area with Overlay Back Button
              Expanded(
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

              // 2. Bottom Sheet: "What is your route?" with Options and Next Button
              _buildRouteOptionsSheet(context, state),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIVE REAL GOOGLE MAP WITH BLUE HIGHWAY POLYLINE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGoogleMap(
    BuildContext context,
    WhereIsTheRouteState state,
  ) {
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
      centerLat: center.latitude,
      centerLng: center.longitude,
      zoom: initialZoom,
      pickupPlace: origin,
      dropoffPlace: destination,
      routes: state.routes,
      selectedRouteIndex: state.selectedIndex,
      onRouteSelected: (idx) {
        context.read<WhereIsTheRouteBloc>().add(
              WhereIsTheRouteOptionSelected(idx),
            );
      },
      showCenterPin: false,
      showControls: false,
      showGoogleWatermark: true,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET: "What is your route?" (1:1 Match with Screenshot)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRouteOptionsSheet(
    BuildContext context,
    WhereIsTheRouteState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Large Bold Header: "What is your route?"
            const Text(
              'What is your route?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 22),

            // Route Options List
            if (state.status == WhereIsTheRouteStatus.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: Color(0xFF0066FF),
                  ),
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
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Custom Radio Indicator (Matches Screenshot exactly)
                        _buildRadioIndicator(isSelected),

                        const SizedBox(width: 18),

                        // Route Details (Duration - Tolls / Distance - Highway)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.title,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                route.subtitle,
                                style: const TextStyle(
                                  fontSize: 14.5,
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

            const SizedBox(height: 16),

            // Bottom Right Next Move Button (→)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _onNextPressed(context, state),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withOpacity(0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          border: Border.all(
            color: const Color(0xFF0066FF),
            width: 2.5,
          ),
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
        border: Border.all(
          color: const Color(0xFF0066FF),
          width: 2.2,
        ),
      ),
    );
  }
}
