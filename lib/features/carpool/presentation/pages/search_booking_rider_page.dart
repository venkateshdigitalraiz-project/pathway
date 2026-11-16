import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import '../../../../core/utils/carpool_formatters.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/repositories/search_booking_rider_repository_impl.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';
import '../bloc/search_booking_rider_bloc.dart';
import 'search_booking_details_page.dart';

/// Aliases to support exact user naming conventions
typedef searchBookingrider = SearchBookingRiderPage;
typedef SearchBookingRider = SearchBookingRiderPage;

/// Clean Architecture Search & Booking Rider Page
class SearchBookingRiderPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final repo = SearchBookingRiderRepositoryImpl();
    final hasInitialQuery =
        (initialOriginCity != null && initialOriginCity!.isNotEmpty) ||
        (initialDestinationCity != null && initialDestinationCity!.isNotEmpty);

    return BlocProvider<SearchBookingRiderBloc>(
      create: (_) {
        final bloc = SearchBookingRiderBloc(
          getBookings: GetRiderBookingsUseCase(repo),
          searchRides: SearchRiderRidesUseCase(repo),
          bookSeat: BookRiderSeatUseCase(repo),
          cancelBooking: CancelRiderBookingUseCase(repo),
        );
        bloc.add(const SearchBookingRiderStarted());
        if (hasInitialQuery) {
          bloc.add(const SearchBookingRiderTabChanged(1));
          bloc.add(
            SearchBookingRiderSearchRequested(
              from: initialOriginCity ?? '',
              to: initialDestinationCity ?? '',
              originLat: initialOriginLat,
              originLng: initialOriginLng,
              destinationLat: initialDestinationLat,
              destinationLng: initialDestinationLng,
              date: initialDate ?? DateTime.now(),
              seats: initialSeats ?? 1,
              radiusKm: initialRadiusKm ?? 30,
            ),
          );
        }
        return bloc;
      },
      child: _SearchBookingRiderView(
        initialOrigin: initialOriginCity,
        initialDestination: initialDestinationCity,
        initialOriginLat: initialOriginLat,
        initialOriginLng: initialOriginLng,
        initialDestinationLat: initialDestinationLat,
        initialDestinationLng: initialDestinationLng,
        initialDate: initialDate,
        initialSeats: initialSeats,
        initialRadiusKm: initialRadiusKm,
      ),
    );
  }
}

class _SearchBookingRiderView extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final double? initialOriginLat;
  final double? initialOriginLng;
  final double? initialDestinationLat;
  final double? initialDestinationLng;
  final DateTime? initialDate;
  final int? initialSeats;
  final int? initialRadiusKm;

  const _SearchBookingRiderView({
    this.initialOrigin,
    this.initialDestination,
    this.initialOriginLat,
    this.initialOriginLng,
    this.initialDestinationLat,
    this.initialDestinationLng,
    this.initialDate,
    this.initialSeats,
    this.initialRadiusKm,
  });

  @override
  State<_SearchBookingRiderView> createState() =>
      _SearchBookingRiderViewState();
}

class _SearchBookingRiderViewState extends State<_SearchBookingRiderView> {
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  // 0: Active, 1: Past

