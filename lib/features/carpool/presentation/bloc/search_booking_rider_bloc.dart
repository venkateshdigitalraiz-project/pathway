import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/rider_booking_entity.dart';
import '../../domain/usecases/search_booking_rider_usecases.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
abstract class SearchBookingRiderEvent extends Equatable {
  const SearchBookingRiderEvent();
  @override
  List<Object?> get props => [];
}

class SearchBookingRiderStarted extends SearchBookingRiderEvent {
  const SearchBookingRiderStarted();
}

class SearchBookingRiderTabChanged extends SearchBookingRiderEvent {
  final int index;
  const SearchBookingRiderTabChanged(this.index);
  @override
  List<Object?> get props => [index];
}

class SearchBookingRiderSearchRequested extends SearchBookingRiderEvent {
  final String from;
  final String to;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime? date;
  final int seats;
  final int radiusKm;

  const SearchBookingRiderSearchRequested({
    required this.from,
    required this.to,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.date,
    this.seats = 1,
    this.radiusKm = 30,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        originLat,
        originLng,
        destinationLat,
        destinationLng,
        date,
        seats,
        radiusKm,
      ];
}

class SearchBookingRiderBookSeatRequested extends SearchBookingRiderEvent {
  final CarpoolRideEntity ride;
  final int seats;
  final String? pickupPoint;
  final String? dropoffPoint;
  final String? passengerNotes;

  const SearchBookingRiderBookSeatRequested({
    required this.ride,
    this.seats = 1,
    this.pickupPoint,
    this.dropoffPoint,
    this.passengerNotes,
  });

