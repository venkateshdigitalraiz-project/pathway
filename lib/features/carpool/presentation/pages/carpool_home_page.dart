import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_colors.dart';
import 'package:pathway/core/utils/carpool_formatters.dart';
import 'package:pathway/core/utils/carpool_status.dart';

import '../../data/datasources/carpool_mock_data_source.dart';
import '../../data/repositories/carpool_repository_impl.dart';
import '../../domain/usecases/accept_booking_usecase.dart';
import '../../domain/usecases/carpool_usecases.dart';
import '../../domain/usecases/reject_booking_usecase.dart';
import '../bloc/carpool_find_ride_bloc.dart';
import '../bloc/carpool_home_bloc.dart';
import '../bloc/carpool_nav_cubit.dart';
import 'carpool_find_ride_page.dart';
import 'carpool_offer_ride_page.dart';
import 'carpool_publish_ride_page.dart';
import 'start_ride_page.dart';
import '../../domain/entities/available_rider_entity.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/start_ride_entity.dart';

// Carpool Home Page – exact 1:1 match with the target UI design:
// 1. Top bar: Hamburger menu (3 horizontal rounded bars) & Notification bell with '2' badge.
// 2. Header: "Hello,\nVenkatesh 👋" & "Where do you want to go?" with top-right skyline illustration.
// 3. Action Cards: "Carpool" (Royal Purple with 3D sleek front car) & "Courier" (Golden Orange with 3D isometric parcel box).
// 4. "Go Green - Reduce Carbon Footprint" silky mint-lime gradient banner with 3D Earth Globe & glossy sprouting leaves.
// 5. "Popular Routes" section with "See All →" and white rounded card with royal blue location pins & prices in INR.
class CarpoolHomePage extends StatelessWidget {
  const CarpoolHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<CarpoolHomeBloc>();
      return const _CarpoolHomeView();
    } catch (_) {
      final remoteDataSource = CarpoolMockDataSource();
      final repository = CarpoolRepositoryImpl(remoteDataSource);
      return MultiBlocProvider(
        providers: [
          BlocProvider<CarpoolHomeBloc>(
            create: (_) => CarpoolHomeBloc(
              getUser: CarpoolGetUserUseCase(repository),
              getPopularRoutes: CarpoolGetPopularRoutesUseCase(repository),
              acceptBooking: AcceptBookingUseCase(repository),
              rejectBooking: RejectBookingUseCase(repository),
            )..add(const CarpoolHomeStarted()),
          ),
          BlocProvider<CarpoolFindRideBloc>(
            create: (_) => CarpoolFindRideBloc(
              searchRides: CarpoolSearchRidesUseCase(repository),
              bookRide: CarpoolBookRideUseCase(repository),
            ),
          ),
        ],
        child: const _CarpoolHomeView(),
      );
    }
  }
}

class _CarpoolHomeView extends StatelessWidget {
  const _CarpoolHomeView();

  void _openFindRide(
    BuildContext context, {
    String? from,
    String? to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) {
    final bloc = context.read<CarpoolFindRideBloc>();
    final f = from ?? bloc.state.from;
    final t = to ?? bloc.state.to;
    bloc.add(
      CarpoolFindRideRouteSelected(
        f,
        t,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      ),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CarpoolFindRidePage()));
  }

  void _openPublishRide(BuildContext context) {
    CarpoolPublishRidePage.show(context);
  }

