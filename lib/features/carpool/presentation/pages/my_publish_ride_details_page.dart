import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../data/repositories/my_publish_ride_details_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/my_publish_ride_details_entity.dart';
import '../../domain/usecases/accept_booking_usecase.dart';
import '../../domain/usecases/get_my_publish_ride_details_usecase.dart';
import '../../domain/usecases/reject_booking_usecase.dart';
import '../bloc/my_publish_ride_details_bloc.dart';
import 'start_ride_page.dart';

/// Screen displaying the full details of a published ride for the driver.
/// Clean Architecture implementation powered by [MyPublishRideDetailsBloc].
class MyPublishRideDetailsPage extends StatelessWidget {
  final String rideId;
  final CarpoolRideEntity? initialRide;

  const MyPublishRideDetailsPage({
    super.key,
    required this.rideId,
    this.initialRide,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyPublishRideDetailsBloc>(
      create: (_) => MyPublishRideDetailsBloc(
        getPublishRideDetails: GetMyPublishRideDetailsUseCase(
          MyPublishRideDetailsRepositoryImpl(),
        ),
        acceptBooking: AcceptBookingUseCase(
          CarpoolRepositoryImpl(CarpoolMockDataSource()),
        ),
        rejectBooking: RejectBookingUseCase(
          CarpoolRepositoryImpl(CarpoolMockDataSource()),
        ),
      )..add(MyPublishRideDetailsFetchRequested(rideId)),
      child: _MyPublishRideDetailsView(
        rideId: rideId,
        initialRide: initialRide,
      ),
    );
  }
}

class _MyPublishRideDetailsView extends StatelessWidget {
  final String rideId;
  final CarpoolRideEntity? initialRide;

