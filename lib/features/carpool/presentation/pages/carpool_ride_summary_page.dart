import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/utils/carpool_date_time_validator.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';
import 'package:pathway/features/carpool/presentation/widgets/carpool_route_selector_card.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/entities/carpool_pricing_entity.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../bloc/carpool_offer_ride_bloc.dart';
import '../widgets/real_google_map_preview.dart';
import 'carpool_ride_published_page.dart';

/// Clean Architecture Route Summary & Booking Confirmation Screen.
/// - Top half: Authentic Google Maps route canvas showing from & to distance and pins.
/// - Bottom half: Card with from & to locations, date & time, seat booking,
///   distance-based price breakdown, and Confirm Booking button.
class CarpoolRideSummaryPage extends StatelessWidget {
  final CarpoolOfferRideBloc? bloc;
  final CarpoolPricingEntity? pricing;

  const CarpoolRideSummaryPage({super.key, this.bloc, this.pricing});

  /// Navigates to [CarpoolRideSummaryPage] sharing the given [CarpoolOfferRideBloc].
  static Future<void> show(
    BuildContext context,
    CarpoolOfferRideBloc bloc, {
    CarpoolPricingEntity? pricing,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CarpoolRideSummaryPage(bloc: bloc, pricing: pricing),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _RideSummaryView(pricing: pricing),
      );
    }

    try {
      context.read<CarpoolOfferRideBloc>();
      return _RideSummaryView(pricing: pricing);
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return BlocProvider(
        create: (_) => CarpoolOfferRideBloc(
          publishRide: CarpoolPublishRideUseCase(repository),
        ),
        child: _RideSummaryView(pricing: pricing),
      );
    }
  }
}

class _RideSummaryView extends StatefulWidget {
  final CarpoolPricingEntity? pricing;
  const _RideSummaryView({this.pricing});

  @override
  State<_RideSummaryView> createState() => _RideSummaryViewState();
}

class _RideSummaryViewState extends State<_RideSummaryView> {
  DistanceResult? _liveDistanceResult;
  String? _lastFrom;
  String? _lastTo;
  bool _isMapFullscreen = false;