  void _openOfferRide(BuildContext context) {
    CarpoolHomeBloc? homeBloc;
    CarpoolNavCubit? navCubit;

    try {
      homeBloc = context.read<CarpoolHomeBloc>();
    } catch (_) {}
    try {
      navCubit = context.read<CarpoolNavCubit>();
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            if (homeBloc != null) BlocProvider.value(value: homeBloc),
            if (navCubit != null) BlocProvider.value(value: navCubit),
          ],
          child: const CarpoolOfferRidePage(),
        ),
      ),
    );
  }

  void _handleAcceptBooking(
    BuildContext context,
    AvailableRiderEntity booking,
  ) {
    final ride = CarpoolRideEntity(
      id: booking.rideId,
      driverName: 'Driver',
      driverRating: 4.9,
      driverTrips: 120,
      vehicle:
          '${booking.vehicleModel ?? "Sedan"} • ${booking.vehicleNumber ?? "GVJVHCY"}',
      vehicleModel: booking.vehicleModel ?? 'Hgigih',
      vehicleNumber: booking.vehicleNumber ?? 'GVJVHCY',
      from: booking.fromAddress,
      to: booking.toAddress,
      departure: DateTime.now(),
      seats: booking.seatsBooked,
      pricePerSeat: booking.totalAmount,
      distanceKm: booking.distanceKm.toInt(),
      status: CarpoolRideStatus.upcoming,
      rideType: CarpoolRideType.normal,
    );

    final passenger = StartRidePassengerEntity(
      id: booking.passengerId,
      name: booking.riderName,
      phone: booking.riderPhone,
      rating: booking.rating,
      totalRides: booking.totalRides,
      pickupLocation: booking.fromAddress,
      dropoffLocation: booking.toAddress,
      distanceToPassengerKm: booking.distanceKm,
      etaToPassengerMin: booking.etaMin,
      journeyDistanceKm: 12.5,
      journeyEtaMin: 25,
      passengerCount: booking.seatsBooked,
    );

    StartRidePage.show(context, ride: ride, passenger: passenger);
  }

  void _showDeclineBookingDialog(
    BuildContext context,
    AvailableRiderEntity booking,
  ) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Decline Ride Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF140D43),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for declining ${booking.riderName}\'s ride request:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B658C),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Vehicle maintenance issue, unable to accommodate passenger',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF5D24F7), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogCtx);
              context.read<CarpoolHomeBloc>().add(
                    CarpoolHomeRejectBookingRequested(
                      bookingId: booking.bookingId,
                      reason: reason.isNotEmpty
                          ? reason
                          : 'Vehicle maintenance issue, unable to accommodate passenger',
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
            colors: [Color(0xFFEDE8FF), Color(0xFFF7F5FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient soft purple wave in bottom right
            Positioned(
              right: -30,
              bottom: 20,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFDED6FD).withOpacity(0.50),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 1. Background City Skyline Image across the wishes / greeting header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 255,
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.74, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/carpool_home_bg.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) =>
                        const CustomPaint(painter: _CitySkylineArtPainter()),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Content
            SafeArea(
              bottom: false,
              child: BlocConsumer<CarpoolHomeBloc, CarpoolHomeState>(
                listenWhen: (prev, curr) =>
                    (curr.error != null && curr.error != prev.error) ||
                    (curr.message != null && curr.message != prev.message) ||
                    (curr.acceptedBooking != null &&
                        curr.acceptedBooking != prev.acceptedBooking),
                listener: (context, state) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }

                  if (state.message != null) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message!),
                        backgroundColor: const Color(0xFF475569),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }

                  if (state.acceptedBooking != null &&
                      state.acceptedRider != null) {
                    final acceptedBooking = state.acceptedBooking!;
                    final acceptedRider = state.acceptedRider!;

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(acceptedBooking.message.isNotEmpty
                            ? acceptedBooking.message
                            : 'Booking accepted successfully!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    final ride = CarpoolRideEntity(
                      id: acceptedBooking.rideId.isNotEmpty
                          ? acceptedBooking.rideId
                          : acceptedRider.rideId,
                      driverName: state.user?.name ?? 'Driver',
                      driverRating: 4.9,
                      driverTrips: 120,
                      vehicle:
                          '${acceptedRider.vehicleModel ?? "Sedan"} • ${acceptedRider.vehicleNumber ?? "GVJVHCY"}',
                      vehicleModel: acceptedRider.vehicleModel ?? 'Hgigih',
                      vehicleNumber: acceptedRider.vehicleNumber ?? 'GVJVHCY',
                      from: acceptedRider.fromAddress,
                      to: acceptedRider.toAddress,
                      departure: DateTime.now(),
                      seats: acceptedBooking.seatsBooked,
                      pricePerSeat: acceptedBooking.totalAmount,
                      distanceKm: acceptedRider.distanceKm.toInt(),
                      status: CarpoolRideStatus.upcoming,
                      rideType: CarpoolRideType.normal,
                      rideCode: acceptedBooking.bookingCode,
                    );

                    final passenger = StartRidePassengerEntity(
                      id: acceptedBooking.passengerId.isNotEmpty
                          ? acceptedBooking.passengerId
                          : acceptedRider.passengerId,
                      name: acceptedRider.riderName,
                      phone: acceptedRider.riderPhone,
                      rating: acceptedRider.rating,
                      totalRides: acceptedRider.totalRides,
                      pickupLocation: acceptedRider.fromAddress,
                      dropoffLocation: acceptedRider.toAddress,
                      distanceToPassengerKm: acceptedRider.distanceKm,
                      etaToPassengerMin: acceptedRider.etaMin,
                      journeyDistanceKm: 12.5,
                      journeyEtaMin: 25,
                      passengerCount: acceptedBooking.seatsBooked,
                    );

                    context
                        .read<CarpoolHomeBloc>()
                        .add(const CarpoolHomeClearAcceptedBooking());
                    StartRidePage.show(context, ride: ride, passenger: passenger);
                  }
                },
                builder: (context, state) {
                  final userName = state.user?.name.isNotEmpty == true
                      ? state.user!.name
                      : 'Venkatesh';

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Top Bar: Back Arrow & Notification Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Arrow icon for backpress
                          GestureDetector(
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).maybePop();
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 2,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 24,
                                color: Color(0xFF140D43),
                              ),
                            ),
                          ),

                          // Notification bell with red '2' badge
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('2 unread notifications'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 28,
                                    color: Color(0xFF140D43),
                                  ),
                                  Positioned(
                                    right: -3,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 17,
                                        minHeight: 17,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '2',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Greeting: "Hello,\nVenkatesh 👋"
                      const Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF140D43),
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF140D43),
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          color: Color(0xFF1E174E),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Two Mode Action Cards: Carpool & Courier
                      Row(
                        children: [
                          // Carpool Card (Deep Purple with 3D sleek car)
                          Expanded(
                            child: _CarpoolActionCard(
                              onTap: () => _openPublishRide(context),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Offer Ride Card (Golden Orange with 3D Searching Glass)
                          Expanded(
                            child: _CourierActionCard(
                              onTap: () => _openOfferRide(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // "Go Green - Reduce Carbon Footprint" Banner
                      const _GoGreenBanner(),

                      const SizedBox(height: 22),

                      // Available Rider Header with Online/Offline Slide Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Availible Rider',
                            style: TextStyle(
                              fontSize: 19.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                              letterSpacing: -0.2,
                            ),
                          ),
                          _OnlineOfflineSlideSwitch(
                            isOnline: state.isOnline,
                            onChanged: (val) {
                              context
                                  .read<CarpoolHomeBloc>()
                                  .add(CarpoolHomeToggleOnlineOffline(val));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Live User Event Raised from User Side (BOOKING_CREATED)
                      if (!state.isOnline)
                        _OfflineStateBanner(
                          onGoOnline: () {
                            context
                                .read<CarpoolHomeBloc>()
                                .add(const CarpoolHomeToggleOnlineOffline(true));
                          },
                        )
                      else if (state.availableBookings.isNotEmpty)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.availableBookings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final booking = state.availableBookings[index];
                            final isAccepting =
                                state.acceptingBookingId == booking.bookingId;
                            final isRejecting =
                                state.rejectingBookingId == booking.bookingId;
                            return _AvailableRiderCard(
                              booking: booking,
                              isAccepting: isAccepting,
                              isRejecting: isRejecting,
                              onAccept: () {
                                context.read<CarpoolHomeBloc>().add(
                                      CarpoolHomeAcceptBookingRequested(booking),
                                    );
                              },
                              onDismiss: () =>
                                  _showDeclineBookingDialog(context, booking),
                            );
                          },
                        )
                      else
                        const _ListeningForRidersCard(),

                      const SizedBox(height: 22),

                      // Popular Routes Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Routes',
                            style: TextStyle(
                              fontSize: 19.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openFindRide(context),
                            behavior: HitTestBehavior.opaque,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF3815D8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF3815D8),
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Popular Routes Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEDE8FF),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B3BF5).withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: state.status == CarpoolStatus.loading
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF3815D8),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < state.routes.length;
                                    i++
                                  ) ...[
                                    InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _openFindRide(
                                        context,
                                        from: state.routes[i].from,
                                        to: state.routes[i].to,
                                        fromLat: state.routes[i].fromLat,
                                        fromLng: state.routes[i].fromLng,
                                        toLat: state.routes[i].toLat,
                                        toLng: state.routes[i].toLng,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              color: Color(0xFF3815D8),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                '${state.routes[i].from} → ${state.routes[i].to}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                  color: Color(0xFF140D43),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              CarpoolFormatters.rupee(
                                                state.routes[i].price,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: Color(0xFF140D43),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i != state.routes.length - 1)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFF1EEFC),
                                      ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carpool Action Card with rich royal purple gradient & custom 3D car silhouette
class _CarpoolActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CarpoolActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 172,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3815D8).withOpacity(0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Front Car Silhouette matching design
            const SizedBox(
              width: 58,
              height: 48,
              child: CustomPaint(painter: _FrontCarArtPainter()),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carpool',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publish Ride',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Courier Action Card with warm golden-orange gradient & 3D isometric parcel box
class _CourierActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CourierActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 172,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB300), Color(0xFFFF9100), Color(0xFFFF6D00)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A00).withOpacity(0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Isometric Cardboard Box
            const SizedBox(
              width: 58,
              height: 48,
              child: CustomPaint(painter: _IsometricParcelBoxPainter()),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offer Ride',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Offer a Ride',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fresh mint-lime "Go Green" banner with 3D Globe & Sprouting leaves
class _GoGreenBanner extends StatelessWidget {
  const _GoGreenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        gradient: AppColors.goGreenGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Text on the left
          const Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            right: 130,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Green',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F3811),
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Reduce Carbon Footprint',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          // Earth image fitting card right side with full height
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/earth.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 72,
                child: CustomPaint(painter: _GoGreenGlobeLeavesPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Front Car Art Painter matching the exact sleek white vehicle in the design
class _FrontCarArtPainter extends CustomPainter {
  const _FrontCarArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = const Color(0xFF1A0A7A)
      ..style = PaintingStyle.fill;

    // 1. Car Cabin & Windshield Roof
    final cabinPath = Path();
    cabinPath.moveTo(w * 0.22, h * 0.45);
    cabinPath.quadraticBezierTo(w * 0.26, h * 0.14, w * 0.38, h * 0.12);
    cabinPath.lineTo(w * 0.62, h * 0.12);
    cabinPath.quadraticBezierTo(w * 0.74, h * 0.14, w * 0.78, h * 0.45);
    cabinPath.close();
    canvas.drawPath(cabinPath, paintWhite);

    // Windshield glass (subtle purple/blue dark tint)
    final glassPath = Path();
    glassPath.moveTo(w * 0.26, h * 0.43);
    glassPath.quadraticBezierTo(w * 0.30, h * 0.18, w * 0.40, h * 0.16);
    glassPath.lineTo(w * 0.60, h * 0.16);
    glassPath.quadraticBezierTo(w * 0.70, h * 0.18, w * 0.74, h * 0.43);
    glassPath.close();
    canvas.drawPath(glassPath, paintDark);

    // Windshield reflection shine
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final shinePath = Path();
    shinePath.moveTo(w * 0.34, h * 0.42);
    shinePath.lineTo(w * 0.44, h * 0.17);
    shinePath.lineTo(w * 0.49, h * 0.17);
    shinePath.lineTo(w * 0.39, h * 0.42);
    shinePath.close();
    canvas.drawPath(shinePath, shinePaint);

    // 2. Car Hood & Body
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.10, h * 0.42, w * 0.80, h * 0.42),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, paintWhite);

    // Side mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.09, h * 0.12),
        const Radius.circular(3),
      ),
      paintWhite,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.87, h * 0.38, w * 0.09, h * 0.12),
        const Radius.circular(3),
      ),
      paintWhite,
    );

    // 3. Headlights (Oval glowing lights)
    final paintLight = Paint()
      ..color = const Color(0xFF240DA2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.54),
        width: w * 0.13,
        height: h * 0.12,
      ),
      paintLight,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.54),
        width: w * 0.13,
        height: h * 0.12,
      ),
      paintLight,
    );

    // Front center grille slot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.68),
          width: w * 0.36,
          height: h * 0.08,
        ),
        const Radius.circular(3),
      ),
      paintLight,
    );

    // Front lower intake & bumper tires
    final tirePaint = Paint()
      ..color = const Color(0xFF130663)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.12, h * 0.80, w * 0.12, h * 0.12),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.76, h * 0.80, w * 0.12, h * 0.12),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      tirePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Isometric Searching Magnifying Glass for Carpool Search Ride Card
