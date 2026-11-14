import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourDetailEvent extends Equatable {
  const TourDetailEvent();
  @override
  List<Object?> get props => [];
}

class TourDetailStarted extends TourDetailEvent {
  const TourDetailStarted(this.packageId);
  final String packageId;
  @override
  List<Object?> get props => [packageId];
}

class TourDetailImageChanged extends TourDetailEvent {
  const TourDetailImageChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class TourDetailState extends Equatable {
  const TourDetailState({
    this.status = TourStatus.initial,
    this.package,
    this.imageIndex = 0,
    this.error,
  });

  final TourStatus status;
  final TourPackageEntity? package;
  final int imageIndex;
  final String? error;

  TourDetailState copyWith({
    TourStatus? status,
    TourPackageEntity? package,
    int? imageIndex,
    String? error,
  }) =>
      TourDetailState(
        status: status ?? this.status,
        package: package ?? this.package,
        imageIndex: imageIndex ?? this.imageIndex,
        error: error,
      );

  @override
  List<Object?> get props => [status, package, imageIndex, error];
}

class TourDetailBloc extends Bloc<TourDetailEvent, TourDetailState> {
  TourDetailBloc({required TourGetPackageUseCase getPackage})
      : _getPackage = getPackage,
        super(const TourDetailState()) {
    on<TourDetailStarted>(_onStarted);
    on<TourDetailImageChanged>(
        (e, emit) => emit(state.copyWith(imageIndex: e.index)));
  }

  final TourGetPackageUseCase _getPackage;

  Future<void> _onStarted(
      TourDetailStarted e, Emitter<TourDetailState> emit) async {
    emit(state.copyWith(status: TourStatus.loading));
    try {
      final p = await _getPackage(e.packageId);
      emit(state.copyWith(status: TourStatus.success, package: p));
    } catch (err) {
      emit(state.copyWith(status: TourStatus.failure, error: '$err'));
    }
  }
}
