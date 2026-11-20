import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_place_entity.dart';

import '../../data/datasources/carpool_places_remote_data_source.dart';
import '../../data/datasources/carpool_routes_remote_data_source.dart';
import '../../data/repositories/carpool_places_repository_impl.dart';
import '../../domain/usecases/get_place_from_coords_usecase.dart';
import '../../domain/usecases/search_carpool_places_usecase.dart';
import '../bloc/carpool_location_picker_bloc.dart';
import '../widgets/carpool_blabla_route_search_card.dart';
import '../widgets/carpool_location_bottom_card.dart';
import '../widgets/real_google_map_picker.dart';
import 'carpool_publish_ride_page.dart';
import 'where_is_the_route_page.dart';

/// BlaBlaCar-style location search and map picker page supporting both Pick-up and Drop-off locations.
///
/// Features:
/// 1. Top AppBar with back navigation, screen title, and "Pick on Map" quick-action button.
/// 2. Top search card with connected Pick-up and Drop-off fields and instant location swap.
/// 3. Google Map interactive canvas showing:
///    - Violet Pick-up marker
///    - Red Drop-off marker
///    - Vibrant royal purple driving route polyline connecting origin and destination
/// 4. Clicking the pinned location immediately opens the Drop-off step within the same screen.
/// 5. Complete route summary and one-tap navigation to [CarpoolPublishRidePage].
class CarpoolBlaBlaLocationPickerPage extends StatelessWidget {
  final String? initialQuery;
  final CarpoolLocationStep initialStep;
  final CarpoolPlaceEntity? initialPickup;
  final CarpoolPlaceEntity? initialDropoff;

  const CarpoolBlaBlaLocationPickerPage({
    super.key,
    this.initialQuery,
    this.initialStep = CarpoolLocationStep.pickup,
    this.initialPickup,
    this.initialDropoff,
  });