class _IsometricParcelBoxPainter extends CustomPainter {
  const _IsometricParcelBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft blurred drop shadow underneath the magnifying glass
    final shadowPaint = Paint()
      ..color = const Color(0xFFBF360C).withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Lens shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, h * 0.46),
        width: w * 0.54,
        height: h * 0.52,
      ),
      shadowPaint,
    );

    // Handle shadow
    final handleShadowPaint = Paint()
      ..color = const Color(0xFFBF360C).withOpacity(0.30)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(
      Offset(w * 0.62, h * 0.62),
      Offset(w * 0.88, h * 0.88),
      handleShadowPaint,
    );

    // 2. Angled 3D Handle
    // Handle rear 3D depth rim
    final handleDepthPaint = Paint()
      ..color = const Color(0xFFE65100)
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.59, h * 0.59),
      Offset(w * 0.86, h * 0.86),
      handleDepthPaint,
    );

    // Main glossy white handle
    final handlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.58, h * 0.58),
      Offset(w * 0.85, h * 0.85),
      handlePaint,
    );

    // Golden metallic connector collar between rim and handle
    final collarPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.54, h * 0.54),
      Offset(w * 0.61, h * 0.61),
      collarPaint,
    );

    // 3. Magnifying Glass Lens
    final lensCenter = Offset(w * 0.38, h * 0.38);
    final lensRadius = w * 0.26;

    // Translucent glass fill with subtle light blue/white glow
    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lensCenter, lensRadius, glassPaint);

    final glassFrostPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withOpacity(0.32)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lensCenter, lensRadius - 1.5, glassFrostPaint);

    // Outer 3D bevel / rim shadow
    final rimBevelPaint = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.50)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(lensCenter.dx + 1.2, lensCenter.dy + 1.2),
      lensRadius,
      rimBevelPaint,
    );

    // Main crisp white outer circular rim
    final rimPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(lensCenter, lensRadius, rimPaint);

    // Inner rim accent ring
    final innerRimPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(lensCenter, lensRadius - 2.4, innerRimPaint);

    // 4. Glossy Lens Glare / Reflection (curved top-left arc)
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shineRect = Rect.fromCircle(
      center: lensCenter,
      radius: lensRadius - 4.5,
    );
    canvas.drawArc(shineRect, -2.6, 1.5, false, shinePaint);

    // Secondary soft reflection sparkle dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(lensCenter.dx + 4.5, lensCenter.dy + 4.5),
      1.6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Earth Globe with Glossy Sprouting Leaves for the Go Green Banner
