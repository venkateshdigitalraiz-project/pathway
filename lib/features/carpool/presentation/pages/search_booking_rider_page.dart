import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/repositories/search_booking_rider_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';
import '../bloc/search_booking_rider_bloc.dart';
import 'search_booking_details_page.dart';

/// Aliases to support exact user naming conventions
typedef SearchBookingRider = SearchBookingRiderPage;

/// Clean Architecture Search & Booking Rider Page
/// Follows BLoC pattern and ensures the search API is executed exactly once
/// with the given query parameters.
class SearchBookingRiderPage extends StatefulWidget {
  final String? initialOriginCity;
  final String? initialDestinationCity;
  final double? initialOriginLat;
  final double? initialOriginLng;
  final double? initialDestinationLat;
  final double? initialDestinationLng;
  final DateTime? initialDate;
  final int? initialSeats;
  final int? initialRadiusKm;

  const SearchBookingRiderPage({
    super.key,
    this.initialOriginCity,
    this.initialDestinationCity,
    this.initialOriginLat,
    this.initialOriginLng,
    this.initialDestinationLat,
    this.initialDestinationLng,
    this.initialDate,
    this.initialSeats,
    this.initialRadiusKm,
  });

  /// Static helper to navigate cleanly from any context
  static Future<void> show(
    BuildContext context, {
    String? originCity,
    String? destinationCity,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? date,
    int? seats,
    int? radiusKm,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchBookingRiderPage(
          initialOriginCity: originCity,
          initialDestinationCity: destinationCity,
          initialOriginLat: originLat,
          initialOriginLng: originLng,
          initialDestinationLat: destinationLat,
          initialDestinationLng: destinationLng,
          initialDate: date,
          initialSeats: seats,
          initialRadiusKm: radiusKm,
        ),
      ),
    );
  }

  @override
  State<SearchBookingRiderPage> createState() => _SearchBookingRiderPageState();
}

class _SearchBookingRiderPageState extends State<SearchBookingRiderPage> {
  late final SearchBookingRiderBloc _bloc;
  bool _hasDispatched = false;

  @override
  void initState() {
    super.initState();
    final repo = SearchBookingRiderRepositoryImpl();
    final hasInitialQuery =
        (widget.initialOriginCity != null &&
            widget.initialOriginCity!.isNotEmpty) ||
        (widget.initialDestinationCity != null &&
            widget.initialDestinationCity!.isNotEmpty);

    _bloc = SearchBookingRiderBloc(
      getBookings: GetRiderBookingsUseCase(repo),
      searchRides: SearchRiderRidesUseCase(repo),
      bookSeat: BookRiderSeatUseCase(repo),
      cancelBooking: CancelRiderBookingUseCase(repo),
    )..add(const SearchBookingRiderStarted());

    // Dispatch the search event exactly ONCE upon page initialization
    if (hasInitialQuery && !_hasDispatched) {
      _bloc.add(
        SearchBookingRiderSearchRequested(
          from: widget.initialOriginCity ?? '',
          to: widget.initialDestinationCity ?? '',
          originLat: widget.initialOriginLat,
          originLng: widget.initialOriginLng,
          destinationLat: widget.initialDestinationLat,
          destinationLng: widget.initialDestinationLng,
          date: widget.initialDate ?? DateTime.now(),
          seats: widget.initialSeats ?? 1,
          radiusKm: widget.initialRadiusKm ?? 30,
        ),
      );
      _hasDispatched = true;
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBookingRiderBloc>.value(
      value: _bloc,
      child: _SearchBookingRiderView(
        originCity: widget.initialOriginCity,
        destinationCity: widget.initialDestinationCity,
        originLat: widget.initialOriginLat,
        originLng: widget.initialOriginLng,
        destinationLat: widget.initialDestinationLat,
        destinationLng: widget.initialDestinationLng,
        date: widget.initialDate,
        seats: widget.initialSeats,
        radiusKm: widget.initialRadiusKm,
      ),
    );
  }
}

class _SearchBookingRiderView extends StatelessWidget {
  final String? originCity;
  final String? destinationCity;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime? date;
  final int? seats;
  final int? radiusKm;

  const _SearchBookingRiderView({
    this.originCity,
    this.destinationCity,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.date,
    this.seats,
    this.radiusKm,
  });

