import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/carpool_location_picker_bloc.dart';

/// Dynamic bottom floating card displaying either:
/// 1. Pinned Pick-up Location with "Set Pick-up & Choose Drop →" button
/// 2. Pinned Drop-off Location with "Confirm Drop-off" button
/// 3. Complete Route Navigation Card with distance, duration, and "Proceed to Publish Ride →" button
class CarpoolLocationBottomCard extends StatelessWidget {
  final VoidCallback onProceedToPublishRide;
  final VoidCallback? onConfirmPickup;
  final VoidCallback? onConfirmDropoff;

  const CarpoolLocationBottomCard({
    super.key,
    required this.onProceedToPublishRide,
    this.onConfirmPickup,
    this.onConfirmDropoff,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarpoolLocationPickerBloc, CarpoolLocationPickerState>(
      builder: (context, state) {
        if (state.hasBothLocations &&
            state.step == CarpoolLocationStep.routeReady) {
          return _buildRouteNavigationCard(context, state);
        }

        if (state.step == CarpoolLocationStep.dropoff) {
          return _buildDropoffLocationCard(context, state);
        }

        return _buildPickupLocationCard(context, state);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. PINNED PICK-UP LOCATION CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPickupLocationCard(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    final place = state.pickupPlace;
    final String title = place?.name.isNotEmpty == true
        ? place!.name
        : (state.pickupQuery.trim().isNotEmpty
            ? state.pickupQuery.trim()
            : 'Pinned Pick-up Location');
    final String address = place?.formattedAddress.isNotEmpty == true
        ? place!.formattedAddress
        : 'Coordinates: ${state.mapCenterLat.toStringAsFixed(4)}, ${state.mapCenterLng.toStringAsFixed(4)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFDDD6FE),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trip_origin_rounded,
                  color: Color(0xFF5D24F7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
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
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PICK-UP',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5D24F7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Click pinned location to open drop location on same screen
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                context.read<CarpoolLocationPickerBloc>().add(
                      const CarpoolLocationPickerConfirmPickup(),
                    );
                if (onConfirmPickup != null) {
                  onConfirmPickup!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D24F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Set Pick-up & Choose Drop-off',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. PINNED DROP-OFF LOCATION CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDropoffLocationCard(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    final place = state.dropoffPlace;
    final String title = place?.name.isNotEmpty == true
        ? place!.name
        : (state.dropoffQuery.trim().isNotEmpty
            ? state.dropoffQuery.trim()
            : 'Pinned Drop-off Location');
    final String address = place?.formattedAddress.isNotEmpty == true
        ? place!.formattedAddress
        : 'Coordinates: ${state.mapCenterLat.toStringAsFixed(4)}, ${state.mapCenterLng.toStringAsFixed(4)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFECACA),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
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
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DROP-OFF',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action button to view complete route navigation
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                if (onConfirmDropoff != null) {
                  onConfirmDropoff!();
                } else if (state.pickupPlace != null && state.dropoffPlace != null) {
                  onProceedToPublishRide();
                } else {
                  context.read<CarpoolLocationPickerBloc>().add(
                        const CarpoolLocationPickerStepChanged(
                          CarpoolLocationStep.pickup,
                        ),
                      );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirm Drop-off & View Route',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.route_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. COMPLETE ROUTE NAVIGATION SUMMARY CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRouteNavigationCard(
    BuildContext context,
    CarpoolLocationPickerState state,
  ) {
    final pickup = state.pickupPlace!;
    final dropoff = state.dropoffPlace!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFDDD6FE),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route Header (Origin -> Destination)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        pickup.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF5D24F7),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        dropoff.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Route Ready Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ROUTE SET',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Distance and Duration Stats Row
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                '~${state.routeDistanceKm} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                state.routeDurationText.isNotEmpty
                    ? state.routeDurationText
                    : 'Driving Route',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Navigation CTA: Proceed to Publish Ride
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onProceedToPublishRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D24F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Route & View Tolls',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
