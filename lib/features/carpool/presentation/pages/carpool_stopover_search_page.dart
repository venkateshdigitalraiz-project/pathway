import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/carpool_distance_calculator.dart';
import '../../data/datasources/places_remote_data_source.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/entities/carpool_stopover_entity.dart';
import '../../domain/entities/carpool_temporary_ride_data.dart';
import '../../domain/entities/place_prediction_entity.dart';
import '../../domain/usecases/get_place_predictions_usecase.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../widgets/real_google_map_picker.dart';

/// Full-screen City Search and Google Map Validation Page for Carpool Stopovers.
///
/// Features:
/// 1. Top city search text field with live Google Places Autocomplete.
/// 2. Google Maps canvas below search field (default: blank map without route markers or polylines).
/// 3. Automatically moves camera and drops marker upon selecting a city from autocomplete.
/// 4. Validates selected city against currently active driving route using 10 KM distance threshold.
/// 5. Valid (<= 10 KM): Green visual feedback and allows adding as stopover.
/// 6. Invalid (> 10 KM): Red visual feedback, rejects adding, and shows exact error message:
///    "This city is more than 10 KM away from your selected route. Please select another city."
/// 7. Preserves all BLoC state, routes, toll preferences, and stopovers.
class CarpoolStopoverSearchPage extends StatelessWidget {
  final CarpoolOfferRideBloc bloc;

  const CarpoolStopoverSearchPage({super.key, required this.bloc});

  static Future<void> show(BuildContext context, CarpoolOfferRideBloc bloc) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CarpoolStopoverSearchPage(bloc: bloc),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: const _StopoverSearchMapView(),
    );
  }
}

class _StopoverSearchMapView extends StatefulWidget {
  const _StopoverSearchMapView();

  @override
  State<_StopoverSearchMapView> createState() => _StopoverSearchMapViewState();
}

class _StopoverSearchMapViewState extends State<_StopoverSearchMapView> {
  final GlobalKey<RealGoogleMapPickerState> _mapKey =
      GlobalKey<RealGoogleMapPickerState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final GetPlacePredictionsUseCase _getPlacePredictions;
  Timer? _debounceTimer;
  List<PlacePredictionEntity> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isLoadingCoordinates = false;
  bool _showSuggestionsDropdown = false;

  CarpoolPlaceEntity? _selectedPlace;
  String? _selectedSubtitle;
  bool? _isCityValid;
  double _distanceToRouteKm = 0.0;