  /// Navigates to [CarpoolBlaBlaLocationPickerPage] safely.
  static Future<void> show(
    BuildContext context, {
    String? initialQuery,
    CarpoolLocationStep initialStep = CarpoolLocationStep.pickup,
    CarpoolPlaceEntity? initialPickup,
    CarpoolPlaceEntity? initialDropoff,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CarpoolBlaBlaLocationPickerPage(
          initialQuery: initialQuery,
          initialStep: initialStep,
          initialPickup: initialPickup,
          initialDropoff: initialDropoff,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = CarpoolPlacesRemoteDataSourceImpl();
    final repository = CarpoolPlacesRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final searchPlacesUseCase = SearchCarpoolPlacesUseCase(repository);
    final getPlaceFromCoordsUseCase = GetPlaceFromCoordsUseCase(repository);
    final routesDataSource = CarpoolRoutesRemoteDataSourceImpl();

    return BlocProvider<CarpoolLocationPickerBloc>(
      create: (_) {
        final bloc = CarpoolLocationPickerBloc(
          searchPlacesUseCase: searchPlacesUseCase,
          getPlaceFromCoordsUseCase: getPlaceFromCoordsUseCase,
          routesDataSource: routesDataSource,
        );
        bloc.add(
          CarpoolLocationPickerStarted(
            initialStep: initialStep,
            initialPickup: initialPickup,
            initialDropoff: initialDropoff,
          ),
        );
        if (initialQuery != null && initialQuery!.trim().isNotEmpty) {
          bloc.add(
            CarpoolLocationPickerQueryChanged(
              initialQuery!.trim(),
              step: initialStep,
            ),
          );
        }
        return bloc;
      },
      child: _BlaBlaLocationPickerView(
        initialStep: initialStep,
        initialPickup: initialPickup,
      ),
    );
  }
}

class _BlaBlaLocationPickerView extends StatefulWidget {
  final CarpoolLocationStep initialStep;
  final CarpoolPlaceEntity? initialPickup;

  const _BlaBlaLocationPickerView({
    this.initialStep = CarpoolLocationStep.pickup,
    this.initialPickup,
  });

  @override
  State<_BlaBlaLocationPickerView> createState() =>
      _BlaBlaLocationPickerViewState();
}

class _BlaBlaLocationPickerViewState extends State<_BlaBlaLocationPickerView> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();

  final GlobalKey<RealGoogleMapPickerState> _mapKey =
      GlobalKey<RealGoogleMapPickerState>();
  GoogleMapController? _mapController;
  Timer? _debounceTimer;
  LatLng? _currentCenter;

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        context.read<CarpoolLocationPickerBloc>().add(
          const CarpoolLocationPickerStepChanged(CarpoolLocationStep.pickup),
        );
      }
      setState(() {});
    });
    _dropoffFocusNode.addListener(() {
      if (_dropoffFocusNode.hasFocus) {
        context.read<CarpoolLocationPickerBloc>().add(
          const CarpoolLocationPickerStepChanged(CarpoolLocationStep.dropoff),
        );
      }
      setState(() {});
    });
  }

  bool get _isSearching {
    return (_pickupFocusNode.hasFocus &&
            _pickupController.text.trim().isNotEmpty) ||
        (_dropoffFocusNode.hasFocus &&
            _dropoffController.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _mapController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPickupChanged(String value) {
    context.read<CarpoolLocationPickerBloc>().add(
      const CarpoolLocationPickerStepChanged(CarpoolLocationStep.pickup),
    );
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<CarpoolLocationPickerBloc>().add(
          CarpoolLocationPickerQueryChanged(
            value,
            step: CarpoolLocationStep.pickup,
          ),
        );
      }
    });
  }

  void _onDropoffChanged(String value) {
    context.read<CarpoolLocationPickerBloc>().add(
      const CarpoolLocationPickerStepChanged(CarpoolLocationStep.dropoff),
    );
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<CarpoolLocationPickerBloc>().add(
          CarpoolLocationPickerQueryChanged(
            value,
            step: CarpoolLocationStep.dropoff,
          ),
        );
      }
    });
  }

  void _animateMapCamera(double lat, double lng, double zoom) {
    _mapKey.currentState?.animateCamera(lat, lng, zoom);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom),
      ),
    );
  }

  void _fitRouteBounds(LatLng pickup, LatLng dropoff) {
    _mapKey.currentState?.fitBounds([
      (lat: pickup.latitude, lng: pickup.longitude),
      (lat: dropoff.latitude, lng: dropoff.longitude),
    ]);
    if ((pickup.latitude - dropoff.latitude).abs() < 0.001 &&
        (pickup.longitude - dropoff.longitude).abs() < 0.001) {
      _animateMapCamera(pickup.latitude, pickup.longitude, 14.5);
      return;
    }

    final southwest = LatLng(
      pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude < dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );
    final northeast = LatLng(
      pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude > dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 65.0));
  }

  void _navigateToWhereIsTheRoute(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    if (state.pickupPlace == null || state.dropoffPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pick-up and drop-off points'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    WhereIsTheRoutePage.show(
      context,
      origin: state.pickupPlace!,
      destination: state.dropoffPlace!,
    );
  }

  void _onConfirmPickupPressed(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    final currentPickup =
        state.pickupPlace ??
        CarpoolPlaceEntity(
          id: 'pickup_${state.mapCenterLat}_${state.mapCenterLng}',
          name: state.pickupQuery.isNotEmpty
              ? state.pickupQuery
              : 'Pick-up Point',
          formattedAddress:
              'Coordinates: ${state.mapCenterLat.toStringAsFixed(4)}, ${state.mapCenterLng.toStringAsFixed(4)}',
          type: CarpoolPlaceType.locality,
          lat: state.mapCenterLat,
          lng: state.mapCenterLng,
        );

    CarpoolBlaBlaLocationPickerPage.show(
      context,
      initialStep: CarpoolLocationStep.dropoff,
      initialPickup: currentPickup,
    );
  }

  void _onConfirmDropoffPressed(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    final origin = widget.initialPickup ?? state.pickupPlace;
    final destination =
        state.dropoffPlace ??
        CarpoolPlaceEntity(
          id: 'dropoff_${state.mapCenterLat}_${state.mapCenterLng}',
          name: state.dropoffQuery.isNotEmpty
              ? state.dropoffQuery
              : 'Drop-off Point',
          formattedAddress:
              'Coordinates: ${state.mapCenterLat.toStringAsFixed(4)}, ${state.mapCenterLng.toStringAsFixed(4)}',
          type: CarpoolPlaceType.locality,
          lat: state.mapCenterLat,
          lng: state.mapCenterLng,
        );

    if (origin != null) {
      WhereIsTheRoutePage.show(
        context,
        origin: origin,
        destination: destination,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarpoolLocationPickerBloc, CarpoolLocationPickerState>(
      listenWhen: (prev, curr) =>
          prev.cameraUpdateToken != curr.cameraUpdateToken ||
          prev.step != curr.step ||
          prev.hasBothLocations != curr.hasBothLocations ||
          prev.pickupPlace != curr.pickupPlace ||
          prev.dropoffPlace != curr.dropoffPlace,
      listener: (context, state) {
        // Sync text controllers when not user-focused
        if (state.pickupPlace != null &&
            !_pickupFocusNode.hasFocus &&
            _pickupController.text != state.pickupPlace!.name) {
          _pickupController.text = state.pickupPlace!.name;
        }
        if (state.dropoffPlace != null &&
            !_dropoffFocusNode.hasFocus &&
            _dropoffController.text != state.dropoffPlace!.name) {
          _dropoffController.text = state.dropoffPlace!.name;
        }

        // Camera animation to current target
        _animateMapCamera(
          state.mapCenterLat,
          state.mapCenterLng,
          state.zoomLevel,
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, state),
          body: Column(
            children: [
              // 1. BlaBlaCar-Style Route Search Card (Single Step Pick-up / Drop-off)
              CarpoolBlaBlaRouteSearchCard(
                pickupController: _pickupController,
                dropoffController: _dropoffController,
                pickupFocusNode: _pickupFocusNode,
                dropoffFocusNode: _dropoffFocusNode,
                onPickupChanged: _onPickupChanged,
                onDropoffChanged: _onDropoffChanged,
                isSingleStepMode: true,
                confirmedPickupName: widget.initialPickup?.name,
                onClearPickup: () {
                  _pickupController.clear();
                  context.read<CarpoolLocationPickerBloc>().add(
                    const CarpoolLocationPickerQueryChanged(
                      '',
                      step: CarpoolLocationStep.pickup,
                    ),
                  );
                },
                onClearDropoff: () {
                  _dropoffController.clear();
                  context.read<CarpoolLocationPickerBloc>().add(
                    const CarpoolLocationPickerQueryChanged(
                      '',
                      step: CarpoolLocationStep.dropoff,
                    ),
                  );
                },
              ),

              // 2. Fullscreen Interactive Map & Dynamic Bottom Card
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fullscreen Google Map (Fills entire space)
                    _buildGoogleMapWidget(context, state),

                    // BlaBlaCar-Style Central Pin Overlay (Always active so user can set exact location)
                    _buildCenterFloatingPin(state),

                    // Top Instruction Hint Pill
                    Positioned(
                      top: 10,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 15,
                              color: state.step == CarpoolLocationStep.pickup
                                  ? const Color(0xFF5D24F7)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.step == CarpoolLocationStep.pickup
                                    ? 'Tap map or search to set Pick-up point'
                                    : 'Tap map or search to set Drop-off point',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Recenter to Current Location Button
                    Positioned(
                      right: 16,
                      bottom: 145,
                      child: FloatingActionButton.small(
                        heroTag: 'recenter_gps_route_btn',
                        backgroundColor: Colors.white,
                        elevation: 3,
                        onPressed: () {
                          _animateMapCamera(
                            state.mapCenterLat,
                            state.mapCenterLng,
                            14.5,
                          );
                        },
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF5D24F7),
                          size: 20,
                        ),
                      ),
                    ),

                    // Bottom Dynamic Location & Route Navigation Card
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CarpoolLocationBottomCard(
                        onProceedToPublishRide: () =>
                            _navigateToWhereIsTheRoute(context, state),
                        onConfirmPickup: () =>
                            _onConfirmPickupPressed(context, state),
                        onConfirmDropoff: () =>
                            _onConfirmDropoffPressed(context, state),
                      ),
                    ),

                    // Live OpenStreetMap / Photon Suggestions Overlay when actively searching
                    if (_isSearching && state.places.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 14,
                        right: 14,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 270),
                          child: _buildPhotonSuggestionsCard(context, state),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotonSuggestionsCard(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  size: 16,
                  color: Color(0xFF5D24F7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Places for "${state.query}"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: state.places.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFFF8FAFC),
                indent: 52,
              ),
              itemBuilder: (context, index) {
                final place = state.places[index];
                return InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    final targetStep = _dropoffFocusNode.hasFocus
                        ? CarpoolLocationStep.dropoff
                        : (_pickupFocusNode.hasFocus
                              ? CarpoolLocationStep.pickup
                              : state.step);
                    context.read<CarpoolLocationPickerBloc>().add(
                      CarpoolLocationPickerPlaceSelected(
                        place,
                        step: targetStep,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9FE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF5D24F7),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      place.name,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      place.type.displayName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5D24F7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.formattedAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP BAR WITH "PICK ON MAP" ACTION
  // ══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1E293B),
          size: 20,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        state.step == CarpoolLocationStep.pickup
            ? 'Pick-up point'
            : 'Drop-off point',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () {
              _animateMapCamera(state.mapCenterLat, state.mapCenterLng, 15.0);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 16, color: Color(0xFF5D24F7)),
                  SizedBox(width: 5),
                  Text(
                    'Pick on Map',
                    style: TextStyle(
                      color: Color(0xFF5D24F7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE MAP WIDGET WITH MARKERS AND ROUTE POLYLINE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGoogleMapWidget(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    return RealGoogleMapPicker(
      key: _mapKey,
      centerLat: state.mapCenterLat,
      centerLng: state.mapCenterLng,
      zoom: state.zoomLevel,
      pickupPlace: null,
      dropoffPlace: null,
      routeWaypoints: const [],
      showCenterPin: false,
      showControls: true,
      showGoogleWatermark: false,
      onCameraMove: (lat, lng) {
        _currentCenter = LatLng(lat, lng);
      },
      onCameraIdle: (lat, lng) {
        context.read<CarpoolLocationPickerBloc>().add(
          CarpoolLocationPickerCameraMoved(lat: lat, lng: lng),
        );
      },
      onTap: (lat, lng) {
        context.read<CarpoolLocationPickerBloc>().add(
          CarpoolLocationPickerMapTapped(lat: lat, lng: lng),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLABLACAR-STYLE CENTER FLOATING PIN OVERLAY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCenterFloatingPin(CarpoolLocationPickerState state) {
    final bool isPickup = state.step == CarpoolLocationStep.pickup;
    final Color pinColor = isPickup
        ? const Color(0xFF5D24F7)
        : const Color(0xFFEF4444);
    final String pinLabel = isPickup ? 'Pick-up point' : 'Drop-off point';

    return IgnorePointer(
      child: Center(
        child: Padding(
          // Offset pin upward so the bottom tip aligns with the map center target
          padding: const EdgeInsets.only(bottom: 38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: pinColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: pinColor.withOpacity(0.38),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPickup
                          ? Icons.trip_origin_rounded
                          : Icons.location_on_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pinLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // 2. High-Visibility Location Pin Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pinColor.withOpacity(0.18),
                    ),
                  ),
                  Icon(Icons.location_pin, size: 42, color: pinColor),
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Ground Shadow Indicator Dot
              Container(
                width: 10,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(10, 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
