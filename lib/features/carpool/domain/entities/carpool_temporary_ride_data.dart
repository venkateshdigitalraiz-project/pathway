import 'carpool_route_option_entity.dart';
import 'carpool_stopover_entity.dart';

/// Clean Architecture temporary session storage for Carpool ride publishing flow.
///
/// 1. [WhereIsTheRoutePage] saves the selected toll route object (km/distance, duration, toll type).
/// 2. [CarpoolStopoverSearchPage] saves newly searched and validated stopover halts.
/// 3. [CarpoolRideSummaryPage] accesses this temporary saved data to pass into the publish ride API.
/// 4. After running the publish API, [clear] is invoked to immediately wipe all temporary session data.
class CarpoolTemporaryRideData {
  CarpoolTemporaryRideData._();
  static final CarpoolTemporaryRideData instance = CarpoolTemporaryRideData._();

  // ══════════════════════════════════════════════════════════════════════════
  // TEMPORARY TOLL ROUTE OBJECT (from WhereIsTheRoutePage)
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic>? tollRoute;
  double? totalDistance;
  double? distanceKm;
  bool? hasToll;
  String? tollType;
  CarpoolRouteOptionEntity? selectedRoute;

  // ══════════════════════════════════════════════════════════════════════════
  // TEMPORARY STOPOVER HALTS LIST (from CarpoolStopoverSearchPage)
  // ══════════════════════════════════════════════════════════════════════════
  List<CarpoolStopoverEntity> stopoverHalts = [];

  /// Saves the toll route details selected on WhereIsTheRoutePage
  void saveTollRoute({
    required String type,
    required String duration,
    required double distance,
    required bool hasTolls,
    CarpoolRouteOptionEntity? routeOption,
  }) {
    tollType = type;
    hasToll = hasTolls;
    totalDistance = distance;
    distanceKm = distance;
    selectedRoute = routeOption;
    tollRoute = {
      'type': type,
      'duration': duration,
      'distance': distance,
    };
  }

  /// Saves or replaces the complete list of stopover halts
  void saveStopoverHalts(List<CarpoolStopoverEntity> halts) {
    stopoverHalts = List.from(halts);
  }

  /// Adds a validated stopover halt from CarpoolStopoverSearchPage
  void addStopoverHalt(CarpoolStopoverEntity halt) {
    final cleanCity = halt.city.trim().toLowerCase();
    final idx = stopoverHalts.indexWhere(
      (h) => h.city.trim().toLowerCase() == cleanCity,
    );
    if (idx >= 0) {
      stopoverHalts[idx] = halt;
    } else {
      stopoverHalts.add(halt);
    }
  }

  /// Removes a stopover halt by city name
  void removeStopoverHalt(String cityName) {
    final clean = cityName.trim().toLowerCase();
    stopoverHalts.removeWhere((h) => h.city.trim().toLowerCase() == clean);
  }

  /// Serializes the stopover halts into ordered JSON objects
  List<Map<String, dynamic>> getSerializedStopovers() {
    return stopoverHalts.asMap().entries.map((entry) {
      final order = entry.key + 1;
      final stop = entry.value;
      return {
        'order': order,
        'city': stop.city,
        'address': stop.address.isNotEmpty ? stop.address : stop.city,
        'state': stop.state.isNotEmpty ? stop.state : 'India',
        'latitude': stop.latitude,
        'longitude': stop.longitude,
      };
    }).toList();
  }

  /// Clears all temporary saved ride publishing data after running the publish API
  void clear() {
    tollRoute = null;
    totalDistance = null;
    distanceKm = null;
    hasToll = null;
    tollType = null;
    selectedRoute = null;
    stopoverHalts.clear();
  }
}