  @override
  void initState() {
    super.initState();
    _fromCtrl = TextEditingController(
      text: widget.initialOrigin?.isNotEmpty == true
          ? widget.initialOrigin!
          : '',
    );
    _toCtrl = TextEditingController(
      text: widget.initialDestination?.isNotEmpty == true
          ? widget.initialDestination!
          : '',
    );
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF5D24F7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Future<void> _pickDate() async {
  //   final now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
  //     firstDate: now,
  //     lastDate: now.add(const Duration(days: 30)),
  //     builder: (context, child) => Theme(
  //       data: Theme.of(context).copyWith(
  //         colorScheme: const ColorScheme.light(
  //           primary: Color(0xFF5D24F7),
  //           onPrimary: Colors.white,
  //           onSurface: Color(0xFF140D43),
  //         ),
  //       ),
  //       child: child!,
  //     ),
  //   );
  //   if (picked != null) {
  //     setState(() => _selectedDate = picked);
  //   }
  // }

  // void _onSearch(BuildContext context) {
  //   final fromText = _fromCtrl.text.trim();
  //   final toText = _toCtrl.text.trim();
  //   if (fromText.isEmpty || toText.isEmpty) {
  //     _snack(context, 'Please enter pickup and dropoff points', isError: true);
  //     return;
  //   }

  //   final originCoords = CarpoolDistanceCalculator.resolveCoordinates(
  //     fromText,
  //     preferredLat: _originLat,
  //     preferredLng: _originLng,
  //   );
  //   final destCoords = CarpoolDistanceCalculator.resolveCoordinates(
  //     toText,
  //     preferredLat: _destinationLat,
  //     preferredLng: _destinationLng,
  //   );

  //   _originLat = originCoords.lat;
  //   _originLng = originCoords.lng;
  //   _destinationLat = destCoords.lat;
  //   _destinationLng = destCoords.lng;

  //   context.read<SearchBookingRiderBloc>().add(
  //     SearchBookingRiderSearchRequested(
  //       from: fromText,
  //       to: toText,
  //       originLat: originCoords.lat,
  //       originLng: originCoords.lng,
  //       destinationLat: destCoords.lat,
  //       destinationLng: destCoords.lng,
  //       date: _selectedDate,
  //       seats: _seats,
  //       radiusKm: _radiusKm,
  //     ),
  //   );
  // }

  // void _confirmCancelBooking(
  //   BuildContext context,
  //   RiderBookingEntity booking,
  // ) async {
  //   final ok = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  //       title: const Text(
  //         'Cancel This Booking?',
  //         style: TextStyle(
  //           fontWeight: FontWeight.w800,
  //           color: Color(0xFF140D43),
  //           fontSize: 18,
  //         ),
  //       ),
  //       content: Text(
  //         'Are you sure you want to cancel your seat from ${booking.from} to ${booking.to}?',
  //         style: const TextStyle(color: Color(0xFF6B658C), fontSize: 14),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx, false),
  //           child: const Text(
  //             'Keep Booking',
  //             style: TextStyle(color: Color(0xFF6B658C)),
  //           ),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: const Color(0xFFEF4444),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //           onPressed: () => Navigator.pop(ctx, true),
  //           child: const Text(
  //             'Yes, Cancel',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w700,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (ok == true && context.mounted) {
  //     context.read<SearchBookingRiderBloc>().add(
  //       SearchBookingRiderCancelBookingRequested(booking.id),
  //     );
  //   }
  // }

  void _showBookSeatDialog(BuildContext context, CarpoolRideEntity ride) {
    final bloc = context.read<SearchBookingRiderBloc>();
    int selectedSeats = 1;
    final notesController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: bloc,
        child: StatefulBuilder(
          builder: (modalCtx, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              16,
              22,
              24 + MediaQuery.of(modalCtx).viewInsets.bottom,
            ),
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

                  // Driver & Ride Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(
                          0xFF5D24F7,
                        ).withOpacity(0.12),
                        child: Text(
                          ride.driverName.isNotEmpty
                              ? ride.driverName[0].toUpperCase()
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
                                Flexible(
                                  child: Text(
                                    ride.driverName,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF140D43),
                                    ),
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
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.vehicle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B658C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CarpoolFormatters.rupee(ride.pricePerSeat),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5D24F7),
                              ),
                            ),
                            const Text(
                              'per seat',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8B85A8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Route summary box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F8FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDE8FF)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trip_origin_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ride.from,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 6.5,
                            top: 2,
                            bottom: 2,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 1.5,
                              height: 12,
                              color: const Color(0xFFDDD6FE),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF5D24F7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ride.to,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
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

                  // Seat selection & Total Fare
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Seats',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF140D43),
                              ),
                            ),
                            Text(
                              '${ride.seats} available',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: selectedSeats > 1
                                  ? () => setModalState(() => selectedSeats--)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedSeats > 1
                                      ? Colors.white
                                      : const Color(0xFFEBE6FC),
                                  border: Border.all(
                                    color: selectedSeats > 1
                                        ? const Color(0xFF5D24F7)
                                        : const Color(0xFFD4CCF7),
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 18,
                                  color: selectedSeats > 1
                                      ? const Color(0xFF5D24F7)
                                      : const Color(0xFF8B85A8),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                '$selectedSeats',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: selectedSeats < ride.seats
                                  ? () => setModalState(() => selectedSeats++)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selectedSeats < ride.seats
                                      ? const Color(0xFF5D24F7)
                                      : const Color(0xFFEBE6FC),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: selectedSeats < ride.seats
                                      ? Colors.white
                                      : const Color(0xFF8B85A8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Passenger Notes TextField
                  const Text(
                    'Passenger Notes',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF140D43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'e.g. Will reach pickup point 10 mins early.',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E98BD),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF5D24F7),
                          size: 22,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9F8FE),
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
                          color: Color(0xFF5D24F7),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total Fare Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B658C),
                        ),
                      ),
                      Text(
                        CarpoolFormatters.rupee(
                          ride.pricePerSeat * selectedSeats,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5D24F7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Buttons: "Cancel" and "Book"
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4CCF7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6B658C),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D24F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final notes = notesController.text.trim();
                            Navigator.pop(sheetCtx);
                            bloc.add(
                              SearchBookingRiderBookSeatRequested(
                                ride: ride,
                                seats: selectedSeats,
                                pickupPoint: ride.from,
                                dropoffPoint: ride.to,
                                passengerNotes: notes.isNotEmpty ? notes : null,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          label: const Text(
                            'Book',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
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
      ),
    );
  }

  void _showBookingSuccessDialog(
    BuildContext context,
    RiderBookingEntity booking,
  ) {
    final bloc = context.read<SearchBookingRiderBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => BlocProvider.value(
        value: bloc,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF140D43).withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with soft halo
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA7F3D0),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF059669),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF140D43),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your seat with ${booking.driverName} is reserved.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B658C),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                // Booking Clean Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEDE8FF)),
                  ),
                  child: Column(
                    children: [
                      // Route
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: 16,
                              color: Color(0xFF5D24F7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.from} → ${booking.to}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF140D43),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Departure: ${CarpoolFormatters.shortDateTime(booking.departure)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B658C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFEDE8FF)),
                      ),

                      // Quick Specs (Seats, Fare, Driver, Vehicle)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSuccessDetailItem(
                            label: 'Seats Booked',
                            value: '${booking.seatsBooked}',
                            icon: Icons.airline_seat_recline_normal_rounded,
                          ),
                          _buildSuccessDetailItem(
                            label: 'Total Fare',
                            value: CarpoolFormatters.rupee(booking.totalAmount),
                            valueColor: const Color(0xFF5D24F7),
                            icon: Icons.payments_rounded,
                          ),
                          _buildSuccessDetailItem(
                            label: 'Status',
                            value: 'Confirmed',
                            valueColor: const Color(0xFF059669),
                            icon: Icons.verified_rounded,
                          ),
                        ],
                      ),

                      // Passenger Notes if present
                      if (booking.passengerNotes != null &&
                          booking.passengerNotes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEDE8FF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                size: 16,
                                color: Color(0xFF5D24F7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Note: "${booking.passengerNotes}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF4C1CDD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // OTP Code (clean pill)
                      if (booking.otpCode != null &&
                          booking.otpCode!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Start Trip OTP:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5D24F7),
                                ),
                              ),
                              Text(
                                booking.otpCode!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD4CCF7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          bloc.add(const SearchBookingRiderClearLastBooking());
                        },
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Color(0xFF6B658C),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D24F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          bloc.add(const SearchBookingRiderClearLastBooking());
                          bloc.add(const SearchBookingRiderTabChanged(0));
                        },
                        child: const Text(
                          'My Bookings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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

  Widget _buildSuccessDetailItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B85A8)),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF8B85A8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? const Color(0xFF140D43),
          ),
        ),
      ],
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
          child: BlocConsumer<SearchBookingRiderBloc, SearchBookingRiderState>(
            listenWhen: (p, c) =>
                (c.message != null && p.message != c.message) ||
                (c.lastBookedBooking != null &&
                    p.lastBookedBooking != c.lastBookedBooking),
            listener: (context, s) {
              if (s.lastBookedBooking != null) {
                _showBookingSuccessDialog(context, s.lastBookedBooking!);
              } else if (s.message != null) {
                _snack(context, s.message!);
              }
            },
            builder: (context, s) {
              return Column(
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Rider Bookings & Search',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Search rides & manage your passenger bookings',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child:
                        s.status == CarpoolStatus.loading &&
                            s.bookings.isEmpty &&
                            s.searchResults.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D24F7),
                            ),
                          )
                        // : Container(),
                        //  s.tabIndex == 0
                        // ? _buildMyBookingsTab(context, s)
                        : _buildSearchRidesTab(context, s),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget _buildMyBookingsTab(
  //   BuildContext context,
  //   SearchBookingRiderState state,
  // ) {
  //   final list = _bookingSubTab == 0
  //       ? state.activeBookings
  //       : state.pastBookings;

  //   return Column(
  //     children: [
  //       // Sub-filter pill row (Active vs Past)
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //         child: Row(
  //           children: [
  //             _subFilterChip('Active (${state.activeBookingsCount})', 0),
  //             const SizedBox(width: 10),
  //             _subFilterChip('Past (${state.pastBookingsCount})', 1),
  //           ],
  //         ),
  //       ),

  //       // Bookings List or Empty State
  //       Expanded(
  //         child: list.isEmpty
  //             ? _buildEmptyBookingsState(context)
  //             : ListView.separated(
  //                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
  //                 itemCount: list.length,
  //                 separatorBuilder: (_, __) => const SizedBox(height: 14),
  //                 itemBuilder: (context, i) {
  //                   final booking = list[i];
  //                   return _RiderBookingCard(
  //                     booking: booking,
  //                     onCancel: () => _confirmCancelBooking(context, booking),
  //                   );
  //                 },
  //               ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _subFilterChip(String label, int index) {
  //   final isSelected = _bookingSubTab == index;
  //   return GestureDetector(
  //     onTap: () => setState(() => _bookingSubTab = index),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  //       decoration: BoxDecoration(
  //         color: isSelected ? const Color(0xFF5D24F7) : Colors.white,
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(
  //           color: isSelected
  //               ? const Color(0xFF5D24F7)
  //               : const Color(0xFFEDE8FF),
  //         ),
  //       ),
  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           color: isSelected ? Colors.white : const Color(0xFF6B658C),
  //           fontSize: 12.5,
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildEmptyBookingsState(BuildContext context) {
  //   return Center(
  //     child: Padding(
  //       padding: const EdgeInsets.all(32),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 80,
  //             height: 80,
  //             decoration: BoxDecoration(
  //               color: const Color(0xFFEDE8FF),
  //               shape: BoxShape.circle,
  //             ),
  //             child: const Icon(
  //               Icons.confirmation_number_outlined,
  //               color: Color(0xFF5D24F7),
  //               size: 40,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             _bookingSubTab == 0
  //                 ? 'No Active Rider Bookings'
  //                 : 'No Past Bookings',
  //             style: const TextStyle(
  //               fontWeight: FontWeight.w800,
  //               fontSize: 17,
  //               color: Color(0xFF140D43),
  //             ),
  //           ),
  //           const SizedBox(height: 6),
  //           const Text(
  //             'Looking to travel? Switch to Find Rides to search and book seats on available routes.',
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //               color: Color(0xFF6B658C),
  //               fontSize: 13,
  //               height: 1.4,
  //             ),
  //           ),
  //           const SizedBox(height: 18),
  //           ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF5D24F7),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 11,
  //               ),
  //             ),
  //             icon: const Icon(
  //               Icons.search_rounded,
  //               color: Colors.white,
  //               size: 18,
  //             ),
  //             label: const Text(
  //               'Search Available Rides',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w700,
  //               ),
  //             ),
  //             onPressed: () => context.read<SearchBookingRiderBloc>().add(
  //               const SearchBookingRiderTabChanged(1),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSearchRidesTab(
    BuildContext context,
    SearchBookingRiderState state,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Available Rides Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Rides (${state.searchResults.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
              ),
            ),
            const Text(
              'Instant Booking',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search Results List
        if (state.searchResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No rides found for this route. Try adjusting your search points.',
                style: TextStyle(color: Color(0xFF6B658C), fontSize: 13),
              ),
            ),
          )
        else
          ...state.searchResults.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SearchResultCard(
                ride: ride,
                isBooking: state.bookingRideId == ride.id,
                onTap: () async {
                  final booked = await SearchBookingDetailsPage.show(
                    context,
                    rideId: ride.id,
                    initialRide: ride,
                  );
                  if (booked == true && context.mounted) {
                    context.read<SearchBookingRiderBloc>().add(
                      const SearchBookingRiderStarted(),
                    );
                  }
                },
                onBook: () => _showBookSeatDialog(context, ride),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card representing a Rider's Booked Trip
// class _RiderBookingCard extends StatelessWidget {
//   final RiderBookingEntity booking;
//   final VoidCallback onCancel;

//   const _RiderBookingCard({required this.booking, required this.onCancel});

//   @override
//   Widget build(BuildContext context) {
//     final isConfirmed = booking.status == RiderBookingStatus.confirmed;

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF4C1CDD).withOpacity(0.06),
//             blurRadius: 16,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Top Row: Status badge, OTP code, Booking ID
//           Row(
//             children: [
//               _statusBadge(booking.status),
//               const SizedBox(width: 8),
//               if (booking.otpCode != null && isConfirmed)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 9,
//                     vertical: 3.5,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFEDE8FF),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     'OTP: ${booking.otpCode}',
//                     style: const TextStyle(
//                       color: Color(0xFF5D24F7),
//                       fontSize: 11.5,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//               const Spacer(),
//               Text(
//                 '#${booking.id}',
//                 style: const TextStyle(
//                   color: Color(0xFF8B85A8),
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // Date & Time Banner
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF7F5FE),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.calendar_month_rounded,
//                   size: 15,
//                   color: Color(0xFF5D24F7),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   CarpoolFormatters.headline(booking.departure),
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF140D43),
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '${booking.seatsBooked} seat(s)',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF5D24F7),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 12),

