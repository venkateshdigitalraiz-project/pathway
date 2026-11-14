import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecase.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourHomeEvent extends Equatable {
  const TourHomeEvent();
  @override
  List<Object?> get props => [];
}

class TourHomeStarted extends TourHomeEvent {
  const TourHomeStarted();
}

class TourHomeState extends Equatable {
  const TourHomeState({
    this.status = TourStatus.initial,
    this.categories = const [],
    this.destinations = const [],
    this.error,
  });

  final TourStatus status;
  final List<TourCategoryEntity> categories;
  final List<TourDestinationEntity> destinations;
  final String? error;

  TourHomeState copyWith({
    TourStatus? status,
    List<TourCategoryEntity>? categories,
    List<TourDestinationEntity>? destinations,
    String? error,
  }) =>
      TourHomeState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        destinations: destinations ?? this.destinations,
        error: error,
      );

  @override
  List<Object?> get props => [status, categories, destinations, error];
}

class TourHomeBloc extends Bloc<TourHomeEvent, TourHomeState> {
  TourHomeBloc({
    required TourGetCategoriesUseCase getCategories,
    required TourGetDestinationsUseCase getDestinations,
  })  : _getCategories = getCategories,
        _getDestinations = getDestinations,
        super(const TourHomeState()) {
    on<TourHomeStarted>(_onStarted);
  }

  final TourGetCategoriesUseCase _getCategories;
  final TourGetDestinationsUseCase _getDestinations;

  Future<void> _onStarted(
      TourHomeStarted e, Emitter<TourHomeState> emit) async {
    emit(state.copyWith(status: TourStatus.loading));
    try {
      final categories = await _getCategories(const TourNoParams());
      final destinations = await _getDestinations(const TourNoParams());
      emit(state.copyWith(
          status: TourStatus.success,
          categories: categories,
          destinations: destinations));
    } catch (err) {
      emit(state.copyWith(status: TourStatus.failure, error: '$err'));
    }
  }
}