  void _fetchDistance(
    String from,
    String to, {
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) {
    if (_lastFrom == from && _lastTo == to) return;
    _lastFrom = from;
    _lastTo = to;

    CarpoolDistanceCalculator.fetchLiveDistance(
      from,
      to,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    ).then((res) {
      if (mounted) {
        if (res.distanceKm > 3800) {
          return;
        }
        setState(() {
          _liveDistanceResult = res;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarpoolOfferRideBloc, CarpoolOfferRideState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, s) {
        if (s.status == CarpoolStatus.success && s.publishedRide != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride published successfully'),
              backgroundColor: Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CarpoolRidePublishedPage(ride: s.publishedRide!),
            ),
          );
        } else if (s.status == CarpoolStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.error ?? 'Could not confirm booking'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, s) {
        _fetchDistance(
          s.from,
          s.to,
          fromLat: s.fromLat,
          fromLng: s.fromLng,
          toLat: s.toLat,
          toLng: s.toLng,
        );

        final bloc = context.read<CarpoolOfferRideBloc>();
        final screenHeight = MediaQuery.of(context).size.height;
        final mapHeight = _isMapFullscreen
            ? screenHeight * 0.78
            : screenHeight * 0.44;

        final activeStops = s.stopovers.isNotEmpty
            ? s.stopovers
                  .where((st) => s.selectedStopovers.contains(st))
                  .toList()
            : s.selectedStopovers.toList();
        final orderedStops = CarpoolDistanceCalculator.orderStopoversInCorridor(
          start: s.from,
          destination: s.to,
          stopovers: activeStops,
          startLat: s.fromLat,
          startLng: s.fromLng,
          destLat: s.toLat,
          destLng: s.toLng,
        );

        // Pricing logic using dynamic API calculation when available
        final pricing = s.pricingCalculation ?? widget.pricing;
        final double ratePerKm = pricing?.ratePerKm ?? 3.5;

        // Total distance considers direct origin to destination location (no halt distance added)
        final double distanceKmDouble =
            ((_liveDistanceResult?.distanceKm != null &&
                _liveDistanceResult!.distanceKm > 0 &&
                _liveDistanceResult!.distanceKm <= 3800)
            ? _liveDistanceResult!.distanceKm.toDouble()
            : ((pricing?.distanceKm != null &&
                      pricing!.distanceKm > 0 &&
                      pricing.distanceKm <= 3800)
                  ? pricing.distanceKm
                  : CarpoolDistanceCalculator.calculateDistanceKm(
                      s.from,
                      s.to,
                      fromLat: s.fromLat,
                      fromLng: s.fromLng,
                      toLat: s.toLat,
                      toLng: s.toLng,
                    ).toDouble()));

        final int distanceKm = distanceKmDouble.round();
        final int suggestedPrice =
            pricing?.suggestedPrice ?? (distanceKm * ratePerKm).round();
        final int minAllowedPrice =
            pricing?.minAllowedPrice ?? (suggestedPrice * 0.75).round();
        final int maxAllowedPrice =
            pricing?.maxAllowedPrice ?? (suggestedPrice * 1.30).round();
        final int calculatedPricePerSeat = suggestedPrice;
        final int effectivePricePerSeat =
            s.pricePerSeat ?? calculatedPricePerSeat;
        final int seats = s.seats > 0 ? s.seats : 1;
        final int effectiveTotalPrice = effectivePricePerSeat * seats;
        final int totalPrice = effectiveTotalPrice;
        final int pricePerSeat = effectivePricePerSeat;
        final String durationText =
            _liveDistanceResult?.durationText ??
            pricing?.formattedDuration ??
            CarpoolDistanceCalculator.estimateDuration(distanceKm);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F6FD),
          body: Stack(
            children: [
              // ══════════════════════════════════════════════════════════════
              // TOP HALF: GOOGLE MAP WITH ROUTE, DISTANCE & PINS
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight,
                child: RealGoogleMapPreview(
                  from: s.from,
                  to: s.to,
                  fromLat: s.fromLat,
                  fromLng: s.fromLng,
                  toLat: s.toLat,
                  toLng: s.toLng,
                  stopovers: orderedStops,
                  distanceKm: distanceKm,
                  durationText: durationText,
                  isExpanded: _isMapFullscreen,
                  onToggleExpand: () {
                    setState(() {
                      _isMapFullscreen = !_isMapFullscreen;
                    });
                  },
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // TOP APP BAR OVERLAY ON MAP (Back button & Title)
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 42,
                            height: 42,
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
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF140D43),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 14,
                        //     vertical: 8,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.92),
                        //     borderRadius: BorderRadius.circular(20),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.black.withOpacity(0.08),
                        //         blurRadius: 8,
                        //         offset: const Offset(0, 2),
                        //       ),
                        //     ],
                        //   ),
                        //   child: const Text(
                        //     'Route & Ride Summary',
                        //     style: TextStyle(
                        //       fontSize: 15.5,
                        //       fontWeight: FontWeight.w800,
                        //       color: Color(0xFF140D43),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════════════
              // BOTTOM HALF: RIDE DETAILS, SEAT BOOKING & PRICING CARD
              // ══════════════════════════════════════════════════════════════
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                top: mapHeight - 24,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3BF5).withOpacity(0.10),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Little Drag Handle with interactive flexible toggle
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _isMapFullscreen = !_isMapFullscreen;
                          });
                        },
                        onVerticalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v > 100 && !_isMapFullscreen) {
                            setState(() => _isMapFullscreen = true);
                          } else if (v < -100 && _isMapFullscreen) {
                            setState(() => _isMapFullscreen = false);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4.5,
                                margin: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6CEF8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isMapFullscreen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: const Color(0xFF5B3BF5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isMapFullscreen
                                        ? "Tap to View Ride Details"
                                        : "Swipe down or tap for Flexible Map",
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B3BF5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable Details Body
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          children: [
                            // ── 1. Route Locations Card (with integrated Date & Time) ──
                            _buildRouteCard(
                              s.from,
                              s.to,
                              distanceKm,
                              durationText,
                              stopovers: orderedStops,
                              departure: s.departure,
                              context: context,
                              bloc: bloc,
                            ),

                            const SizedBox(height: 14),

                            // ── Vehicle Information Card ────────────────────
                            _buildVehicleInformationCard(
                              context: context,
                              bloc: bloc,
                              vehicleModel: s.vehicleModel,
                              vehicleNumber: s.vehicleNumber,
                            ),

                            const SizedBox(height: 14),

                            // ── 3. Seats & Pricing Setup Card ───────────────
                            _buildSeatsAndPricingCard(
                              seats: s.seats,
                              pricePerSeat: effectivePricePerSeat,
                              totalPrice: effectiveTotalPrice,
                              distanceKm: distanceKm,
                              ratePerKm: ratePerKm,
                              suggestedPrice: suggestedPrice,
                              minPrice: minAllowedPrice,
                              maxPrice: maxAllowedPrice,
                              bloc: bloc,
                            ),

                            const SizedBox(height: 16),

                            // ── 4. Distance & Price Calculation ────────────
                            _buildPriceCalculationCard(
                              distanceKm: distanceKmDouble,
                              ratePerKm: ratePerKm,
                              totalPrice: totalPrice,
                              pricePerSeat: pricePerSeat,
                              seats: seats,
                              pricing: pricing,
                              durationText: durationText,
                            ),
                            const SizedBox(height: 18),
                            // ── 5. Confirm Booking Button ───────────────────
                            _buildConfirmBookingButton(
                              isLoading: s.status == CarpoolStatus.loading,
                              onPressed: () => _onConfirmBookingPressed(
                                context,
                                bloc,
                                s,
                                pricePerSeat,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Verifies ride information, vehicle details, and auth status before publishing
  Future<void> _onConfirmBookingPressed(
    BuildContext context,
    CarpoolOfferRideBloc bloc,
    CarpoolOfferRideState s,
    int pricePerSeat,
  ) async {
    // 1. Verify Origin and Destination
    if (s.from.trim().isEmpty || s.to.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid pick-up and drop-off locations'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (s.from.trim().toLowerCase() == s.to.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick-up and drop-off locations cannot be the same'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Real-time verification of ride departure date & time
    final dateValidation = CarpoolDateTimeValidator.validate(
      date: s.departure,
      time: TimeOfDay(hour: s.departure.hour, minute: s.departure.minute),
      hasSelectedDate: true,
      hasSelectedTime: true,
    );
    if (!dateValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dateValidation.errorMessage ??
                'Departure date and time must be in the future. Please update them.',
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Verify Available Seats
    if (s.seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please offer at least 1 available seat'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Verify Price per Seat
    if (pricePerSeat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a valid price per seat'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 4. Verify Vehicle Information
    if (s.vehicleModel.trim().isEmpty || s.vehicleNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your vehicle information before confirming',
          ),
          backgroundColor: Color(0xFF3815D8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _showVehicleDialog(context, bloc, s.vehicleModel, s.vehicleNumber);
      return;
    }

    // 5. Verify Authentication Token
    final storage = AuthLocalStorage();
    await storage.init();
    final token = await storage.getAccessTokenAsync();
    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in with your phone to publish a ride'),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Synchronize price per seat into bloc if changed
    if (s.pricePerSeat == null || s.pricePerSeat != pricePerSeat) {
      bloc.add(CarpoolOfferPricePerSeatSet(pricePerSeat));
    }

    // All verifications passed -> Dispatch API publish
    bloc.add(const CarpoolOfferPublishPressed());
  }

  /// Estimates travel duration based on distance
  // String _estimateDuration(int distanceKm) {
  //   final totalMinutes = (distanceKm / 65 * 60).round();
  //   final hours = totalMinutes ~/ 60;
  //   final mins = totalMinutes % 60;
  //   if (hours > 0) {
  //     return '$hours hr ${mins > 0 ? '$mins min' : ''}';
  //   }
  //   return '$mins min';
  // }

  Future<void> _pickDate(
    BuildContext context,
    CarpoolOfferRideBloc bloc,
    DateTime current,
  ) async {
    final now = DateTime.now();
    final firstDate = CarpoolDateTimeValidator.getFirstSelectableDate(now: now);
    final initialDate = CarpoolDateTimeValidator.getInitialDate(
      selectedDate: current,
      hasSelectedDate: true,
      now: now,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: CarpoolDateTimeValidator.getLatestSelectableDate(now: now),
      selectableDayPredicate: (date) =>
          !CarpoolDateTimeValidator.isPastDate(date, now: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      bloc.add(CarpoolOfferDateChanged(picked));

      // Revalidate existing time with newly selected date
      final currentTime = TimeOfDay(hour: current.hour, minute: current.minute);
      if (!CarpoolDateTimeValidator.isTimeSlotValidForDate(
        date: picked,
        time: currentTime,
      )) {
        final adjustedTime =
            CarpoolDateTimeValidator.getNextAvailableTime(picked);
        bloc.add(
          CarpoolOfferTimeChanged(adjustedTime.hour, adjustedTime.minute),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected time has passed for today. Time updated to next available slot.',
            ),
            backgroundColor: Color(0xFF3815D8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    CarpoolOfferRideBloc bloc,
    DateTime current,
  ) async {
    final now = DateTime.now();
    final initialTime = CarpoolDateTimeValidator.getInitialTime(
      selectedDate: current,
      selectedTime: TimeOfDay(hour: current.hour, minute: current.minute),
      hasSelectedTime: true,
      now: now,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3815D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF140D43),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      if (!CarpoolDateTimeValidator.isTimeSlotValidForDate(
        date: current,
        time: picked,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot select past or current time. Please choose a future time.',
            ),
            backgroundColor: Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      bloc.add(CarpoolOfferTimeChanged(picked.hour, picked.minute));
    }
  }

  /// Builds the Route From & To display card with accurate Google Map styling and integrated Date & Time
  Widget _buildRouteCard(
    String from,
    String to,
    int distanceKm,
    String duration, {
    List<String> stopovers = const [],
    required DateTime departure,
    BuildContext? context,
    CarpoolOfferRideBloc? bloc,
  }) {
    final fromGeo = CarpoolDistanceCalculator.findGeo(from);
    final toGeo = CarpoolDistanceCalculator.findGeo(to);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google Maps Route Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF1A73E8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Google Maps Route',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$distanceKm km • $duration',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date of Your Journey Row (Clean text display on top)
          InkWell(
            onTap: (context != null && bloc != null)
                ? () async {
                    await _pickDate(context, bloc, departure);
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3815D8).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF3815D8),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATE OF YOUR JOURNEY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B658C),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              CarpoolFormatters.date(departure),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E88B0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            GestureDetector(
                              onTap: (context != null && bloc != null)
                                  ? () => _pickTime(context, bloc, departure)
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 14.5,
                                    color: Color(0xFF3815D8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    CarpoolFormatters.time(departure),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF140D43),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: (context != null && bloc != null)
                        ? () => _pickDate(context, bloc, departure)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: Color(0xFF9E9AB8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider between Journey Date & Route Locations
          Container(height: 1, color: const Color(0xFFEDE8FF)),

          const SizedBox(height: 12),

          // Pick-up (From) Row with Google Maps Blue Pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56DB).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.circle,
                  color: Color(0xFF1A56DB),
                  size: 11,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICK-UP LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B658C),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    if (fromGeo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        fromGeo.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (stopovers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Container(
                width: 2,
                height: 10,
                color: const Color(0xFF1A73E8),
              ),
            ),
            for (final stop in stopovers) ...[
              Builder(
                builder: (context) {
                  CarpoolDistanceCalculator.resolveCoordinates(stop);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              stop,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF140D43),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Halt',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),

                            const Spacer(),
                            InkWell(
                              onTap: () {
                                context.read<CarpoolOfferRideBloc>().add(
                                  CarpoolOfferStopoverRemoved(stop),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 10,
                  color: const Color(0xFF1A73E8),
                ),
              ),
            ],
          ] else ...[
            // Connecting Highway Line with Route Tag
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const SizedBox(width: 11),
                  Container(
                    width: 2,
                    height: 22,
                    color: const Color(0xFF1A73E8),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Fastest Highway Route',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3815D8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Add Halt / Stopover Action Button
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4, bottom: 6),
            child: Builder(
              builder: (context) {
                return InkWell(
                  onTap: () async {
                    final result = await carpoolSelectLocation(
                      context,
                      title: 'Search Halt / Stopover Location',
                      isPickup: false,
                    );
                    if (result != null && result.name.trim().isNotEmpty) {
                      final stopName = result.name.trim();
                      if (result.lat != null && result.lng != null) {
                        CarpoolDistanceCalculator.registerGeo(
                          stopName,
                          result.lat!,
                          result.lng!,
                        );
                      }
                      if (context.mounted) {
                        context.read<CarpoolOfferRideBloc>().add(
                          CarpoolOfferStopoverAdded(stopName),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 15,
                          color: Color(0xFF4C2BF0),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add Halt / Stopover',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4C2BF0),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Drop-off (To) Row with Google Maps Red Pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFE53935),
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP-OFF LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B658C),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                      ),
                    ),
                    if (toGeo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        toGeo.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Vehicle Information Card
  Widget _buildVehicleInformationCard({
    required BuildContext context,
    required CarpoolOfferRideBloc bloc,
    required String vehicleModel,
    required String vehicleNumber,
  }) {
    final bool hasVehicle =
        vehicleModel.trim().isNotEmpty || vehicleNumber.trim().isNotEmpty;
    final String subtitleText = hasVehicle
        ? [
            if (vehicleModel.trim().isNotEmpty) vehicleModel.trim(),
            if (vehicleNumber.trim().isNotEmpty) vehicleNumber.trim(),
          ].join(' • ')
        : 'Tap to add vehicle model & number';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              _showVehicleDialog(context, bloc, vehicleModel, vehicleNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF3815D8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Vehical information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasVehicle
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: hasVehicle
                              ? const Color(0xFF3815D8)
                              : const Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B658C),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the Vehicle Information dialog box to enter vehicleModel and vehicleNumber
  void _showVehicleDialog(
    BuildContext context,
    CarpoolOfferRideBloc bloc,
    String currentModel,
    String currentNumber,
  ) {
    final modelController = TextEditingController(text: currentModel);
    final numberController = TextEditingController(text: currentNumber);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        title: const Row(
          children: [
            Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF3815D8),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Vehicle Model',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B658C),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: modelController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF140D43),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Honda City, Maruti Swift',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF9E98BE),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F5FE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF3815D8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Vehicle Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B658C),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: numberController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF140D43),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. TS 09 AB 1234',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF9E98BE),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F5FE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF3815D8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3815D8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final model = modelController.text.trim();
              final number = numberController.text.trim();
              bloc.add(
                CarpoolOfferVehicleChanged(model: model, number: number),
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Unified, clean and intuitive Seats & Price configuration card
  Widget _buildSeatsAndPricingCard({
    required int seats,
    required int pricePerSeat,
    required int totalPrice,
    required int distanceKm,
    required num ratePerKm,
    int? suggestedPrice,
    int? minPrice,
    int? maxPrice,
    required CarpoolOfferRideBloc bloc,
  }) {
    final bool canDecrementSeats = seats > 1;
    final bool canIncrementSeats = seats < 8;
    final bool canDecreasePrice = minPrice == null || pricePerSeat > minPrice;
    final bool canIncreasePrice = maxPrice == null || pricePerSeat < maxPrice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3815D8).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Available Seats ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                // Soft tinted circular icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.event_seat_rounded,
                    color: Color(0xFF3815D8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Labels
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Seats',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'How many passengers can join',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Stepper for Seats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E0FA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModernCircleStepperBtn(
                        icon: Icons.remove_rounded,
                        enabled: canDecrementSeats,
                        onTap: () {
                          if (canDecrementSeats) {
                            bloc.add(const CarpoolOfferSeatsChanged(-1));
                          }
                        },
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 34),
                        alignment: Alignment.center,
                        child: Text(
                          '$seats',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ),
                      _ModernCircleStepperBtn(
                        icon: Icons.add_rounded,
                        enabled: canIncrementSeats,
                        onTap: () {
                          if (canIncrementSeats) {
                            bloc.add(const CarpoolOfferSeatsChanged(1));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clean Subtle Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF2EFFD)),
          ),

          // ── Row 2: Price per Seat ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // Soft tinted circular rupee icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: Color(0xFF059669),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Labels
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price per Seat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF140D43),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fare charged to each passenger',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Stepper for Price (±10)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E0FA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModernCircleStepperBtn(
                        icon: Icons.remove_rounded,
                        enabled: canDecreasePrice,
                        onTap: () {
                          if (canDecreasePrice) {
                            bloc.add(
                              CarpoolOfferPriceChanged(
                                -10,
                                currentBasePrice: pricePerSeat,
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 54),
                        alignment: Alignment.center,
                        child: Text(
                          '₹$pricePerSeat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ),
                      _ModernCircleStepperBtn(
                        icon: Icons.add_rounded,
                        enabled: canIncreasePrice,
                        onTap: () {
                          if (canIncreasePrice) {
                            bloc.add(
                              CarpoolOfferPriceChanged(
                                10,
                                currentBasePrice: pricePerSeat,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Reassurance Banner ───────────────────────
          if (suggestedPrice != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FCFA),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFE9F7F1), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: ₹$suggestedPrice  •  Fair limit: ₹${minPrice ?? 0} – ₹${maxPrice ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Backward-compatible delegate for seats row
  // Widget _buildSeatsBookingRow(int seats, CarpoolOfferRideBloc bloc) {
  //   return _buildSeatsAndPricingCard(
  //     seats: seats,
  //     pricePerSeat: 0,
  //     totalPrice: 0,
  //     distanceKm: 0,
  //     ratePerKm: 3.5,
  //     bloc: bloc,
  //   );
  // }

  /// Backward-compatible delegate for price row
  // Widget _buildPriceMarginRow({
  //   required int pricePerSeat,
  //   required int totalPrice,
  //   required int distanceKm,
  //   required num ratePerKm,
  //   int? suggestedPrice,
  //   int? minPrice,
  //   int? maxPrice,
  //   required CarpoolOfferRideBloc bloc,
  // }) {
  //   return _buildSeatsAndPricingCard(
  //     seats: 1,
  //     pricePerSeat: pricePerSeat,
  //     totalPrice: totalPrice,
  //     distanceKm: distanceKm,
  //     ratePerKm: ratePerKm,
  //     suggestedPrice: suggestedPrice,
  //     minPrice: minPrice,
  //     maxPrice: maxPrice,
  //     bloc: bloc,
  //   );
  // }

  /// Builds the Price & Distance breakdown card using dynamic pricing calculation
  Widget _buildPriceCalculationCard({
    required num distanceKm,
    required num ratePerKm,
    required int totalPrice,
    required int pricePerSeat,
    required int seats,
    CarpoolPricingEntity? pricing,
    String? durationText,
  }) {
    // final String displayDistance = distanceKm is double && distanceKm % 1 != 0
    //     ? distanceKm.toStringAsFixed(1)
    //     : '${distanceKm.round()}';

    final String displayRate = ratePerKm is double && ratePerKm % 1 != 0
        ? ratePerKm.toStringAsFixed(1)
        : '${ratePerKm.round()}';

    // final String displayDuration =
    //     durationText ??
    //     (pricing != null
    //         ? pricing.formattedDuration
    //         : _estimateDuration(distanceKm.round()));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3BF5).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0ECFC)),
          ),
          const SizedBox(height: 12),

          // Line Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFareRowItem(
                  title: 'Base Route Rate',
                  subtitle: 'Calculated tariff per kilometer',
                  value: '₹$displayRate / km',
                ),
                const SizedBox(height: 10),
                _buildFareRowItem(
                  title: 'Price per Seat',
                  subtitle: 'Fare for 1 co-traveler seat',
                  value: '₹$pricePerSeat',
                  valueColor: const Color(0xFF3815D8),
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _buildFareRowItem(
                  title: 'Seats Offered',
                  subtitle: 'Total passenger capacity booked',
                  value: '$seats ${seats == 1 ? 'seat' : 'seats'}',
                ),
                const SizedBox(height: 10),
                _buildFareRowItem(
                  title: 'Total Price',
                  subtitle: '$seats seats × ₹$pricePerSeat / seat',
                  value: '₹$totalPrice',
                  valueColor: const Color(0xFF140D43),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grand Total Royal Purple Gradient Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4C1CDD),
                  Color(0xFF3815D8),
                  Color(0xFF2E0DA3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x334C1CDD),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL ESTIMATED RIDE PRICE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'For all $seats offered passenger seats combined',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹$totalPrice',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildMetricMiniChip({
  //   required IconData icon,
  //   required String label,
  //   required String value,
  //   required Color iconColor,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFF8F7FD),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: const Color(0xFFEDE8FF)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(icon, size: 14, color: iconColor),
  //             const SizedBox(width: 4),
  //             Flexible(
  //               child: Text(
  //                 label,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 10.5,
  //                   fontWeight: FontWeight.w600,
  //                   color: Color(0xFF6B658C),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           value,
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w800,
  //             color: Color(0xFF140D43),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFareRowItem({
    required String title,
    required String subtitle,
    required String value,
    Color valueColor = const Color(0xFF140D43),
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF140D43),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B658C),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Builds the Confirm Booking Gradient Button
  Widget _buildConfirmBookingButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D24F7), Color(0xFF300AB3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Rate badge pill indicating ₹10 / km
// ignore: unused_element
class _RateBadge extends StatelessWidget {
  final String rateText;
  const _RateBadge({required this.rateText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
      ),
      child: Text(
        rateText,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF15803D),
        ),
      ),
    );
  }
}

/// Modern circular tactile stepper button with interactive feedback
class _ModernCircleStepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _ModernCircleStepperBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF3815D8).withOpacity(0.15),
        highlightColor: const Color(0xFF3815D8).withOpacity(0.08),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? Colors.white : const Color(0xFFF1F0F7),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFDCD6F7)
                  : const Color(0xFFE5E2F0),
              width: 1.2,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF5B3BF5).withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 19,
            color: enabled ? const Color(0xFF3815D8) : const Color(0xFFA19DB8),
          ),
        ),
      ),
    );
  }
}