//           // Route Timeline
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Column(
//                 children: [
//                   const SizedBox(height: 3),
//                   Container(
//                     width: 12,
//                     height: 12,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xFF10B981),
//                     ),
//                   ),
//                   Container(
//                     width: 2,
//                     height: 26,
//                     color: const Color(0xFFDDD6FE),
//                   ),
//                   Container(
//                     width: 12,
//                     height: 12,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xFFEF4444),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       booking.from,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF140D43),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       booking.to,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF140D43),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // Driver & Vehicle row with Price
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF9F8FE),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 18,
//                   backgroundColor: const Color(0xFFEDE8FF),
//                   child: Text(
//                     booking.driverName.isNotEmpty ? booking.driverName[0] : 'D',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w800,
//                       color: Color(0xFF5D24F7),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         booking.driverName,
//                         style: const TextStyle(
//                           fontSize: 13.5,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF140D43),
//                         ),
//                       ),
//                       Text(
//                         '${booking.vehicle} • ${booking.vehicleNumber ?? ''}',
//                         style: const TextStyle(
//                           fontSize: 11.5,
//                           color: Color(0xFF6B658C),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   CarpoolFormatters.rupee(booking.totalAmount),
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: Color(0xFF5D24F7),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           if (isConfirmed) ...[
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Color(0xFFFCA5A5)),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(18),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                     ),
//                     onPressed: onCancel,
//                     child: const Text(
//                       'Cancel Booking',
//                       style: TextStyle(
//                         color: Color(0xFFEF4444),
//                         fontSize: 12.5,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _statusBadge(RiderBookingStatus status) {
//     Color bg;
//     Color fg;
//     String text;
//     switch (status) {
//       case RiderBookingStatus.confirmed:
//         bg = const Color(0xFFECFDF5);
//         fg = const Color(0xFF059669);
//         text = '● Confirmed';
//         break;
//       case RiderBookingStatus.completed:
//         bg = const Color(0xFFEEF2FF);
//         fg = const Color(0xFF4F46E5);
//         text = '✔ Completed';
//         break;
//       case RiderBookingStatus.cancelled:
//         bg = const Color(0xFFFEF2F2);
//         fg = const Color(0xFFDC2626);
//         text = '✕ Cancelled';
//         break;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: fg,
//           fontSize: 11.5,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
// }