  void _triggerSearch(BuildContext context) {
    context.read<SearchBookingRiderBloc>().add(
      SearchBookingRiderSearchRequested(
        from: originCity ?? '',
        to: destinationCity ?? '',
        originLat: originLat,
        originLng: originLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        date: date ?? DateTime.now(),
        seats: seats ?? 1,
        radiusKm: radiusKm ?? 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromName = originCity?.isNotEmpty == true ? originCity! : 'Origin';
    final toName = destinationCity?.isNotEmpty == true
        ? destinationCity!
        : 'Destination';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF140D43),
            size: 19,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            Text(
              '$fromName → $toName',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B658C),
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(
        //       Icons.refresh_rounded,
        //       color: Color(0xFF5D24F7),
        //       size: 22,
        //     ),
        //     tooltip: 'Refresh',
        //     onPressed: () => _triggerSearch(context),
        //   ),
        // ],
      ),
      body: BlocConsumer<SearchBookingRiderBloc, SearchBookingRiderState>(
        listenWhen: (prev, curr) =>
            curr.message != null && curr.message != prev.message,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: state.message!.toLowerCase().contains('failed')
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Query summary pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Color(0xFF5D24F7),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$fromName to $toName',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date != null ? CarpoolFormatters.date(date!) : "Today"} • ${seats ?? 1} passenger',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: state.searchResults.isNotEmpty
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.status == CarpoolStatus.loading
                            ? 'Searching...'
                            : '${state.searchResults.length} Ride${state.searchResults.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: state.searchResults.isNotEmpty
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDE8FF)),

              // Main Content
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchBookingRiderState state) {
    if (state.status == CarpoolStatus.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF5D24F7),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Finding available rides...',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF140D43),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connecting with drivers on this route',
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFF6B658C).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_crash_rounded,
                  size: 36,
                  color: Color(0xFF5D24F7),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Rides Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'There are no published rides matching your route and time. Try searching again or pick a different date.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B658C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D24F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                onPressed: () => _triggerSearch(context),
                child: const Text(
                  'Search Again',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final ride = state.searchResults[index];

        return _RideCard(
          ride: ride,
          onTap: () async {
            final booked = await SearchBookingDetailsPage.show(
              context,
              rideId: ride.id,
              initialRide: ride,
            );
            if (booked == true && context.mounted) {
              _triggerSearch(context);
            }
          },
        );
      },
    );
  }
}

/// Tailored, uncluttered Ride Card that presents only relevant information
/// strictly derived from the backend response.
class _RideCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final VoidCallback onTap;

  const _RideCard({
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = ride.driverName.isNotEmpty
        ? ride.driverName.trim()[0].toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D24F7).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Driver Avatar, Driver Name, Rating & Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEDE8FF),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5D24F7),
                        ),
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
                                  ride.driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${ride.driverRating}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (ride.rideCode != null &&
                              ride.rideCode!.isNotEmpty)
                            Text(
                              ride.rideCode!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B85A8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CarpoolFormatters.rupee(ride.pricePerSeat),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D24F7),
                          ),
                        ),
                        const Text(
                          'per seat',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8B85A8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Route Display (Origin to Destination)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEDE8FF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 18,
                                color: const Color(0xFFDDD6FE),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.from,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  ride.to,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ride.estimatedDuration.isNotEmpty ||
                              ride.displayDistance.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEDE8FF),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (ride.estimatedDuration.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: Color(0xFF5D24F7),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          ride.estimatedDuration,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF5D24F7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (ride.displayDistance.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.route_rounded,
                                          size: 12,
                                          color: Color(0xFF7C3AED),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          ride.displayDistance,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (ride.stopovers != null &&
                          ride.stopovers!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1, color: Color(0xFFEDE8FF)),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.alt_route_rounded,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Via: ${ride.stopovers!.map((s) => s['city']?.toString() ?? s['name']?.toString() ?? '').where((c) => c.isNotEmpty).join(' • ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Key Chips Row: Time, Duration & Distance, Available Seats, Vehicle
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Departure Time
                    _buildPill(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: const Color(0xFF5D24F7),
                      text: CarpoolFormatters.shortDateTime(ride.departure),
                      bgColor: const Color(0xFFF3F0FF),
                      textColor: const Color(0xFF140D43),
                    ),
                    // Estimated Journey Time & Distance Pill
                    if (ride.estimatedDuration.isNotEmpty ||
                        ride.displayDistance.isNotEmpty)
                      _buildPill(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF1A73E8),
                        text:
                            (ride.estimatedDuration.isNotEmpty &&
                                ride.displayDistance.isNotEmpty)
                            ? '${ride.estimatedDuration} • ${ride.displayDistance}'
                            : (ride.estimatedDuration.isNotEmpty
                                  ? ride.estimatedDuration
                                  : ride.displayDistance),
                        bgColor: const Color(0xFFE8F0FE),
                        textColor: const Color(0xFF1A73E8),
                      ),
                    // Available Seats
                    _buildPill(
                      icon: Icons.event_seat_rounded,
                      iconColor: const Color(0xFF059669),
                      text:
                          '${ride.seats} seat${ride.seats == 1 ? '' : 's'} left',
                      bgColor: const Color(0xFFECFDF5),
                      textColor: const Color(0xFF059669),
                    ),
                    // Vehicle Info
                    if (ride.vehicle.isNotEmpty)
                      _buildPill(
                        icon: Icons.directions_car_rounded,
                        iconColor: const Color(0xFF6B658C),
                        text: ride.vehicle,
                        bgColor: const Color(0xFFF1F5F9),
                        textColor: const Color(0xFF475569),
                      ),
                  ],
                ),

                // Notes badge (if provided by publisher)
                if (ride.notes != null && ride.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ride.notes!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
