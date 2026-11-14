import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecase.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourBookingEvent extends Equatable {
  const TourBookingEvent();
  @override
  List<Object?> get props => [];
}

/// Starts (and resets) the booking flow for one package.
class TourBookingStarted extends TourBookingEvent {
  const TourBookingStarted(this.package);
  final TourPackageEntity package;
  @override
  List<Object?> get props => [package];
}

class TourBookingDateChanged extends TourBookingEvent {
  const TourBookingDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class TourBookingTravellersChanged extends TourBookingEvent {
  const TourBookingTravellersChanged(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

class TourBookingPackageTypeChanged extends TourBookingEvent {
  const TourBookingPackageTypeChanged(this.type);
  final TourPackageType type;
  @override
  List<Object?> get props => [type];
}

class TourBookingAddOnToggled extends TourBookingEvent {
  const TourBookingAddOnToggled(this.addOnId);
  final String addOnId;
  @override
  List<Object?> get props => [addOnId];
}

class TourBookingNameChanged extends TourBookingEvent {
  const TourBookingNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class TourBookingEmailChanged extends TourBookingEvent {
  const TourBookingEmailChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class TourBookingPhoneChanged extends TourBookingEvent {
  const TourBookingPhoneChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class TourBookingNotesChanged extends TourBookingEvent {
  const TourBookingNotesChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class TourBookingTermsToggled extends TourBookingEvent {
  const TourBookingTermsToggled(this.agreed);
  final bool agreed;
  @override
  List<Object?> get props => [agreed];
}

class TourBookingPaymentSelected extends TourBookingEvent {
  const TourBookingPaymentSelected(this.method);
  final TourPaymentMethod method;
  @override
  List<Object?> get props => [method];
}

class TourBookingPayPressed extends TourBookingEvent {
  const TourBookingPayPressed();
}

class TourBookingState extends Equatable {
  const TourBookingState({
    this.package,
    this.addOns = const [],
    this.travelDate,
    this.travellers = 2,
    this.packageType = TourPackageType.standard,
    this.selectedAddOnIds = const {},
    this.name = '',
    this.email = '',
    this.phone = '',
    this.notes = '',
    this.agreed = false,
    this.payment = TourPaymentMethod.upi,
    this.status = TourStatus.initial,
    this.booking,
    this.error,
  });

  final TourPackageEntity? package;
  final List<TourAddOnEntity> addOns;
  final DateTime? travelDate;
  final int travellers;
  final TourPackageType packageType;
  final Set<String> selectedAddOnIds;
  final String name;
  final String email;
  final String phone;
  final String notes;
  final bool agreed;
  final TourPaymentMethod payment;
  final TourStatus status;
  final TourBookingEntity? booking;
  final String? error;

  Iterable<TourAddOnEntity> get selectedAddOns =>
      addOns.where((a) => selectedAddOnIds.contains(a.id));

  int get total => package == null
      ? 0
      : TourPricing.total(
          package: package!,
          type: packageType,
          travellers: travellers,
          addOns: selectedAddOns,
        );

  /// Null when the customer details step is valid.
  String? get detailsError {
    if (name.trim().length < 2) return 'Enter your full name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Enter a valid email address.';
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      return 'Enter a valid 10-digit mobile number.';
    }
    if (!agreed) return 'Please accept the Terms & Conditions to continue.';
    return null;
  }

  TourBookingState copyWith({
    List<TourAddOnEntity>? addOns,
    DateTime? travelDate,
    int? travellers,
    TourPackageType? packageType,
    Set<String>? selectedAddOnIds,
    String? name,
    String? email,
    String? phone,
    String? notes,
    bool? agreed,
    TourPaymentMethod? payment,
    TourStatus? status,
    TourBookingEntity? booking,
    String? error,
  }) =>
      TourBookingState(
        package: package,
        addOns: addOns ?? this.addOns,
        travelDate: travelDate ?? this.travelDate,
        travellers: travellers ?? this.travellers,
        packageType: packageType ?? this.packageType,
        selectedAddOnIds: selectedAddOnIds ?? this.selectedAddOnIds,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        agreed: agreed ?? this.agreed,
        payment: payment ?? this.payment,
        status: status ?? this.status,
        booking: booking ?? this.booking,
        error: error,
      );

  @override
  List<Object?> get props => [
        package, addOns, travelDate, travellers, packageType, selectedAddOnIds,
        name, email, phone, notes, agreed, payment, status, booking, error,
      ];
}

class TourBookingBloc extends Bloc<TourBookingEvent, TourBookingState> {
  TourBookingBloc({
    required TourGetAddOnsUseCase getAddOns,
    required TourCreateBookingUseCase createBooking,
  })  : _getAddOns = getAddOns,
        _createBooking = createBooking,
        super(const TourBookingState()) {
    on<TourBookingStarted>(_onStarted);
    on<TourBookingDateChanged>(
        (e, emit) => emit(state.copyWith(travelDate: e.date)));
    on<TourBookingTravellersChanged>((e, emit) => emit(state.copyWith(
        travellers: (state.travellers + e.delta).clamp(1, 10).toInt())));
    on<TourBookingPackageTypeChanged>(
        (e, emit) => emit(state.copyWith(packageType: e.type)));
    on<TourBookingAddOnToggled>((e, emit) {
      final ids = {...state.selectedAddOnIds};
      ids.contains(e.addOnId) ? ids.remove(e.addOnId) : ids.add(e.addOnId);
      emit(state.copyWith(selectedAddOnIds: ids));
    });
    on<TourBookingNameChanged>((e, emit) => emit(state.copyWith(name: e.value)));
    on<TourBookingEmailChanged>(
        (e, emit) => emit(state.copyWith(email: e.value)));
    on<TourBookingPhoneChanged>(
        (e, emit) => emit(state.copyWith(phone: e.value)));
    on<TourBookingNotesChanged>(
        (e, emit) => emit(state.copyWith(notes: e.value)));
    on<TourBookingTermsToggled>(
        (e, emit) => emit(state.copyWith(agreed: e.agreed)));
    on<TourBookingPaymentSelected>(
        (e, emit) => emit(state.copyWith(payment: e.method)));
    on<TourBookingPayPressed>(_onPay);
  }

  final TourGetAddOnsUseCase _getAddOns;
  final TourCreateBookingUseCase _createBooking;

  Future<void> _onStarted(
      TourBookingStarted e, Emitter<TourBookingState> emit) async {
    final n = DateTime.now();
    emit(TourBookingState(
      package: e.package,
      travelDate: DateTime(n.year, n.month, n.day + 14),
    ));
    try {
      final addOns = await _getAddOns(const TourNoParams());
      emit(state.copyWith(addOns: addOns));
    } catch (_) {
      // add-ons are optional; continue without them
    }
  }

  Future<void> _onPay(
      TourBookingPayPressed e, Emitter<TourBookingState> emit) async {
    final pkg = state.package;
    final date = state.travelDate;
    if (pkg == null || date == null || state.status == TourStatus.loading) {
      return;
    }
    emit(state.copyWith(status: TourStatus.loading));
    try {
      final booking = await _createBooking(TourCreateBookingParams(
        packageId: pkg.id,
        travelDate: date,
        travellers: state.travellers,
        packageType: state.packageType,
        addOnIds: state.selectedAddOnIds.toList(),
        customerName: state.name,
        email: state.email,
        phone: state.phone,
        notes: state.notes,
        paymentMethod: state.payment,
      ));
      emit(state.copyWith(status: TourStatus.success, booking: booking));
    } catch (err) {
      emit(state.copyWith(status: TourStatus.failure, error: '$err'));
      emit(state.copyWith(status: TourStatus.initial)); // clears one-shot error
    }
  }
}