/// Search Result Card for Riders
class _SearchResultCard extends StatelessWidget {
  final CarpoolRideEntity ride;
  final VoidCallback onBook;
  final VoidCallback? onTap;
  final bool isBooking;

  const _SearchResultCard({
    required this.ride,
    required this.onBook,
    this.onTap,
    this.isBooking = false,
  });

  @override
  Widget build(BuildContext context) {
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
                // Driver info & Price
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEDE8FF),
                      child: Text(
                        ride.driverName.isNotEmpty ? ride.driverName[0] : 'D',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5D24F7),
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
                              Text(
                                ride.driverName,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Color(0xFFFFB800),
                              ),
                              Text(
                                '${ride.driverRating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            ride.vehicle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B658C),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5D24F7),
                          ),
                        ),
                        const Text(
                          'per seat',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF8B85A8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Route row: From → To (e.g. Connaught Place, New Delhi → Sindhi Camp, Jaipur)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FE),
                    borderRadius: BorderRadius.circular(10),
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
                          '${ride.from} → ${ride.to}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF140D43),
                          ),
                        ),
                      ),
                      if (ride.originCity != null ||
                          ride.destinationCity != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${ride.displayFromCity} to ${ride.displayToCity})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B658C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Departure time & Seats left
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Color(0xFF5D24F7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                CarpoolFormatters.shortDateTime(ride.departure),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF140D43),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ride.seats} seats available',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D24F7),
                        disabledBackgroundColor: const Color(
                          0xFF5D24F7,
                        ).withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      onPressed: isBooking ? null : onBook,
                      child: isBooking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Book Seat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
