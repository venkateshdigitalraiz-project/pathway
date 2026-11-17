import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/start_ride_entity.dart';
import '../bloc/start_ride_bloc.dart';

/// Single-class comprehensive Clean Architecture Start Ride flow.
/// Accurately implements all screens shown in the design:
/// 1. Today's Ride overview
/// 2. Navigate to Passenger map
/// 3. Contact Passenger bottom sheet
/// 4. Passenger Picked Up celebration
/// 5. Start Journey in-app navigation
/// 6. Ride in Progress scenic destination view
class StartRidePage extends StatelessWidget {
  final CarpoolRideEntity ride;
  final StartRidePassengerEntity? passenger;

  const StartRidePage({
    super.key,
    required this.ride,
    this.passenger,
  });

  /// Static entry-point to navigate to [StartRidePage] with BLoC
  static Future<void> show(
    BuildContext context, {
    required CarpoolRideEntity ride,
    StartRidePassengerEntity? passenger,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => StartRideBloc(
            initialRide: ride,
            initialPassenger: passenger,
          )..add(StartRideStarted(ride, customPassenger: passenger)),
          child: StartRidePage(ride: ride, passenger: passenger),
        ),
      ),
    );
  }

  StartRidePassengerEntity _getEffectivePassenger(
    StartRideState state,
    CarpoolRideEntity currentRide,
  ) {
    return state.passenger ??
        passenger ??
        StartRideBloc.createDefaultPassenger(
          currentRide,
          customPassenger: passenger,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StartRideBloc, StartRideState>(
      listenWhen: (prev, curr) =>
          (curr.message != null && curr.message != prev.message) ||
          (curr.isCompleted && !prev.isCompleted),
      listener: (context, state) {
        if (state.isCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride completed successfully! Great job!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
          return;
        }

        if (state.message != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              backgroundColor: const Color(0xFF5D24F7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == CarpoolStatus.loading) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAFD),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF5D24F7)),
            ),
          );
        }

        switch (state.step) {
          case StartRideStep.todaysRide:
            return _buildTodaysRideScreen(context, state);
          case StartRideStep.navigateToPassenger:
            return _buildNavigateToPassengerScreen(context, state);
          case StartRideStep.passengerPickedUp:
            return _buildPassengerPickedUpScreen(context, state);
          case StartRideStep.startJourney:
            return _buildStartJourneyScreen(context, state);
          case StartRideStep.rideInProgress:
            return _buildRideInProgressScreen(context, state);
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. TODAY'S RIDE SCREEN (Screen 1)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTodaysRideScreen(BuildContext context, StartRideState state) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);
    final rideCode = currentRide.id.toUpperCase().startsWith('CP-')
        ? currentRide.id.toUpperCase()
        : 'CP-${DateFormat('yyyyMMdd').format(currentRide.departure)}-001';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleBackButton(onTap: () => Navigator.pop(context)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: Color(0xFF5D24F7),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Today's Ride",
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  _buildCircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications for this ride'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Car Illustration Banner Card
                    _buildCarBannerCard(
                      rideCode: rideCode,
                      vehicleModel: passenger.vehicleType,
                    ),

                    const SizedBox(height: 24),

                    // Passenger Details Title
                    const Text(
                      'Passenger Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF140D43),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Passenger Info Card
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showContactPassengerBottomSheet(context, state),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDE8FF)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4C1CDD).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildPassengerAvatar(size: 50),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passenger.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF140D43),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 15,
                                        color: Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${passenger.rating.toStringAsFixed(1)} (${passenger.totalRides} rides)',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B658C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF8B85A8),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Locations Card (Pickup & Drop)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFEDE8FF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4C1CDD).withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Pickup Location Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDE8FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Color(0xFF5D24F7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pickup Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8B85A8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${passenger.pickupLocation} (${passenger.distanceToPassengerKm} km)',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF140D43),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const SizedBox(width: 15),
                                Container(
                                  width: 2,
                                  height: 24,
                                  color: const Color(0xFFEDE8FF),
                                ),
                              ],
                            ),
                          ),

                          // Drop Location Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Drop Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8B85A8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      passenger.dropoffLocation,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
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

                    const SizedBox(height: 16),

                    // Vehicle & Passengers Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.directions_car_rounded,
                                  size: 20,
                                  color: Color(0xFF5D24F7),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Vehicle',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8B85A8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      passenger.vehicleType,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF140D43),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: const Color(0xFFDDD6FE),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 20,
                                  color: Color(0xFF5D24F7),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Passengers',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8B85A8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${passenger.passengerCount}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF140D43),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Navigate to Passenger Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D24F7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(
                    Icons.near_me_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Navigate to Passenger',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () {
                    context.read<StartRideBloc>().add(
                          const StartRideNextStepPressed(),
                        );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. NAVIGATE TO PASSENGER SCREEN (Screen 2)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNavigateToPassengerScreen(
    BuildContext context,
    StartRideState state,
  ) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with On the Way title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  _buildCircleBackButton(
                    onTap: () {
                      context.read<StartRideBloc>().add(
                            const StartRidePreviousStepPressed(),
                          );
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'On the Way',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF140D43),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Reach passenger at ${passenger.pickupLocation.split(',').first.trim()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B658C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 42), // Balance back button
                ],
              ),
            ),

            // Live Navigation Map Canvas
            Expanded(
              child: Stack(
                children: [
                  // Simulated Map Route Canvas
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MockNavigationMapPainter(
                        isTowardsDestination: false,
                      ),
                    ),
                  ),

                  // Passenger Callout Tooltip
                  Positioned(
                    top: 50,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            passenger.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          Text(
                            '(${passenger.pickupLocation.split(',').first.trim()})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Locate Button
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF5D24F7),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Panel
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distance & ETA Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 20,
                          color: Color(0xFF5D24F7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${passenger.distanceToPassengerKm} km',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          Text(
                            'ETA: ${passenger.etaToPassengerMin} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Location Tag Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Color(0xFF5D24F7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            passenger.pickupLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Call Passenger Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D24F7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Call Passenger',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () =>
                          _showContactPassengerBottomSheet(context, state),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Message / Arrived Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFDDD6FE),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                            color: Color(0xFF5D24F7),
                          ),
                          label: const Text(
                            'Message',
                            style: TextStyle(
                              color: Color(0xFF5D24F7),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            context.read<StartRideBloc>().add(
                                  const StartRideMessagePassengerPressed(),
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text(
                            'Arrived at Pickup →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onPressed: () {
                            context.read<StartRideBloc>().add(
                                  const StartRideNextStepPressed(),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. CONTACT PASSENGER BOTTOM SHEET (Screen 3)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showContactPassengerBottomSheet(
    BuildContext context,
    StartRideState state,
  ) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD6FE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Passenger Avatar
            _buildPassengerAvatar(size: 68),

            const SizedBox(height: 12),

            // Passenger Name
            Text(
              passenger.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),

            const SizedBox(height: 4),

            // Rating & Rides
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${passenger.rating.toStringAsFixed(1)} (${passenger.totalRides} rides)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B658C),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 3 Circular Action Buttons: Call, Message, Share Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModalRoundButton(
                  icon: Icons.phone_rounded,
                  label: 'Call',
                  color: const Color(0xFF5D24F7),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: passenger.phone));
                    context.read<StartRideBloc>().add(
                          const StartRideCallPassengerPressed(),
                        );
                  },
                ),
                _buildModalRoundButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Message',
                  color: const Color(0xFF5D24F7),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<StartRideBloc>().add(
                          const StartRideMessagePassengerPressed(),
                        );
                  },
                ),
                _buildModalRoundButton(
                  icon: Icons.near_me_rounded,
                  label: 'Share\nLocation',
                  color: const Color(0xFF5D24F7),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<StartRideBloc>().add(
                          const StartRideShareLocationPressed(),
                        );
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDD6FE), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF140D43),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PASSENGER PICKED UP CELEBRATION SCREEN (Screen 4)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPassengerPickedUpScreen(
    BuildContext context,
    StartRideState state,
  ) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 10),
                child: _buildCircleBackButton(
                  onTap: () {
                    context.read<StartRideBloc>().add(
                          const StartRidePreviousStepPressed(),
                        );
                  },
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Celebration Confetti + Large Green Checkmark Badge
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ConfettiPainter(),
                            ),
                          ),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 46,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Headline Title
                    const Text(
                      'Passenger Picked Up!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF140D43),
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Start your journey towards\ndestination.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B658C),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Passenger Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F8FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDE8FF)),
                      ),
                      child: Row(
                        children: [
                          _buildPassengerAvatar(size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passenger.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 15,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${passenger.rating.toStringAsFixed(1)} (${passenger.totalRides} rides)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B658C),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Start Journey Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D24F7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: () {
                          context.read<StartRideBloc>().add(
                                const StartRideNextStepPressed(),
                              );
                        },
                        child: const Text(
                          'Start Journey  →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // View Ride Details Link
                    TextButton(
                      onPressed: () {
                        _showRideDetailsDialog(context, state);
                      },
                      child: const Text(
                        'View Ride Details',
                        style: TextStyle(
                          color: Color(0xFF5D24F7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. START JOURNEY / IN JOURNEY SCREEN (Screen 5)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStartJourneyScreen(BuildContext context, StartRideState state) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with In Journey Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  _buildCircleBackButton(
                    onTap: () {
                      context.read<StartRideBloc>().add(
                            const StartRidePreviousStepPressed(),
                          );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 9,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'In Journey',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            // Live Navigation Map Canvas to Destination
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MockNavigationMapPainter(
                        isTowardsDestination: true,
                        destinationName: passenger.dropoffLocation
                            .split(',')
                            .first
                            .trim(),
                      ),
                    ),
                  ),

                  // Destination Flag Callout Tooltip
                  Positioned(
                    top: 50,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        passenger.dropoffLocation.split(',').first.trim(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF140D43),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom In-Journey Panel
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 14,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distance & ETA + View Route Button
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 22,
                        color: Color(0xFF5D24F7),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${passenger.journeyDistanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          Text(
                            '≈ ${passenger.journeyEtaMin} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE8FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: Color(0xFF5D24F7),
                        ),
                        label: const Text(
                          'View Route',
                          style: TextStyle(
                            color: Color(0xFF5D24F7),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        onPressed: () {
                          context.read<StartRideBloc>().add(
                                const StartRideNextStepPressed(),
                              );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Destination Address Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Color(0xFF5D24F7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            passenger.dropoffLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // End Ride Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      label: const Text(
                        'End Ride',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _confirmEndRide(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. RIDE IN PROGRESS SCENIC HIGHWAY SCREEN (Screen 6)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRideInProgressScreen(BuildContext context, StartRideState state) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);

    return Scaffold(
      backgroundColor: const Color(0xFF140D43),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  _buildCircleBackButton(
                    color: Colors.white24,
                    iconColor: Colors.white,
                    onTap: () {
                      context.read<StartRideBloc>().add(
                            const StartRidePreviousStepPressed(),
                          );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Ride in Progress',
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Heading to Destination Title
            const Text(
              'Heading to Destination',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              passenger.dropoffLocation,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA5B4FC),
              ),
            ),

            const SizedBox(height: 16),

            // Scenic Highway & Car Illustration Canvas
            Expanded(
              child: CustomPaint(
                painter: _ScenicHighwayPainter(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Image.asset(
                      'assets/images/active_car.png',
                      width: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_rounded,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Floating Card & End Ride Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distance & ETA Row
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 22,
                        color: Color(0xFF5D24F7),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${passenger.journeyDistanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          Text(
                            '≈ ${passenger.journeyEtaMin} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE8FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: Color(0xFF5D24F7),
                        ),
                        label: const Text(
                          'View Route',
                          style: TextStyle(
                            color: Color(0xFF5D24F7),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        onPressed: () {
                          context.read<StartRideBloc>().add(
                                const StartRideStepSet(
                                  StartRideStep.startJourney,
                                ),
                              );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Red Solid End Ride Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      label: const Text(
                        'End Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => _confirmEndRide(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE SUB-WIDGETS & MODALS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCarBannerCard({
    required String rideCode,
    required String vehicleModel,
  }) {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF4FE), Color(0xFFF3EDFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
      ),
      child: Stack(
        children: [
          // Left Info
          Positioned(
            left: 16,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green active pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Text(
                        'Ride Active',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Carpool Ride',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF140D43),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#$rideCode',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B658C),
                  ),
                ),
              ],
            ),
          ),

          // Right Car Image
          Positioned(
            right: 8,
            bottom: 8,
            child: Image.asset(
              'assets/images/active_car_cutout.png',
              width: 170,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car_rounded,
                size: 80,
                color: Color(0xFF5D24F7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEDE8FF), width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/rider_image.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFEDE8FF),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF5D24F7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBackButton({
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: color == null ? const Color(0xFFEDE8FF) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          size: 26,
          color: iconColor ?? const Color(0xFF140D43),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEDE8FF)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF140D43)),
      ),
    );
  }

  Widget _buildModalRoundButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF140D43),
            ),
          ),
        ],
      ),
    );
  }

  void _showRideDetailsDialog(BuildContext context, StartRideState state) {
    final currentRide = state.ride ?? ride;
    final passenger = _getEffectivePassenger(state, currentRide);
    final r = currentRide;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 14),
            _buildDetailRow('From', passenger.pickupLocation),
            _buildDetailRow('To', passenger.dropoffLocation),
            _buildDetailRow('Vehicle', passenger.vehicleType),
            _buildDetailRow(
              'Scheduled Departure',
              CarpoolFormatters.headline(r.departure),
            ),
            _buildDetailRow(
              'Price per Seat',
              CarpoolFormatters.rupee(r.pricePerSeat),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D24F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B85A8),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF140D43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEndRide(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'End Ride?',
          style: TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to complete this ride? Passengers will be charged and notified.',
          style: TextStyle(color: Color(0xFF6B658C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm End',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<StartRideBloc>().add(const StartRideEndRidePressed());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM MAP & GRAPHIC PAINTERS (Ensures 60FPS offline high-fidelity UI)
// ═══════════════════════════════════════════════════════════════════════════

class _MockNavigationMapPainter extends CustomPainter {
  final bool isTowardsDestination;
  final String? destinationName;

  _MockNavigationMapPainter({
    required this.isTowardsDestination,
    this.destinationName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Canvas Background (Light soft map grey)
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Green Park Zones
    final parkPaint = Paint()..color = const Color(0xFFE2F3E7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 40, 110, 80),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 130, size.height - 180, 110, 100),
        const Radius.circular(20),
      ),
      parkPaint,
    );

    // 3. Roads / Streets
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.85);
    path.lineTo(size.width * 0.35, size.height * 0.55);
    path.lineTo(size.width * 0.65, size.height * 0.35);
    path.lineTo(size.width * 0.72, size.height * 0.2);

    canvas.drawPath(path, roadBorderPaint);
    canvas.drawPath(path, roadPaint);

    // Secondary Roads
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.5),
      roadBorderPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );

    // 4. Blue Active Route Line
    final routePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, routePaint);

    // 5. Driver Car Icon
    final carPos = Offset(size.width * 0.35, size.height * 0.55);
    final carBgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(carPos, 14, carBgPaint);
    final carBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(carPos, 14, carBorderPaint);

    // 6. Destination or Pickup Pin
    final pinPos = Offset(size.width * 0.72, size.height * 0.2);
    final pinPaint = Paint()
      ..color = isTowardsDestination
          ? const Color(0xFFEF4444)
          : const Color(0xFF5D24F7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pinPos, 10, pinPaint);
    final pinCenter = Paint()..color = Colors.white;
    canvas.drawCircle(pinPos, 4, pinCenter);
  }

  @override
  bool shouldRepaint(covariant _MockNavigationMapPainter oldDelegate) =>
      oldDelegate.isTowardsDestination != isTowardsDestination;
}

class _ScenicHighwayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Road surface perspective
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2C2455), Color(0xFF1E1742)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final roadPath = Path();
    roadPath.moveTo(size.width * 0.05, size.height);
    roadPath.lineTo(size.width * 0.95, size.height);
    roadPath.lineTo(size.width * 0.62, size.height * 0.4);
    roadPath.lineTo(size.width * 0.38, size.height * 0.4);
    roadPath.close();

    canvas.drawPath(roadPath, roadPaint);

    // Dashed center road markings
    final dashPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.5, size.height * 0.85),
      dashPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.62),
      dashPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.45),
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final random = math.Random(42);

    for (int i = 0; i < 40; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final isCircle = i % 2 == 0;

      if (isCircle) {
        canvas.drawCircle(Offset(dx, dy), random.nextDouble() * 3 + 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(dx, dy, random.nextDouble() * 6 + 3, 3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