class _GoGreenGlobeLeavesPainter extends CustomPainter {
  const _GoGreenGlobeLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final globeCenter = Offset(w * 0.60, h * 0.46);
    final radius = w * 0.36;

    // Globe ocean background with spherical 3D lighting
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        colors: const [
          Color(0xFF81D4FA),
          Color(0xFF29B6F6),
          Color(0xFF0288D1),
          Color(0xFF01579B),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: radius));

    canvas.drawCircle(globeCenter, radius, oceanPaint);

    // Clip to globe circle for continents
    canvas.save();
    final globePath = Path()
      ..addOval(Rect.fromCircle(center: globeCenter, radius: radius));
    canvas.clipPath(globePath);

    // Continents (emerald & bright lime green)
    final continentPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    // North America / Europe shape
    final c1 = Path()
      ..moveTo(globeCenter.dx - radius * 0.6, globeCenter.dy - radius * 0.4)
      ..quadraticBezierTo(
        globeCenter.dx - radius * 0.2,
        globeCenter.dy - radius * 0.8,
        globeCenter.dx + radius * 0.2,
        globeCenter.dy - radius * 0.5,
      )
      ..lineTo(globeCenter.dx + radius * 0.4, globeCenter.dy - radius * 0.1)
      ..quadraticBezierTo(
        globeCenter.dx - radius * 0.1,
        globeCenter.dy + radius * 0.1,
        globeCenter.dx - radius * 0.6,
        globeCenter.dy - radius * 0.4,
      );
    canvas.drawPath(c1, continentPaint);

    // Asia / India / Africa shape
    final c2 = Path()
      ..moveTo(globeCenter.dx - radius * 0.1, globeCenter.dy + radius * 0.1)
      ..quadraticBezierTo(
        globeCenter.dx + radius * 0.6,
        globeCenter.dy - radius * 0.1,
        globeCenter.dx + radius * 0.8,
        globeCenter.dy + radius * 0.4,
      )
      ..quadraticBezierTo(
        globeCenter.dx + radius * 0.3,
        globeCenter.dy + radius * 0.8,
        globeCenter.dx - radius * 0.1,
        globeCenter.dy + radius * 0.6,
      )
      ..close();
    canvas.drawPath(c2, continentPaint);

    // Specular glossy reflection on top of the globe
    final glossPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.55),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromLTWH(
              globeCenter.dx - radius,
              globeCenter.dy - radius,
              radius * 2,
              radius,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(globeCenter.dx, globeCenter.dy - radius * 0.4),
        width: radius * 1.5,
        height: radius * 0.8,
      ),
      glossPaint,
    );

    canvas.restore();

    // Sprouting glossy green leaves on the left of the globe
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
      ).createShader(Rect.fromLTWH(0, h * 0.30, w * 0.45, h * 0.65));

    // Leaf 1: pointing up-left
    final leaf1 = Path()
      ..moveTo(w * 0.32, h * 0.65)
      ..quadraticBezierTo(w * 0.05, h * 0.50, w * 0.05, h * 0.35)
      ..quadraticBezierTo(w * 0.28, h * 0.30, w * 0.32, h * 0.65)
      ..close();
    canvas.drawPath(leaf1, leafPaint);

    // Leaf 1 vein
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.08, h * 0.38),
      veinPaint,
    );

    // Leaf 2: pointing lower-left
    final leaf2 = Path()
      ..moveTo(w * 0.35, h * 0.70)
      ..quadraticBezierTo(w * 0.12, h * 0.72, w * 0.15, h * 0.88)
      ..quadraticBezierTo(w * 0.35, h * 0.90, w * 0.35, h * 0.70)
      ..close();
    canvas.drawPath(leaf2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rich City Skyline Illustration for the top-right header background
class _CitySkylineArtPainter extends CustomPainter {
  const _CitySkylineArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft sky gradient glow in upper background
    final skyGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.6),
        radius: 1.2,
        colors: [
          const Color(0xFFFFCCBC).withOpacity(0.35),
          const Color(0xFFD1C4E9).withOpacity(0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyGlow);

    // Tower colors in rich blue/violet atmospheric haze
    final towerPaintFar = Paint()
      ..color = const Color(0xFF9FA8DA).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final towerPaintMid = Paint()
      ..color = const Color(0xFF7986CB).withOpacity(0.50)
      ..style = PaintingStyle.fill;

    final towerPaintNear = Paint()
      ..color = const Color(0xFF5C6BC0).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Window grid dots & lines
    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 1. Far background towers
    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, h * 0.38, 22, h * 0.50),
      towerPaintFar,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.32, h * 0.25, 26, h * 0.60),
      towerPaintFar,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.85, h * 0.30, 24, h * 0.60),
      towerPaintFar,
    );

    // 2. Mid towers
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.48, h * 0.18, 30, h * 0.70),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      towerPaintMid,
    );

    // Spire on center tower
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48 + 13, h * 0.06, 3.5, h * 0.12),
      towerPaintMid,
    );
    // Beacon light at spire tip
    canvas.drawCircle(
      Offset(w * 0.48 + 14.7, h * 0.06),
      2.5,
      Paint()..color = const Color(0xFFFF5252),
    );

    // Windows on mid tower
    for (double y = h * 0.22; y < h * 0.75; y += 12) {
      canvas.drawLine(Offset(w * 0.51, y), Offset(w * 0.55, y), windowPaint);
      canvas.drawLine(Offset(w * 0.60, y), Offset(w * 0.64, y), windowPaint);
    }

    // 3. Tall primary skyscraper (Right-Center)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.68, h * 0.12, 34, h * 0.78),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      towerPaintNear,
    );

    // Tall spire
    canvas.drawRect(
      Rect.fromLTWH(w * 0.68 + 15, h * 0.03, 4, h * 0.09),
      towerPaintNear,
    );
    canvas.drawCircle(
      Offset(w * 0.68 + 17, h * 0.03),
      3,
      Paint()..color = const Color(0xFFFF1744),
    );

    // Windows on primary skyscraper
    for (double y = h * 0.16; y < h * 0.80; y += 10) {
      canvas.drawLine(Offset(w * 0.71, y), Offset(w * 0.78, y), windowPaint);
      canvas.drawLine(Offset(w * 0.81, y), Offset(w * 0.88, y), windowPaint);
    }

    // 4. Lush rolling green treetops at the base of the skyline
    final treePaintBack = Paint()
      ..color = const Color(0xFF43A047).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final treePaintFront = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.70)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.25, h * 0.86), 28, treePaintBack);
    canvas.drawCircle(Offset(w * 0.48, h * 0.84), 34, treePaintBack);
    canvas.drawCircle(Offset(w * 0.75, h * 0.82), 36, treePaintBack);
    canvas.drawCircle(Offset(w * 0.95, h * 0.84), 30, treePaintBack);

    canvas.drawCircle(Offset(w * 0.36, h * 0.90), 32, treePaintFront);
    canvas.drawCircle(Offset(w * 0.62, h * 0.88), 38, treePaintFront);
    canvas.drawCircle(Offset(w * 0.88, h * 0.89), 34, treePaintFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A modern, smooth slide switch for toggling Driver/Rider Online & Offline status
class _OnlineOfflineSlideSwitch extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _OnlineOfflineSlideSwitch({
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        width: 104,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isOnline
              ? const LinearGradient(
                  colors: [Color(0xFFE8FDF3), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isOnline ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? const Color(0xFF10B981).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Status text & indicator dot
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              alignment: isOnline ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isOnline ? 9 : 0,
                  right: isOnline ? 0 : 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                        boxShadow: isOnline
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isOnline
                            ? const Color(0xFF047857)
                            : const Color(0xFF475569),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sliding knob
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isOnline
                          ? const Color(0xFF059669).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.16),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isOnline
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    size: 14.5,
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying a live rider booking raised via socket `BOOKING_CREATED`
class _AvailableRiderCard extends StatelessWidget {
  final AvailableRiderEntity booking;
  final bool isAccepting;
  final bool isRejecting;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _AvailableRiderCard({
    required this.booking,
    this.isAccepting = false,
    this.isRejecting = false,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: booking.isNew
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: booking.isNew ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF140D43).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Rider Name, Rating & Price
          Row(
            children: [
              // Avatar Circle
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    booking.riderName.isNotEmpty
                        ? booking.riderName.substring(0, 1).toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Rider Name & Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            booking.riderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF140D43),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (booking.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${booking.rating.toStringAsFixed(1)} (${booking.totalRides} rides)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Fare & Seats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${booking.totalAmount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4F46E5),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${booking.seatsBooked} ${booking.seatsBooked > 1 ? "Seats" : "Seat"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Route Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icons column (Purple origin dot, connecting line, Red destination pin)
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF5025D1),
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 22,
                    color: const Color(0xFFCBD5E1),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Addresses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.fromAddress,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      booking.toAddress,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Distance & ETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 11,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.distanceKm} km',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${booking.etaMin} min away',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons: Decline & Accept Ride
          Row(
            children: [
              // Decline
              InkWell(
                onTap: (isAccepting || isRejecting) ? null : onDismiss,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: isRejecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF64748B)),
                          ),
                        )
                      : const Text(
                          'Decline',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 10),

              // Accept & Start Ride
              Expanded(
                child: InkWell(
                  onTap: isAccepting ? null : onAccept,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5025D1), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5025D1).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isAccepting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Accept Ride',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Offline status banner shown when driver is offline
class _OfflineStateBanner extends StatelessWidget {
  final VoidCallback onGoOnline;

  const _OfflineStateBanner({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_off_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are currently Offline',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Switch to Online to receive live rider bookings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: onGoOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go Online',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Active listening card when online and waiting for new BOOKING_CREATED events
class _ListeningForRidersCard extends StatelessWidget {
  const _ListeningForRidersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.radar_rounded,
                color: Color(0xFF6D28D9),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listening for Rider Bookings...',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4C1D95),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'New ride requests from users will appear here in real time.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
