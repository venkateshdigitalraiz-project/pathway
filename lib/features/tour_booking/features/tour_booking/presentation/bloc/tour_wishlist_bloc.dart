import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecase.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourWishlistEvent extends Equatable {
  const TourWishlistEvent();
  @override
  List<Object?> get props => [];
}

class TourWishlistStarted extends TourWishlistEvent {
  const TourWishlistStarted();
}

class TourWishlistToggled extends TourWishlistEvent {
  const TourWishlistToggled(this.packageId);
  final String packageId;
  @override
  List<Object?> get props => [packageId];
}

class TourWishlistState extends Equatable {
  const TourWishlistState({
    this.status = TourStatus.initial,
    this.packages = const [],
  });

  final TourStatus status;
  final List<TourPackageEntity> packages;

  bool isSaved(String packageId) => packages.any((p) => p.id == packageId);

  @override
  List<Object?> get props => [status, packages];
}

class TourWishlistBloc extends Bloc<TourWishlistEvent, TourWishlistState> {
  TourWishlistBloc({
    required TourGetWishlistUseCase getWishlist,
    required TourToggleWishlistUseCase toggleWishlist,
  })  : _getWishlist = getWishlist,
        _toggleWishlist = toggleWishlist,
        super(const TourWishlistState()) {
    on<TourWishlistStarted>(_onStarted);
    on<TourWishlistToggled>(_onToggled);
  }

  final TourGetWishlistUseCase _getWishlist;
  final TourToggleWishlistUseCase _toggleWishlist;

  Future<void> _onStarted(
      TourWishlistStarted e, Emitter<TourWishlistState> emit) async {
    try {
      final list = await _getWishlist(const TourNoParams());
      emit(TourWishlistState(status: TourStatus.success, packages: list));
    } catch (_) {
      emit(const TourWishlistState(status: TourStatus.failure));
    }
  }

  Future<void> _onToggled(
      TourWishlistToggled e, Emitter<TourWishlistState> emit) async {
    try {
      final list = await _toggleWishlist(e.packageId);
      emit(TourWishlistState(status: TourStatus.success, packages: list));
    } catch (_) {
      // keep current state
    }
  }
}