  const _MyPublishRideDetailsView({required this.rideId, this.initialRide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FD),
      appBar: _buildAppBar(context),
      body: BlocConsumer<MyPublishRideDetailsBloc, MyPublishRideDetailsState>(
        listener: (context, state) {
          if (state is MyPublishRideDetailsLoaded &&
              state.feedbackMessage != null &&
              state.feedbackMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.feedbackMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: state.isErrorFeedback
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MyPublishRideDetailsLoading) {
            return _buildLoading(context);
          } else if (state is MyPublishRideDetailsLoaded) {
            return _buildContent(
              context,
              state.details,
              processingBookingId: state.processingBookingId,
            );
          } else if (state is MyPublishRideDetailsFailure) {
            return _buildError(context, state.error);
          }
          return _buildLoading(context);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: const Text(
        'Published Ride Details',
        style: TextStyle(
          color: Color(0xFF140D43),
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF5D24F7),
            size: 22,
          ),
          onPressed: () {
            context.read<MyPublishRideDetailsBloc>().add(
              MyPublishRideDetailsRefreshRequested(rideId),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF5D24F7), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Loading ride details…',
            style: TextStyle(
              color: Color(0xFF6B658C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MyPublishRideDetailsBloc>().add(
                  MyPublishRideDetailsFetchRequested(rideId),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D24F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MyPublishRideDetailsEntity ride, {
    String? processingBookingId,
  }) {
    return RefreshIndicator(
      color: const Color(0xFF5D24F7),
      onRefresh: () async {
        context.read<MyPublishRideDetailsBloc>().add(
          MyPublishRideDetailsRefreshRequested(rideId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Bar: Ride Code + Status
            _buildRideCodeBar(context, ride),
            const SizedBox(height: 14),

            // 2. Route & Schedule Card
            _buildRouteCard(ride),
            const SizedBox(height: 16),

            // 3. Stats Grid (Seats, Price, Occupied, Potential)
            _buildMetricsGrid(ride),
            const SizedBox(height: 16),

            // 4. Vehicle & Driver Card
            _buildVehicleCard(ride),
            const SizedBox(height: 16),

            // 5. Notes / Direct Drive badge
            if (ride.notes.isNotEmpty) ...[
              _buildNotesCard(ride),
              const SizedBox(height: 16),
            ],

            // 6. Booked Passengers Section
            _buildBookedPassengersSection(
              context,
              ride,
              processingBookingId: processingBookingId,
            ),
            const SizedBox(height: 24),

            // 7. Action Button
            _buildStartRideButton(context, ride),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCodeBar(
    BuildContext context,
    MyPublishRideDetailsEntity ride,
  ) {
    final bool isActive = ride.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EDFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: Color(0xFF5D24F7),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Code',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    ride.rideCode.isNotEmpty ? ride.rideCode : 'CR-PUBLISHED',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF140D43),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Active' : ride.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? const Color(0xFF15803D)
                        : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(MyPublishRideDetailsEntity ride) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy • hh:mm a');
    final formattedDate = dateFormat.format(ride.departureTime.toLocal());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Departure time banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D24F7), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Route Timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin indicators
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 48,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Locations text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ORIGIN / PICKUP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.originAddress.isNotEmpty
                              ? ride.originAddress
                              : 'Starting Point',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (ride.originCity.isNotEmpty &&
                            ride.originCity != ride.originAddress)
                          Text(
                            ride.originCity,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Destination
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESTINATION / DROPOFF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.destinationAddress.isNotEmpty
                              ? ride.destinationAddress
                              : 'Destination',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (ride.destinationCity.isNotEmpty &&
                            ride.destinationCity != ride.destinationAddress)
                          Text(
                            ride.destinationCity,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(MyPublishRideDetailsEntity ride) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Price / Seat',
                value: '₹${ride.pricePerSeat}',
                subtitle: 'per passenger',
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                title: 'Available Seats',
                value: '${ride.availableSeats} of ${ride.totalSeats}',
                subtitle: '${ride.totalSeatsOccupied} occupied',
                icon: Icons.event_seat_rounded,
                iconColor: const Color(0xFF5D24F7),
                bgColor: const Color(0xFFF3E8FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Passengers',
                value: '${ride.totalPassengers}',
                subtitle: '${ride.bookings.length} confirmed booking(s)',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                title: 'Total Earned',
                value: '₹${ride.currentEarnings}',
                subtitle: 'from booked seats',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(MyPublishRideDetailsEntity ride) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D24F7), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REGISTERED VEHICLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ride.vehicleModel.isNotEmpty ? ride.vehicleModel : 'Toyota',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.vehicleNumber.isNotEmpty
                      ? ride.vehicleNumber
                      : 'Verified Plate',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D24F7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF3B82F6)),
                SizedBox(width: 4),
                Text(
                  'AC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(MyPublishRideDetailsEntity ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ride.notes,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedPassengersSection(
    BuildContext context,
    MyPublishRideDetailsEntity ride, {
    String? processingBookingId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Booked Passengers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D24F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ride.bookings.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (ride.bookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 38,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 12),
                Text(
                  'No Bookings Yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'When passengers book seats on this ride, their details and pickup locations will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ride.bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final passenger = ride.bookings[index];
              return _buildPassengerCard(
                context,
                rideId: ride.id,
                passenger: passenger,
                isProcessing: processingBookingId == passenger.id,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPassengerCard(
    BuildContext context, {
    required String rideId,
    required MyPublishRidePassengerEntity passenger,
    bool isProcessing = false,
  }) {
    final bool hasAvatar =
        passenger.passengerAvatar != null &&
        passenger.passengerAvatar!.trim().isNotEmpty;
    final bool isPaid = passenger.paymentStatus.toLowerCase() == 'paid';
    final String statusLower = passenger.bookingStatus.trim().toLowerCase();
    final bool isConfirmed =
        statusLower == 'confirmed' || statusLower == 'accepted';
    final bool isCancelled = statusLower == 'cancelled' ||
        statusLower == 'rejected' ||
        statusLower == 'declined';
    final bool showActionButtons = !isConfirmed && !isCancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEDE9FE),
                backgroundImage: hasAvatar
                    ? NetworkImage(passenger.passengerAvatar!)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        passenger.passengerName.isNotEmpty
                            ? passenger.passengerName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Color(0xFF5D24F7),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.passengerName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (passenger.passengerPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        passenger.passengerPhone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${passenger.totalAmount}',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      passenger.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: isPaid
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_seat_rounded,
                    size: 15,
                    color: Color(0xFF5D24F7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${passenger.seatsBooked} ${passenger.seatsBooked == 1 ? "Seat" : "Seats"} Booked',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  passenger.bookingCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          if (passenger.fromAddress.isNotEmpty ||
              passenger.toAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 15,
                    color: Color(0xFF5D24F7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${passenger.fromAddress.isNotEmpty ? passenger.fromAddress : "Origin"} → ${passenger.toAddress.isNotEmpty ? passenger.toAddress : "Destination"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action row (Reject & Accept) when pending; Status banner when confirmed/cancelled
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          if (showActionButtons)
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: Material(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isProcessing
                          ? null
                          : () => _showRejectDialog(context, rideId, passenger),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isProcessing) ...[
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                            ],
                            const Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Accept Button
                Expanded(
                  child: Material(
                    color: const Color(0xFF5D24F7),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isProcessing
                          ? null
                          : () {
                              context.read<MyPublishRideDetailsBloc>().add(
                                    MyPublishRideDetailsAcceptBookingRequested(
                                      rideId: rideId,
                                      bookingId: passenger.id,
                                    ),
                                  );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5D24F7).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isProcessing) ...[
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                isProcessing ? 'Processing…' : 'Accept',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildStatusBanner(statusLower),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String statusLower) {
    final bool isConfirmed =
        statusLower == 'confirmed' || statusLower == 'accepted';
    final bool isCancelled = statusLower == 'cancelled' ||
        statusLower == 'rejected' ||
        statusLower == 'declined';

    final Color bgColor = isConfirmed
        ? const Color(0xFFDCFCE7)
        : (isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFEDE9FE));
    final Color borderColor = isConfirmed
        ? const Color(0xFF86EFAC)
        : (isCancelled ? const Color(0xFFFCA5A5) : const Color(0xFFDDD6FE));
    final Color textColor = isConfirmed
        ? const Color(0xFF15803D)
        : (isCancelled ? const Color(0xFFDC2626) : const Color(0xFF5D24F7));
    final IconData icon = isConfirmed
        ? Icons.check_circle_rounded
        : (isCancelled ? Icons.cancel_rounded : Icons.info_rounded);
    final String label = isConfirmed
        ? 'Booking Confirmed'
        : (isCancelled
            ? 'Booking Cancelled'
            : 'Booking ${statusLower.isNotEmpty ? (statusLower[0].toUpperCase() + statusLower.substring(1)) : "Status"}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    String rideId,
    MyPublishRidePassengerEntity passenger,
  ) {
    final reasonController = TextEditingController(
      text: 'Vehicle maintenance issue, unable to accommodate passenger',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Decline Booking',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decline booking ${passenger.bookingCode} for ${passenger.passengerName}?',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason for declining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  hintText: 'Enter reason for declining',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : 'Vehicle maintenance issue, unable to accommodate passenger';
                Navigator.of(dialogContext).pop();
                context.read<MyPublishRideDetailsBloc>().add(
                      MyPublishRideDetailsRejectBookingRequested(
                        rideId: rideId,
                        bookingId: passenger.id,
                        reason: reason,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartRideButton(
    BuildContext context,
    MyPublishRideDetailsEntity ride,
  ) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5025D1), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5025D1).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Convert to CarpoolRideEntity to invoke StartRidePage
          final carpoolRide = CarpoolRideEntity(
            id: ride.id,
            driverName: ride.publisherName,
            driverRating: 4.9,
            driverTrips: 120,
            vehicle: '${ride.vehicleModel} • ${ride.vehicleNumber}',
            vehicleModel: ride.vehicleModel,
            vehicleNumber: ride.vehicleNumber,
            from: ride.originAddress,
            to: ride.destinationAddress,
            departure: ride.departureTime,
            seats: ride.availableSeats,
            pricePerSeat: ride.pricePerSeat,
            distanceKm: 25,
            status: CarpoolRideStatus.upcoming,
            rideType: CarpoolRideType.normal,
            originCity: ride.originCity,
            destinationCity: ride.destinationCity,
          );
          StartRidePage.show(context, ride: carpoolRide);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Navigation / Ride',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
