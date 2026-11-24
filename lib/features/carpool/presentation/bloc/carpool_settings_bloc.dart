import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/carpool_status.dart';
import '../../data/datasources/carpool_settings_local_data_source.dart';
import '../../domain/entities/carpool_settings_entity.dart';
import '../../domain/usecases/get_carpool_settings_usecase.dart';

// ── EVENTS ───────────────────────────────────────────────────────────────────

abstract class CarpoolSettingsEvent extends Equatable {
  const CarpoolSettingsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCarpoolSettingsEvent extends CarpoolSettingsEvent {
  final bool forceRefresh;

  const FetchCarpoolSettingsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

// ── STATE ────────────────────────────────────────────────────────────────────

class CarpoolSettingsState extends Equatable {
  final CarpoolStatus status;
  final CarpoolSettingsEntity settings;
  final String? errorMessage;

  const CarpoolSettingsState({
    this.status = CarpoolStatus.initial,
    this.settings = CarpoolSettingsEntity.defaultSettings,
    this.errorMessage,
  });

  CarpoolSettingsState copyWith({
    CarpoolStatus? status,
    CarpoolSettingsEntity? settings,
    String? errorMessage,
  }) {
    return CarpoolSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}

// ── BLOC ─────────────────────────────────────────────────────────────────────

class CarpoolSettingsBloc
    extends Bloc<CarpoolSettingsEvent, CarpoolSettingsState> {
  final GetCarpoolSettingsUseCase getCarpoolSettings;
  final CarpoolSettingsLocalDataSource? localDataSource;

  CarpoolSettingsBloc({
    GetCarpoolSettingsUseCase? getCarpoolSettings,
    GetCarpoolSettingsUseCase? getCarpoolSettingsUseCase,
    this.localDataSource,
  })  : getCarpoolSettings = (getCarpoolSettings ?? getCarpoolSettingsUseCase)!,
        super(
          CarpoolSettingsState(
            status: CarpoolStatus.initial,
            settings: (getCarpoolSettings ?? getCarpoolSettingsUseCase)!.getCached(),
          ),
        ) {
    on<FetchCarpoolSettingsEvent>(_onFetchSettings);
  }

  Future<void> _onFetchSettings(
    FetchCarpoolSettingsEvent event,
    Emitter<CarpoolSettingsState> emit,
  ) async {
    emit(state.copyWith(status: CarpoolStatus.loading, errorMessage: null));
    try {
      final settings = await getCarpoolSettings(
        forceRefresh: event.forceRefresh,
      );
      emit(
        state.copyWith(
          status: CarpoolStatus.success,
          settings: settings,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CarpoolStatus.failure,
          errorMessage: e.toString(),
          settings: getCarpoolSettings.getCached(),
        ),
      );
    }
  }
}
