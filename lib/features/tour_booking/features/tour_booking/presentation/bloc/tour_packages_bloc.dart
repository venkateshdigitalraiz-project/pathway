import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../../domain/usecases/tour_usecase.dart';
import '../../domain/usecases/tour_usecases.dart';

abstract class TourPackagesEvent extends Equatable {
  const TourPackagesEvent();
  @override
  List<Object?> get props => [];
}

class TourPackagesStarted extends TourPackagesEvent {
  const TourPackagesStarted(
      {this.categoryId, this.query = '', this.openSearch = false});
  final String? categoryId;
  final String query;
  final bool openSearch;
  @override
  List<Object?> get props => [categoryId, query, openSearch];
}

/// `null` category = "All".
class TourPackagesFilterChanged extends TourPackagesEvent {
  const TourPackagesFilterChanged(this.categoryId);
  final String? categoryId;
  @override
  List<Object?> get props => [categoryId];
}

class TourPackagesSearchToggled extends TourPackagesEvent {
  const TourPackagesSearchToggled();
}

class TourPackagesSearchChanged extends TourPackagesEvent {
  const TourPackagesSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class TourPackagesState extends Equatable {
  const TourPackagesState({
    this.status = TourStatus.initial,
    this.categories = const [],
    this.categoryId,
    this.query = '',
    this.searchOpen = false,
    this.packages = const [],
  });

  final TourStatus status;
  final List<TourCategoryEntity> categories;
  final String? categoryId;
  final String query;
  final bool searchOpen;
  final List<TourPackageEntity> packages;

  TourPackagesState copyWith({
    TourStatus? status,
    List<TourCategoryEntity>? categories,
    Object? categoryId = _keep,
    String? query,
    bool? searchOpen,
    List<TourPackageEntity>? packages,
  }) =>
      TourPackagesState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        categoryId:
            identical(categoryId, _keep) ? this.categoryId : categoryId as String?,
        query: query ?? this.query,
        searchOpen: searchOpen ?? this.searchOpen,
        packages: packages ?? this.packages,
      );

  static const Object _keep = Object();

  @override
  List<Object?> get props =>
      [status, categories, categoryId, query, searchOpen, packages];
}

class TourPackagesBloc extends Bloc<TourPackagesEvent, TourPackagesState> {
  TourPackagesBloc({
    required TourGetCategoriesUseCase getCategories,
    required TourGetPackagesUseCase getPackages,
  })  : _getCategories = getCategories,
        _getPackages = getPackages,
        super(const TourPackagesState()) {
    on<TourPackagesStarted>(_onStarted);
    on<TourPackagesFilterChanged>((e, emit) async {
      emit(state.copyWith(categoryId: e.categoryId));
      await _load(emit);
    });
    on<TourPackagesSearchToggled>((e, emit) async {
      final open = !state.searchOpen;
      emit(state.copyWith(searchOpen: open, query: open ? state.query : ''));
      if (!open) await _load(emit);
    });
    on<TourPackagesSearchChanged>((e, emit) async {
      emit(state.copyWith(query: e.query));
      await _load(emit, expectedQuery: e.query);
    });
  }

  final TourGetCategoriesUseCase _getCategories;
  final TourGetPackagesUseCase _getPackages;

  Future<void> _onStarted(
      TourPackagesStarted e, Emitter<TourPackagesState> emit) async {
    emit(state.copyWith(
        status: TourStatus.loading,
        categoryId: e.categoryId,
        query: e.query,
        searchOpen: e.openSearch || e.query.isNotEmpty));
    try {
      final cats = await _getCategories(const TourNoParams());
      emit(state.copyWith(categories: cats));
    } catch (_) {}
    await _load(emit);
  }

  Future<void> _load(Emitter<TourPackagesState> emit,
      {String? expectedQuery}) async {
    emit(state.copyWith(status: TourStatus.loading));
    try {
      final list = await _getPackages(
          TourSearchParams(categoryId: state.categoryId, query: state.query));
      // Ignore stale responses if the query changed meanwhile.
      if (expectedQuery != null && expectedQuery != state.query) return;
      emit(state.copyWith(status: TourStatus.success, packages: list));
    } catch (_) {
      emit(state.copyWith(status: TourStatus.failure));
    }
  }
}