  @override
  void initState() {
    super.initState();
    final remoteDataSource = GooglePlacesRemoteDataSourceImpl(
      apiKey: ApiEndpoints.googleMapsApiKey,
    );
    final repository = PlacesRepositoryImpl(remoteDataSource);
    _getPlacePredictions = GetPlacePredictionsUseCase(repository);

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showSuggestionsDropdown = _searchFocusNode.hasFocus &&
              _searchController.text.trim().isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
        _showSuggestionsDropdown = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestionsDropdown = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 280), () async {
      try {
        final results = await _getPlacePredictions(clean);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoadingSuggestions = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _suggestions = [];
      _isLoadingSuggestions = false;
      _isLoadingCoordinates = false;
      _showSuggestionsDropdown = false;
      _selectedPlace = null;
      _isCityValid = null;
      _distanceToRouteKm = 0.0;
    });
    _searchFocusNode.requestFocus();
  }

  /// Handles user tapping a city suggestion from Google Places Autocomplete
  Future<void> _onSelectPrediction(PlacePredictionEntity prediction) async {
    _searchFocusNode.unfocus();
    final cityName = prediction.mainText.isNotEmpty
        ? prediction.mainText
        : prediction.description.split(',').first.trim();

    _searchController.text = cityName;

    setState(() {
      _showSuggestionsDropdown = false;
      _isLoadingCoordinates = true;
    });

    double? lat = prediction.lat;
    double? lng = prediction.lng;

    final bool hasValidCoords = lat != null &&
        lng != null &&
        lat >= 6.5 &&
        lat <= 38.0 &&
        lng >= 68.0 &&
        lng <= 98.0;

    if (!hasValidCoords) {
      final cached = CarpoolDistanceCalculator.findGeo(cityName) ??
          CarpoolDistanceCalculator.findGeo(prediction.description);
      if (cached != null && cached.lat >= 6.5 && cached.lat <= 38.0) {
        lat = cached.lat;
        lng = cached.lng;
      } else {
        final resolved = CarpoolDistanceCalculator.resolveCoordinates(cityName);
        if (resolved.lat >= 6.5 && resolved.lat <= 38.0) {
          lat = resolved.lat;
          lng = resolved.lng;
        }
      }

      if (lat == null || lng == null || lat < 6.5 || lat > 38.0) {
        final fetched = await CarpoolDistanceCalculator.fetchGeocodeCoordinates(
          prediction.placeId.isNotEmpty
              ? prediction.placeId
              : prediction.description,
          isPlaceId: prediction.placeId.isNotEmpty,
        ) ?? await CarpoolDistanceCalculator.fetchGeocodeCoordinates(
          prediction.description,
          isPlaceId: false,
        ) ?? await CarpoolDistanceCalculator.fetchGeocodeCoordinates(
          cityName,
          isPlaceId: false,
        );

        if (fetched != null && fetched.lat >= 6.5 && fetched.lat <= 38.0) {
          lat = fetched.lat;
          lng = fetched.lng;
        }
      }
    }

    final state = context.read<CarpoolOfferRideBloc>().state;
    final double validLat = (lat != null && lat >= 6.5 && lat <= 38.0)
        ? lat
        : (state.fromLat != 0.0 ? state.fromLat : 17.3850);
    final double validLng = (lng != null && lng >= 68.0 && lng <= 98.0)
        ? lng
        : (state.fromLng != 0.0 ? state.fromLng : 78.4867);

    CarpoolDistanceCalculator.registerGeo(cityName, validLat, validLng);

    final place = CarpoolPlaceEntity(
      id: prediction.placeId,
      name: cityName,
      formattedAddress: prediction.description,
      type: CarpoolPlaceType.city,
      lat: validLat,
      lng: validLng,
    );

    // Animate map camera to the selected city location
    _mapKey.currentState?.animateCamera(validLat, validLng, 13.5);

    // Validate selected city against currently selected driving route using 10 KM validation
    List<({double lat, double lng})>? routePolyline;
    if (state.selectedRouteOption != null &&
        state.selectedRouteOption!.waypoints.isNotEmpty) {
      routePolyline = state.selectedRouteOption!.waypoints
          .map((w) => (lat: w.lat, lng: w.lng))
          .toList();
    }

    final adj = CarpoolDistanceCalculator.validateLocationOnRoute(
      start: state.from,
      destination: state.to,
      candidateName: cityName,
      candidateLat: validLat,
      candidateLng: validLng,
      startLat: state.fromLat,
      startLng: state.fromLng,
      destLat: state.toLat,
      destLng: state.toLng,
      currentStopovers: state.selectedStopovers.toList(),
      routePolyline: routePolyline,
      corridorText: state.selectedRouteOption?.corridorText,
      routeName: state.selectedRouteOption?.highwayName ??
          state.selectedRouteOption?.title,
      maxDistanceToRouteKm: 10.0,
    );

    final bool isValid = adj.isOnRoute;
    final double distKm = adj.distanceToRouteKm;

    if (!mounted) return;

    setState(() {
      _isLoadingCoordinates = false;
      _selectedPlace = place;
      _selectedSubtitle = prediction.secondaryText.isNotEmpty
          ? prediction.secondaryText
          : prediction.description;
      _isCityValid = isValid;
      _distanceToRouteKm = distKm;
      _showSuggestionsDropdown = false;
    });

    // If city is more than 10 KM away, display error message
    if (!isValid) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This city is more than 10 KM away from your selected route. Please select another city.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Adds the validated stopover and returns to previous screen
  void _onAddStopover() {
    if (_selectedPlace == null || _isCityValid != true) return;

    final cityName = _selectedPlace!.name;
    final bloc = context.read<CarpoolOfferRideBloc>();

    final stopoverObj = CarpoolStopoverEntity(
      latitude: _selectedPlace!.lat,
      longitude: _selectedPlace!.lng,
      address: _selectedPlace!.formattedAddress.isNotEmpty
          ? _selectedPlace!.formattedAddress
          : (_selectedSubtitle ?? _selectedPlace!.name),
      state: _selectedPlace!.state.isNotEmpty ? _selectedPlace!.state : 'India',
      city: _selectedPlace!.name,
    );

    // Save stopover halt to temporary session storage
    CarpoolTemporaryRideData.instance.addStopoverHalt(stopoverObj);

    bloc.add(CarpoolOfferStopoverAdded(cityName, stopoverObject: stopoverObj));
    CarpoolDistanceCalculator.registerGeo(
      cityName,
      _selectedPlace!.lat,
      _selectedPlace!.lng,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$cityName added to your stopovers',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF4C2BF0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<CarpoolOfferRideBloc, CarpoolOfferRideState>(
          builder: (context, state) {
            final double initialCenterLat = state.fromLat != 0.0
                ? state.fromLat
                : (state.toLat != 0.0 ? state.toLat : 17.3850);
            final double initialCenterLng = state.fromLng != 0.0
                ? state.fromLng
                : (state.toLng != 0.0 ? state.toLng : 78.4867);

            return Stack(
              children: [
                // ══════════════════════════════════════════════════════════════
                // 1. MAIN COLUMN: TOP SEARCH BAR + BLANK GOOGLE MAP
                // ══════════════════════════════════════════════════════════════
                Column(
                  children: [
                    // Top App Bar with Back Button & Search Input
                    _buildTopSearchBar(context),

                    // Google Map Canvas (Blank by default: no route markers or polylines)
                    Expanded(
                      child: Stack(
                        children: [
                          RealGoogleMapPicker(
                            key: _mapKey,
                            centerLat: _selectedPlace?.lat ?? initialCenterLat,
                            centerLng: _selectedPlace?.lng ?? initialCenterLng,
                            zoom: _selectedPlace != null ? 13.5 : 10.5,
                            pickupPlace: null, // No route markers by default
                            dropoffPlace: null,
                            routeWaypoints: const [], // Blank map: No route polylines
                            routes: const [],
                            singleMarkerPlace: _selectedPlace,
                            isSingleMarkerValid: _isCityValid,
                            showCenterPin: false,
                            showControls: true,
                            showGoogleWatermark: false,
                          ),

                          // Active Selected Route Context Badge (Top-left on Map)
                          if (state.selectedRouteOption != null)
                            Positioned(
                              top: 10,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
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
                                      state.selectedRouteOption!.hasTolls
                                          ? Icons.toll_rounded
                                          : Icons.money_off_rounded,
                                      size: 14,
                                      color: state.selectedRouteOption!.hasTolls
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF15803D),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Active: ${state.selectedRouteOption!.highwayName}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ══════════════════════════════════════════════════════════════
                // 2. AUTOCOMPLETE SUGGESTIONS DROPDOWN (OVERLAY)
                // ══════════════════════════════════════════════════════════════
                if (_showSuggestionsDropdown)
                  Positioned(
                    top: 66,
                    left: 16,
                    right: 16,
                    child: _buildAutocompleteDropdown(),
                  ),

                // ══════════════════════════════════════════════════════════════
                // 3. BOTTOM VALIDATION FEEDBACK CARD
                // ══════════════════════════════════════════════════════════════
                if (_selectedPlace != null && !_showSuggestionsDropdown)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildValidationFeedbackCard(context, state),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Top Search Bar with back button, search textfield, clear button, and progress spinner
  Widget _buildTopSearchBar(BuildContext context) {
    const primaryPurple = Color(0xFF4C2BF0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1EEFC), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: primaryPurple,
              size: 26,
            ),
            splashRadius: 22,
          ),
          const SizedBox(width: 2),

          // Search Field Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? primaryPurple
                      : const Color(0xFFE2DCF9),
                  width: _searchFocusNode.hasFocus ? 1.6 : 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: _searchFocusNode.hasFocus
                        ? primaryPurple
                        : const Color(0xFF9E98BE),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF140D43),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search city, town, or village...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9E98BE),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _onClearSearch,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF8A84A7),
                        ),
                      ),
                    ),
                  if (_isLoadingSuggestions || _isLoadingCoordinates)
                    const Padding(
                      padding: EdgeInsets.all(6),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Autocomplete dropdown overlay showing real-time Google Places suggestions
  Widget _buildAutocompleteDropdown() {
    const primaryPurple = Color(0xFF4C2BF0);

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F140D43).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2DCF9), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _suggestions.isEmpty && !_isLoadingSuggestions
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No matching places found. Try typing a town or city along your corridor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B658C),
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFF1EEFC),
                  indent: 48,
                ),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final mainName = item.mainText.isNotEmpty
                      ? item.mainText
                      : item.description.split(',').first.trim();

                  return InkWell(
                    onTap: () => _onSelectPrediction(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EEFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: primaryPurple,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mainName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF140D43),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.secondaryText.isNotEmpty) ...[
                                  const SizedBox(height: 1.5),
                                  Text(
                                    item.secondaryText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B658C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 15,
                            color: Color(0xFF9E98BE),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Bottom Visual Feedback Card displaying 10 KM validation status and action button
  Widget _buildValidationFeedbackCard(
    BuildContext context,
    CarpoolOfferRideState state,
  ) {
    final isValid = _isCityValid == true;
    final isInvalid = _isCityValid == false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Indicator Bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // City Title & Validation Badge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPlace?.name ?? 'Selected City',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_selectedSubtitle != null &&
                        _selectedSubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _selectedSubtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Visual Status Badge (Green vs Red)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isValid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 13,
                      color: isValid
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isValid
                          ? 'Within 10 KM'
                          : '${_distanceToRouteKm.toStringAsFixed(1)} KM away',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isValid
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── REJECTION ERROR BANNER (Requirement 7) ──
          if (isInvalid)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This city is more than 10 KM away from your selected route. Please select another city.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── VALIDATION SUCCESS INFO BANNER (Requirement 6) ──
          if (isValid)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid stopover • ${_distanceToRouteKm.toStringAsFixed(1)} km from your driving route',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── ACTION BUTTON: ADD STOPOVER (Active) OR DISABLED ──
          if (isValid)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D24F7), Color(0xFF3815D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4C1CDD).withOpacity(0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _onAddStopover,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_location_alt_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add as Stopover',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Location Not Allowed (>10 KM)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
