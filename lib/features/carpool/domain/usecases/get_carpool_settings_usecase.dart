import '../entities/carpool_settings_entity.dart';
import '../repositories/carpool_settings_repository.dart';

class GetCarpoolSettingsUseCase {
  final CarpoolSettingsRepository repository;

  const GetCarpoolSettingsUseCase(this.repository);

  Future<CarpoolSettingsEntity> call({bool forceRefresh = false}) {
    return repository.getCarpoolSettings(forceRefresh: forceRefresh);
  }

  CarpoolSettingsEntity getCached() {
    return repository.getCachedSettings();
  }
}
