import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/repositories/my_ride_booking_repository_impl.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/cancel_my_ride_booking_usecase.dart';
import '../../domain/usecases/get_my_ride_bookings_usecase.dart';
import '../bloc/my_ride_booking_bloc.dart';
import 'search_booking_rider_page.dart';

class MyRideBookingPage extends StatelessWidget {
  const MyRideBookingPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyRideBookingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = MyRideBookingRepositoryImpl();
    return BlocProvider<MyRideBookingBloc>(
      create: (_) => MyRideBookingBloc(
        getMyBookings: GetMyRideBookingsUseCase(repo),
        cancelBooking: CancelMyRideBookingUseCase(repo),
      )..add(const MyRideBookingStarted()),
      child: const _MyRideBookingView(),
    );
  }
}

class _MyRideBookingView extends StatefulWidget {
  const _MyRideBookingView();

  @override
  State<_MyRideBookingView> createState() => _MyRideBookingViewState();
}

class _MyRideBookingViewState extends State<_MyRideBookingView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF5D24F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmCancel(BuildContext context, RiderBookingEntity booking) async {
    final bloc = context.read<MyRideBookingBloc>();
    final reasonCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Cancel This Booking?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF140D43),
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your seat with ${booking.driverName} from ${booking.from} to ${booking.to}?',
              style: const TextStyle(
                color: Color(0xFF6B658C),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'Cancellation reason (optional)',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9E98BD),
                ),
                filled: true,
                fillColor: const Color(0xFFF9F8FE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE8FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5D24F7),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Booking',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final reason = reasonCtrl.text.trim();
      bloc.add(
        MyRideBookingCancelRequested(
          booking.id,
          reason: reason.isNotEmpty ? reason : null,
        ),
      );
    }
  }

  void _showBookingDetailsSheet(
    BuildContext context,
    RiderBookingEntity booking,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD6FE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF140D43),
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 16),

              // Route Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE8FF)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.trip_origin_rounded,
                          size: 15,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.from,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 7, top: 3, bottom: 3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 1.5,
                          height: 16,
                          color: const Color(0xFFDDD6FE),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: Color(0xFF5D24F7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.to,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF140D43),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Driver Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFF5D24F7).withOpacity(0.12),
                      child: Text(
                        booking.driverName.isNotEmpty
                            ? booking.driverName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Color(0xFF5D24F7),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
                              Text(
                                booking.driverName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                              if (booking.driverRating > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFF59E0B),
                                ),
                                Text(
                                  '${booking.driverRating}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (booking.driverPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              booking.driverPhone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B658C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (booking.vehicle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              booking.vehicleNumber != null &&
                                      booking.vehicleNumber!.isNotEmpty
                                  ? '${booking.vehicle} • ${booking.vehicleNumber}'
                                  : booking.vehicle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (booking.driverPhone.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.phone_rounded,
                          color: Color(0xFF5D24F7),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: booking.driverPhone),
                          );
                          _snack(
                            context,
                            'Driver phone copied: ${booking.driverPhone}',
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Specs Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailTile(
                    'Booking ID',
                    '#${booking.id}',
                    Icons.tag_rounded,
                  ),
                  _buildDetailTile(
                    'Seats Booked',
                    '${booking.seatsBooked} Seat(s)',
                    Icons.airline_seat_recline_normal_rounded,
                  ),
                  _buildDetailTile(
                    'Total Fare',
                    CarpoolFormatters.rupee(booking.totalAmount),
                    Icons.payments_rounded,
                    valueColor: const Color(0xFF5D24F7),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildDetailTile(
                'Departure Date & Time',
                CarpoolFormatters.shortDateTime(booking.departure),
                Icons.access_time_rounded,
              ),

              if (booking.passengerNotes != null &&
                  booking.passengerNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDE8FF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: Color(0xFF5D24F7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Passenger Note: "${booking.passengerNotes}"',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF4C1CDD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (booking.otpCode != null &&
                  booking.otpCode!.trim().isNotEmpty &&
                  booking.status == RiderBookingStatus.confirmed) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Trip OTP Code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5D24F7),
                            ),
                          ),
                          Text(
                            'Share with driver at boarding',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF6B658C),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        booking.otpCode!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Color(0xFF140D43),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D24F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B658C)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8B85A8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF140D43),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RiderBookingStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case RiderBookingStatus.confirmed:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case RiderBookingStatus.completed:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'Completed';
        icon = Icons.task_alt_rounded;
        break;
      case RiderBookingStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Color(0xFFFAFAFF),
              Colors.white,
            ],
            stops: [0.0, 0.25, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<MyRideBookingBloc, MyRideBookingState>(
            listenWhen: (p, c) => c.message != null && p.message != c.message,
            listener: (context, s) => _snack(context, s.message!),
            builder: (context, s) {
              return Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF140D43),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'My Ride Booking',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Track and manage your reserved carpool rides',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B658C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF5D24F7),
                          ),
                          onPressed: () => context
                              .read<MyRideBookingBloc>()
                              .add(const MyRideBookingRefreshed()),
                        ),
                      ],
                    ),
                  ),

                  // Metrics Summary Carousel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Active',
                            count: '${s.activeCount}',
                            icon: Icons.directions_car_rounded,
                            color: const Color(0xFF10B981),
                            bgGradient: const [
                              Color(0xFFE8FDF3),
                              Color(0xFFF3FEF8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Completed',
                            count: '${s.completedCount}',
                            icon: Icons.verified_rounded,
                            color: const Color(0xFF5D24F7),
                            bgGradient: const [
                              Color(0xFFEDE8FF),
                              Color(0xFFF7F5FE),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Spent',
                            count: CarpoolFormatters.rupee(s.totalFareSpent),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF0284C7),
                            bgGradient: const [
                              Color(0xFFE0F2FE),
                              Color(0xFFF0F9FF),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEDE8FF)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => context
                            .read<MyRideBookingBloc>()
                            .add(MyRideBookingSearchQueryChanged(val)),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Search by city, dropoff, or driver...',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9E98BD),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF5D24F7),
                            size: 19,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    context
                                        .read<MyRideBookingBloc>()
                                        .add(
                                          const MyRideBookingSearchQueryChanged(
                                            '',
                                          ),
                                        );
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Segmented Filter Pills (All, Active, Completed, Cancelled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(
                            label: 'All (${s.totalCount})',
                            isSelected: s.tabIndex == 0,
                            onTap: () => context
                                .read<MyRideBookingBloc>()
                                .add(const MyRideBookingTabChanged(0)),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            label: 'Active (${s.activeCount})',
                            isSelected: s.tabIndex == 1,
                            onTap: () => context
                                .read<MyRideBookingBloc>()
                                .add(const MyRideBookingTabChanged(1)),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            label: 'Completed (${s.completedCount})',
                            isSelected: s.tabIndex == 2,
                            onTap: () => context
                                .read<MyRideBookingBloc>()
                                .add(const MyRideBookingTabChanged(2)),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterPill(
                            label: 'Cancelled (${s.cancelledCount})',
                            isSelected: s.tabIndex == 3,
                            onTap: () => context
                                .read<MyRideBookingBloc>()
                                .add(const MyRideBookingTabChanged(3)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Main List
                  Expanded(
                    child: s.status == CarpoolStatus.loading &&
                            s.bookings.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D24F7),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF5D24F7),
                            onRefresh: () async {
                              context
                                  .read<MyRideBookingBloc>()
                                  .add(const MyRideBookingRefreshed());
                            },
                            child: s.filteredBookings.isEmpty
                                ? _buildEmptyState(context, s.tabIndex)
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      6,
                                      20,
                                      32,
                                    ),
                                    itemCount: s.filteredBookings.length,
                                    itemBuilder: (context, idx) {
                                      final item = s.filteredBookings[idx];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _MyRideBookingItemCard(
                                          booking: item,
                                          isCancelling:
                                              s.cancellingBookingId == item.id,
                                          onCancel: () =>
                                              _confirmCancel(context, item),
                                          onTap: () =>
                                              _showBookingDetailsSheet(
                                            context,
                                            item,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required List<Color> bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B658C),
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D24F7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF5D24F7) : const Color(0xFFEDE8FF),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D24F7).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B658C),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int tabIndex) {
    String message = 'You have no bookings under this filter.';
    if (tabIndex == 1) message = 'No active or upcoming bookings found.';
    if (tabIndex == 2) message = 'No completed trip history yet.';
    if (tabIndex == 3) message = 'No cancelled bookings.';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFF5D24F7),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No Ride Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF140D43),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B658C),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D24F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Search & Book Rides',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            onPressed: () => SearchBookingRiderPage.show(context),
          ),
        ),
      ],
    );
  }
}