  @override
  List<Object?> get props => [
        ride,
        seats,
        pickupPoint,
        dropoffPoint,
        passengerNotes,
      ];
}

class SearchBookingRiderClearLastBooking extends SearchBookingRiderEvent {
  const SearchBookingRiderClearLastBooking();
}

class SearchBookingRiderCancelBookingRequested extends SearchBookingRiderEvent {
  final String bookingId;
  const SearchBookingRiderCancelBookingRequested(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class SearchBookingRiderState extends Equatable {
  final CarpoolStatus status;
  final int tabIndex;
  final List<RiderBookingEntity> bookings;
  final List<CarpoolRideEntity> searchResults;
  final String from;
  final String to;
  final DateTime? date;
  final int seats;
  final String? message;
  final String? bookingRideId;
  final RiderBookingEntity? lastBookedBooking;

  const SearchBookingRiderState({
    this.status = CarpoolStatus.initial,
    this.tabIndex = 0,
    this.bookings = const [],
    this.searchResults = const [],
    this.from = '',
    this.to = '',
    this.date,
    this.seats = 1,
    this.message,
    this.bookingRideId,
    this.lastBookedBooking,
  });

  List<RiderBookingEntity> get activeBookings => bookings
      .where((b) => b.status == RiderBookingStatus.confirmed)
      .toList();

  List<RiderBookingEntity> get pastBookings => bookings
      .where((b) => b.status != RiderBookingStatus.confirmed)
      .toList();

  int get activeBookingsCount => activeBookings.length;
  int get pastBookingsCount => pastBookings.length;

  SearchBookingRiderState copyWith({
    CarpoolStatus? status,
    int? tabIndex,
    List<RiderBookingEntity>? bookings,
    List<CarpoolRideEntity>? searchResults,
    String? from,
    String? to,
    DateTime? date,
    int? seats,
    String? message,
    String? bookingRideId,
    bool clearBookingRideId = false,
    RiderBookingEntity? lastBookedBooking,
    bool clearLastBookedBooking = false,
  }) {
    return SearchBookingRiderState(
      status: status ?? this.status,
      tabIndex: tabIndex ?? this.tabIndex,
      bookings: bookings ?? this.bookings,
      searchResults: searchResults ?? this.searchResults,
      from: from ?? this.from,
      to: to ?? this.to,
      date: date ?? this.date,
      seats: seats ?? this.seats,
      message: message,
      bookingRideId: clearBookingRideId ? null : (bookingRideId ?? this.bookingRideId),
      lastBookedBooking: clearLastBookedBooking ? null : (lastBookedBooking ?? this.lastBookedBooking),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tabIndex,
        bookings,
        searchResults,
        from,
        to,
        date,
        seats,
        message,
        bookingRideId,
        lastBookedBooking,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------
class SearchBookingRiderBloc extends Bloc<SearchBookingRiderEvent, SearchBookingRiderState> {
  final GetRiderBookingsUseCase getBookings;
  final SearchRiderRidesUseCase searchRides;
  final BookRiderSeatUseCase bookSeat;
  final CancelRiderBookingUseCase cancelBooking;

  bool _isSearching = false;
  String? _lastSearchKey;

  SearchBookingRiderBloc({
    required this.getBookings,
    required this.searchRides,
    required this.bookSeat,
    required this.cancelBooking,
  }) : super(const SearchBookingRiderState()) {
    on<SearchBookingRiderStarted>(_onStarted);
    on<SearchBookingRiderTabChanged>((e, emit) => emit(state.copyWith(tabIndex: e.index)));
    on<SearchBookingRiderSearchRequested>(_onSearch);
    on<SearchBookingRiderBookSeatRequested>(_onBookSeat);
    on<SearchBookingRiderClearLastBooking>((e, emit) => emit(state.copyWith(clearLastBookedBooking: true)));
    on<SearchBookingRiderCancelBookingRequested>(_onCancelBooking);
  }

  Future<void> _onStarted(SearchBookingRiderStarted event, Emitter<SearchBookingRiderState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      final list = await getBookings();
      emit(state.copyWith(status: CarpoolStatus.success, bookings: list));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: 'Failed to load bookings: $e'));
    }
  }

  Future<void> _onSearch(SearchBookingRiderSearchRequested event, Emitter<SearchBookingRiderState> emit) async {
    final searchKey = '${event.from}_${event.to}_${event.originLat}_${event.originLng}_${event.destinationLat}_${event.destinationLng}_${event.date?.millisecondsSinceEpoch}_${event.seats}';
    if (_isSearching || _lastSearchKey == searchKey) {
      return; // Guard: run exactly one time for identical query
    }
    _isSearching = true;
    _lastSearchKey = searchKey;

    emit(state.copyWith(
      status: CarpoolStatus.loading,
      from: event.from,
      to: event.to,
      date: event.date,
      seats: event.seats,
    ));
    try {
      final results = await searchRides(
        from: event.from,
        to: event.to,
        originLat: event.originLat,
        originLng: event.originLng,
        destinationLat: event.destinationLat,
        destinationLng: event.destinationLng,
        date: event.date,
        seats: event.seats,
        radiusKm: event.radiusKm,
      );
      emit(state.copyWith(status: CarpoolStatus.success, searchResults: results));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: 'Search failed: $e'));
    } finally {
      _isSearching = false;
    }
  }

  Future<void> _onBookSeat(SearchBookingRiderBookSeatRequested event, Emitter<SearchBookingRiderState> emit) async {
    emit(state.copyWith(bookingRideId: event.ride.id, clearLastBookedBooking: true));
    try {
      final newBooking = await bookSeat(
        ride: event.ride,
        seats: event.seats,
        pickupPoint: event.pickupPoint,
        dropoffPoint: event.dropoffPoint,
        passengerNotes: event.passengerNotes,
      );
      final updated = [newBooking, ...state.bookings];
      emit(state.copyWith(
        clearBookingRideId: true,
        lastBookedBooking: newBooking,
        bookings: updated,
        message: 'Ride booked successfully with ${event.ride.driverName}!'));
    } catch (e) {
      emit(state.copyWith(
        clearBookingRideId: true,
        message: 'Booking failed: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  Future<void> _onCancelBooking(SearchBookingRiderCancelBookingRequested event, Emitter<SearchBookingRiderState> emit) async {
    emit(state.copyWith(status: CarpoolStatus.loading));
    try {
      await cancelBooking(event.bookingId);
      final list = await getBookings();
      emit(state.copyWith(status: CarpoolStatus.success, bookings: list, message: 'Booking cancelled successfully.'));
    } catch (e) {
      emit(state.copyWith(status: CarpoolStatus.failure, message: 'Cancel failed: $e'));
    }
  }
}