class _MyRideBookingItemCard extends StatelessWidget {
  final RiderBookingEntity booking;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _MyRideBookingItemCard({
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = booking.status == RiderBookingStatus.confirmed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1CDD).withOpacity(0.05),
            blurRadius: 14,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Driver & Status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEDE8FF),
                      child: Text(
                        booking.driverName.isNotEmpty
                            ? booking.driverName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Color(0xFF5D24F7),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  booking.driverName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF140D43),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (booking.driverRating > 0) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFFB800),
                                ),
                                Text(
                                  '${booking.driverRating}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (booking.driverPhone.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              booking.driverPhone,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ] else if (booking.vehicle.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              booking.vehicleNumber != null &&
                                      booking.vehicleNumber!.isNotEmpty
                                  ? '${booking.vehicle} • ${booking.vehicleNumber}'
                                  : booking.vehicle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CarpoolFormatters.rupee(booking.totalAmount),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D24F7),
                          ),
                        ),
                        Text(
                          '${booking.seatsBooked} seat(s)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B85A8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Route summary box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDE8FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trip_origin_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${booking.from} → ${booking.to}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Date & Time + Action Buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Color(0xFF5D24F7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CarpoolFormatters.shortDateTime(booking.departure),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF140D43),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (booking.otpCode != null &&
                        booking.otpCode!.isNotEmpty &&
                        isConfirmed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OTP: ${booking.otpCode}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5D24F7),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (booking.driverPhone.isNotEmpty) ...[
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: booking.driverPhone),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Driver phone copied: ${booking.driverPhone}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: Color(0xFF5D24F7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Call',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5D24F7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (isConfirmed)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        onPressed: isCancelling ? null : onCancel,
                        child: isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFDC2626),
                                ),
                              )
                            : const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: booking.status == RiderBookingStatus.completed
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status == RiderBookingStatus.completed
                              ? 'Completed'
                              : 'Cancelled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: booking.status ==
                                    RiderBookingStatus.completed
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
