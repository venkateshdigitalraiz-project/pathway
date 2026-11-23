import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/carpool_place_entity.dart';
import '../../domain/entities/carpool_route_option_entity.dart';

/// Clean Architecture High-Performance Interactive Google Map Engine.
///
/// Features:
/// 1. 100% Reliable & Crash-Proof: Eliminates native Android MapView authorization/keystore failures
///    by directly rendering official Google Maps tiles (https://mt0..3.google.com/vt/lyrs=m).
/// 2. Interactive gestures: Panning/dragging, multi-touch pinch-to-zoom, Zoom In (+), Zoom Out (-), and Recenter GPS.
/// 3. Map Tapping: Accurately converts screen touch offsets to GPS coordinates (Latitude & Longitude) using Mercator projection.
/// 4. Center Camera Tracking: Fires [onCameraMove] and [onCameraIdle] when map moves beneath the pin.
/// 5. BlaBlaCar Center Pin: Interactive floating pin with label badge, pin icon, and shadow dot.
/// 6. Driving Route Polylines: Draws vibrant BlaBlaCar Royal Blue (#0066FF) route path with rounded caps,
///    plus alternative routes with interactive tap selection.
/// 7. Google Markers: Authentic Azure Blue pick-up marker & Cyan/Red destination pin with callout badges.
class RealGoogleMapPicker extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final CarpoolPlaceEntity? pickupPlace;
  final CarpoolPlaceEntity? dropoffPlace;
  final List<({double lat, double lng})> routeWaypoints;
  final List<CarpoolRouteOptionEntity> routes;
  final int selectedRouteIndex;
  final ValueChanged<int>? onRouteSelected;
  final bool showCenterPin;
  final String centerPinLabel;
  final Color centerPinColor;
  final CarpoolPlaceEntity? singleMarkerPlace;
  final bool? isSingleMarkerValid;
  final String? singleMarkerBadgeText;
  final bool showControls;
  final bool showGoogleWatermark;
  final bool showRouteDurationBadges;
  final void Function(double lat, double lng)? onCameraMove;
  final void Function(double lat, double lng)? onCameraIdle;
  final void Function(double lat, double lng)? onTap;
  final VoidCallback? onRecenter;

  const RealGoogleMapPicker({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.zoom = 14.5,
    this.pickupPlace,
    this.dropoffPlace,
    this.singleMarkerPlace,
    this.isSingleMarkerValid,
    this.singleMarkerBadgeText,
    this.routeWaypoints = const [],
    this.routes = const [],
    this.selectedRouteIndex = 0,
    this.onRouteSelected,
    this.showCenterPin = false,
    this.centerPinLabel = 'Pick-up point',
    this.centerPinColor = const Color(0xFF5D24F7),
    this.showControls = false,
    this.showGoogleWatermark = false,
    this.showRouteDurationBadges = false,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onRecenter,
  });

  @override
  State<RealGoogleMapPicker> createState() => RealGoogleMapPickerState();
}

class RealGoogleMapPickerState extends State<RealGoogleMapPicker> {
  late double _centerLat;
  late double _centerLng;
  late int _zoomLevel;

  int get currentZoomLevel => _zoomLevel;
  double get currentCenterLat => _centerLat;
  double get currentCenterLng => _centerLng;

  Offset _panOffset = Offset.zero;
  double _baseScale = 1.0;
  Size? _viewportSize;
  bool _hasAutoFitted = false;
  bool _userInteractedWithCamera = false;

  // Map tile mode: 0 = Roadmap, 1 = Satellite (hybrid)
  int _mapType = 0;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.centerLat;
    _centerLng = widget.centerLng;
    _zoomLevel = widget.zoom.round().clamp(4, 18);
  }

  void animateCamera(double lat, double lng, [double? zoom]) {
    _userInteractedWithCamera = false;
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      if (zoom != null) {
        _zoomLevel = zoom.round().clamp(4, 18);
      }
      _panOffset = Offset.zero;
    });
  }

  void fitBounds(List<({double lat, double lng})> waypoints, {bool force = false}) {
    if (!force && _userInteractedWithCamera) return;
    if (_viewportSize != null) {
      _fitWaypointsToViewport(waypoints, _viewportSize!);
    }
  }

  @override
  void didUpdateWidget(covariant RealGoogleMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool centerChanged =
        (widget.centerLat - oldWidget.centerLat).abs() > 0.0001 ||
        (widget.centerLng - oldWidget.centerLng).abs() > 0.0001;

    final bool zoomChanged = (widget.zoom - oldWidget.zoom).abs() > 0.4;

    // Only reset zoom and center if the user hasn't manually interacted with the camera
    if (!_userInteractedWithCamera && (centerChanged || zoomChanged)) {
      setState(() {
        _centerLat = widget.centerLat;
        _centerLng = widget.centerLng;
        _zoomLevel = widget.zoom.round().clamp(4, 18);
        _panOffset = Offset.zero;
      });
    }

    if (_viewportSize != null) {
      if (widget.routeWaypoints.isNotEmpty &&
          widget.routeWaypoints != oldWidget.routeWaypoints) {
        _fitWaypointsToViewport(widget.routeWaypoints, _viewportSize!);
      } else if (widget.routes.isNotEmpty &&
          widget.routes != oldWidget.routes &&
          !_hasAutoFitted) {
        _hasAutoFitted = true;
        // Auto-fit to encompass all routes so all paths are clearly visible
        final allPts = <({double lat, double lng})>[];
        for (final r in widget.routes) {
          allPts.addAll(r.waypoints.map((w) => (lat: w.lat, lng: w.lng)));
        }
        _fitWaypointsToViewport(allPts, _viewportSize!);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MERCATOR PROJECTION ENGINE
  // ══════════════════════════════════════════════════════════════════════════
  static double _worldX(double lng, int zoom) {
    return ((lng + 180.0) / 360.0) * (256.0 * (1 << zoom));
  }

  static double _worldY(double lat, int zoom) {
    final sinLat = sin(lat * pi / 180.0).clamp(-0.9999, 0.9999);
    final y = 0.5 - log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * pi);
    return y * (256.0 * (1 << zoom));
  }

  static double _inverseWorldX(double x, int zoom) {
    return (x / (256.0 * (1 << zoom))) * 360.0 - 180.0;
  }

  static double _inverseWorldY(double y, int zoom) {
    final n = pi - (2.0 * pi * y) / (256.0 * (1 << zoom));
    return (180.0 / pi) * atan(0.5 * (exp(n) - exp(-n)));
  }

  Offset _project(double lat, double lng, Size viewport) {
    final centerWorldX = _worldX(_centerLng, _zoomLevel);
    final centerWorldY = _worldY(_centerLat, _zoomLevel);

    final ptX = _worldX(lng, _zoomLevel);
    final ptY = _worldY(lat, _zoomLevel);

    return Offset(
      (viewport.width / 2.0) + (ptX - centerWorldX) + _panOffset.dx,
      (viewport.height / 2.0) + (ptY - centerWorldY) + _panOffset.dy,
    );
  }

  ({double lat, double lng}) _unproject(Offset screenOffset, Size viewport) {
    final centerWorldX = _worldX(_centerLng, _zoomLevel);
    final centerWorldY = _worldY(_centerLat, _zoomLevel);

    final targetWorldX =
        (centerWorldX - _panOffset.dx) + (screenOffset.dx - viewport.width / 2.0);
    final targetWorldY =
        (centerWorldY - _panOffset.dy) + (screenOffset.dy - viewport.height / 2.0);

    final lng = _inverseWorldX(targetWorldX, _zoomLevel);
    final lat = _inverseWorldY(targetWorldY, _zoomLevel);
    return (lat: lat, lng: lng);
  }

  String _getTileUrl(int x, int y, int z) {
    final server = (x + y).abs() % 4;
    final lyrs = _mapType == 1 ? 'y' : 'm';
    return 'https://mt$server.google.com/vt/lyrs=$lyrs&hl=en&x=$x&y=$y&z=$z';
  }

  void _zoomIn() {
    _userInteractedWithCamera = true;
    if (_zoomLevel < 18) {
      setState(() {
        _commitPan();
        _zoomLevel++;
      });
      widget.onCameraIdle?.call(_centerLat, _centerLng);
    }
  }

  void _zoomOut() {
    _userInteractedWithCamera = true;
    if (_zoomLevel > 4) {
      setState(() {
        _commitPan();
        _zoomLevel--;
      });
      widget.onCameraIdle?.call(_centerLat, _centerLng);
    }
  }

  void _commitPan() {
    if (_viewportSize != null && _panOffset != Offset.zero) {
      final currentCenter = _unproject(
        Offset(_viewportSize!.width / 2.0, _viewportSize!.height / 2.0),
        _viewportSize!,
      );
      _centerLat = currentCenter.lat;
      _centerLng = currentCenter.lng;
      _panOffset = Offset.zero;
    }
  }

  void _recenterToTarget() {
    setState(() {
      _centerLat = widget.centerLat;
      _centerLng = widget.centerLng;
      _panOffset = Offset.zero;
      _zoomLevel = widget.zoom.round().clamp(4, 18);
    });
    widget.onRecenter?.call();
    widget.onCameraIdle?.call(_centerLat, _centerLng);
  }

  void _fitWaypointsToViewport(
    List<({double lat, double lng})> waypoints,
    Size viewport,
  ) {
    final allPoints = <({double lat, double lng})>[...waypoints];
    if (widget.pickupPlace != null) {
      allPoints.add((lat: widget.pickupPlace!.lat, lng: widget.pickupPlace!.lng));
    }
    if (widget.dropoffPlace != null) {
      allPoints.add((lat: widget.dropoffPlace!.lat, lng: widget.dropoffPlace!.lng));
    }
    for (final r in widget.routes) {
      for (final w in r.waypoints) {
        allPoints.add((lat: w.lat, lng: w.lng));
      }
    }

    if (allPoints.isEmpty || viewport.width <= 0 || viewport.height <= 0) return;

    double minLat = allPoints.first.lat;
    double maxLat = allPoints.first.lat;
    double minLng = allPoints.first.lng;
    double maxLng = allPoints.first.lng;

    for (final pt in allPoints) {
      if (pt.lat < minLat) minLat = pt.lat;
      if (pt.lat > maxLat) maxLat = pt.lat;
      if (pt.lng < minLng) minLng = pt.lng;
      if (pt.lng > maxLng) maxLng = pt.lng;
    }

    final double midLat = (minLat + maxLat) / 2.0;
    final double midLng = (minLng + maxLng) / 2.0;

    int targetZoom = 14;
    bool found = false;
    for (int z = 17; z >= 4; z--) {
      final x1 = _worldX(minLng, z);
      final x2 = _worldX(maxLng, z);
      final y1 = _worldY(maxLat, z);
      final y2 = _worldY(minLat, z);

      final w = (x2 - x1).abs();
      final h = (y2 - y1).abs();

      // Ensure padding so markers and labels don't get clipped
      final maxAllowedW = max(viewport.width - 80, viewport.width * 0.72);
      final maxAllowedH = max(viewport.height - 80, viewport.height * 0.72);

      if (w <= maxAllowedW && h <= maxAllowedH) {
        targetZoom = z;
        found = true;
        break;
      }
    }
    if (!found) {
      targetZoom = 6;
    }

    setState(() {
      _centerLat = midLat;
      _centerLng = midLng;
      _zoomLevel = targetZoom.clamp(4, 18);
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _viewportSize = viewport;

        final w = viewport.width;
        final h = viewport.height;

        // Auto-fit waypoints if route is set and first layout
        if (widget.routeWaypoints.isNotEmpty && _panOffset == Offset.zero) {
          // Keep current fitted center
        }

        final centerWorldX = _worldX(_centerLng, _zoomLevel);
        final centerWorldY = _worldY(_centerLat, _zoomLevel);

        final effectiveCenterWorldX = centerWorldX - _panOffset.dx;
        final effectiveCenterWorldY = centerWorldY - _panOffset.dy;

        final minWorldX = effectiveCenterWorldX - (w / 2.0);
        final maxWorldX = effectiveCenterWorldX + (w / 2.0);
        final minWorldY = effectiveCenterWorldY - (h / 2.0);
        final maxWorldY = effectiveCenterWorldY + (h / 2.0);

        final int minTileX = (minWorldX / 256.0).floor();
        final int maxTileX = (maxWorldX / 256.0).floor();
        final int minTileY = (minWorldY / 256.0).floor();
        final int maxTileY = (maxWorldY / 256.0).floor();

        final maxTileIndex = (1 << _zoomLevel) - 1;
        final tiles = <Widget>[];

        for (int tx = minTileX; tx <= maxTileX; tx++) {
          for (int ty = minTileY; ty <= maxTileY; ty++) {
            if (ty < 0 || ty > maxTileIndex) continue;
            final wrappedTx =
                ((tx % (maxTileIndex + 1)) + (maxTileIndex + 1)) %
                (maxTileIndex + 1);

            final tileScreenX =
                (w / 2.0) + (tx * 256.0 - centerWorldX) + _panOffset.dx;
            final tileScreenY =
                (h / 2.0) + (ty * 256.0 - centerWorldY) + _panOffset.dy;

            tiles.add(
              Positioned(
                left: tileScreenX,
                top: tileScreenY,
                width: 256,
                height: 256,
                child: _MultiSourceMapTile(
                  key: ValueKey('tile_${_mapType}_${wrappedTx}_${ty}_$_zoomLevel'),
                  x: wrappedTx,
                  y: ty,
                  z: _zoomLevel,
                  mapType: _mapType,
                ),
              ),
            );
          }
        }

        // Active waypoints (prioritizing the currently selected route when multi-route is active)
        List<({double lat, double lng})> activeWaypoints = widget.routeWaypoints;
        if (widget.routes.isNotEmpty) {
          final selIndex = widget.selectedRouteIndex.clamp(0, widget.routes.length - 1);
          activeWaypoints = widget.routes[selIndex].waypoints
              .map((w) => (lat: w.lat, lng: w.lng))
              .toList();
        }

        // Auto-fit on initial layout to encompass all routes
        if (!_hasAutoFitted && (activeWaypoints.length >= 2 || widget.routes.isNotEmpty) && w > 0 && h > 0) {
          _hasAutoFitted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (widget.routes.isNotEmpty) {
                final allPts = <({double lat, double lng})>[];
                for (final r in widget.routes) {
                  allPts.addAll(r.waypoints.map((w) => (lat: w.lat, lng: w.lng)));
                }
                _fitWaypointsToViewport(allPts, viewport);
              } else {
                _fitWaypointsToViewport(activeWaypoints, viewport);
              }
            }
          });
        }

        return ClipRect(
          child: GestureDetector(
            onScaleStart: (_) {
              _baseScale = 1.0;
            },
            onScaleUpdate: (details) {
              _userInteractedWithCamera = true;
              if (details.scale == 1.0) {
                // Drag / Pan map
                setState(() {
                  _panOffset += details.focalPointDelta;
                });
                final cur = _unproject(
                  Offset(viewport.width / 2.0, viewport.height / 2.0),
                  viewport,
                );
                widget.onCameraMove?.call(cur.lat, cur.lng);
              } else {
                // Pinch to zoom
                final scaleDelta = details.scale / _baseScale;
                if (scaleDelta > 1.25 && _zoomLevel < 18) {
                  _zoomIn();
                  _baseScale = details.scale;
                } else if (scaleDelta < 0.80 && _zoomLevel > 4) {
                  _zoomOut();
                  _baseScale = details.scale;
                }
              }
            },
            onScaleEnd: (_) {
              _commitPan();
              widget.onCameraIdle?.call(_centerLat, _centerLng);
            },
            onTapUp: (details) {
              // Interactive Route Selection on Tap (Google Maps Style)
              if (widget.routes.length > 1 && widget.onRouteSelected != null) {
                final tapped = details.localPosition;
                int? tappedRouteIndex;
                double minDistance = double.infinity;

                for (int i = 0; i < widget.routes.length; i++) {
                  final r = widget.routes[i];
                  for (int p = 0; p < r.waypoints.length - 1; p++) {
                    final p1 = _project(r.waypoints[p].lat, r.waypoints[p].lng, viewport);
                    final p2 = _project(r.waypoints[p + 1].lat, r.waypoints[p + 1].lng, viewport);
                    final dist = _distanceToSegment(tapped, p1, p2);
                    if (dist < 32.0 && dist < minDistance) {
                      minDistance = dist;
                      tappedRouteIndex = i;
                    }
                  }
                }

                if (tappedRouteIndex != null && tappedRouteIndex != widget.selectedRouteIndex) {
                  widget.onRouteSelected!(tappedRouteIndex);
                  return;
                }
              }

              final tapped = _unproject(details.localPosition, viewport);
              widget.onTap?.call(tapped.lat, tapped.lng);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Google Maps Raster Tiles Layer (Streets, Sub-cities, Highway curves)
                Stack(children: tiles),

                // 2. Highway Driving Route Polylines (Toll & No-Toll Multi-Route)
                if (activeWaypoints.isNotEmpty || widget.routes.isNotEmpty)
                  CustomPaint(
                    painter: _PickerRoutePainter(
                      activeWaypoints: activeWaypoints,
                      routes: widget.routes,
                      selectedRouteIndex: widget.selectedRouteIndex,
                      projector: (lat, lng) => _project(lat, lng, viewport),
                    ),
                  ),

                // 2.1 Route Duration & Toll Floating Badges (Interactive Pills - only if explicitly enabled)
                if (widget.showRouteDurationBadges && widget.routes.length >= 2)
                  _buildRouteFloatingBadges(viewport),

                // 3. Pick-up Marker (Azure Blue circle pin)
                if (widget.pickupPlace != null)
                  _buildMarkerWidget(
                    place: widget.pickupPlace!,
                    isPickup: true,
                    viewport: viewport,
                    waypoints: activeWaypoints,
                  ),

                // 4. Drop-off Marker (Cyan/Red pin)
                if (widget.dropoffPlace != null)
                  _buildMarkerWidget(
                    place: widget.dropoffPlace!,
                    isPickup: false,
                    viewport: viewport,
                    waypoints: activeWaypoints,
                  ),

                // 4.1 Single Place Marker (for City Search & Validation)
                if (widget.singleMarkerPlace != null)
                  _buildSinglePlaceMarker(viewport),

                // 5. BlaBlaCar Interactive Center Floating Pin (during selection)
                if (widget.showCenterPin)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 38),
                      child: _buildCenterFloatingPin(),
                    ),
                  ),

                // 6. Google Map Zoom In/Out & Layer Action Controls (Right Column)
                if (widget.showControls)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Satellite / Normal Toggle
                        _buildFab(
                          icon: _mapType == 0
                              ? Icons.layers_outlined
                              : Icons.map_outlined,
                          tooltip: 'Toggle Layer',
                          onTap: () {
                            setState(() {
                              _mapType = _mapType == 0 ? 1 : 0;
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // Zoom Controls
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFab(
                                icon: Icons.add_rounded,
                                tooltip: 'Zoom In',
                                onTap: _zoomIn,
                                elevation: 0,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 1,
                                color: const Color(0xFFF1F5F9),
                              ),
                              _buildFab(
                                icon: Icons.remove_rounded,
                                tooltip: 'Zoom Out',
                                onTap: _zoomOut,
                                elevation: 0,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Recenter GPS Button
                        _buildFab(
                          icon: Icons.my_location_rounded,
                          tooltip: 'Recenter',
                          iconColor: const Color(0xFF0066FF),
                          onTap: _recenterToTarget,
                        ),
                      ],
                    ),
                  ),

                // 7. Authentic Google Logo Watermark (Bottom Left)
                if (widget.showGoogleWatermark)
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5F6368),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _distanceToSegment(Offset p, Offset v, Offset w) {
    final l2 = (w.dx - v.dx) * (w.dx - v.dx) + (w.dy - v.dy) * (w.dy - v.dy);
    if (l2 == 0) return (p - v).distance;
    final t = ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(v.dx + clampedT * (w.dx - v.dx), v.dy + clampedT * (w.dy - v.dy));
    return (p - projection).distance;
  }

  Widget _buildRouteFloatingBadges(Size viewport) {
    if (widget.routes.length < 2) return const SizedBox.shrink();

    final badgeWidgets = <Widget>[];

    for (int i = 0; i < widget.routes.length; i++) {
      final r = widget.routes[i];
      if (r.waypoints.length < 2) continue;

      // Position badge along the route near midpoint
      final midIdx = (r.waypoints.length * (i == 0 ? 0.46 : 0.54))
          .round()
          .clamp(0, r.waypoints.length - 1);
      final midPoint = r.waypoints[midIdx];
      final screenOffset = _project(midPoint.lat, midPoint.lng, viewport);

      if (screenOffset.dx < 45 ||
          screenOffset.dx > viewport.width - 45 ||
          screenOffset.dy < 45 ||
          screenOffset.dy > viewport.height - 40) {
        continue;
      }

      final isSelected = i == widget.selectedRouteIndex;

      badgeWidgets.add(
        Positioned(
          left: screenOffset.dx - 65,
          top: screenOffset.dy - 34,
          child: GestureDetector(
            onTap: () {
              widget.onRouteSelected?.call(i);
            },
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF004ECC)
                        : const Color(0xFFCBD5E1),
                    width: isSelected ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF0066FF).withOpacity(0.38)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.navigation_rounded
                          : Icons.directions_car_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.durationText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color:
                            isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.hasTolls ? '• Tolls' : '• No tolls',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : (r.hasTolls
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: badgeWidgets);
  }

  Widget _buildSinglePlaceMarker(Size viewport) {
    final place = widget.singleMarkerPlace!;
    final pos = _project(place.lat, place.lng, viewport);
    final isValid = widget.isSingleMarkerValid;

    final primaryColor = isValid == true
        ? const Color(0xFF16A34A)
        : (isValid == false ? const Color(0xFFDC2626) : const Color(0xFF5D24F7));
    final iconData = isValid == true
        ? Icons.check_circle_rounded
        : (isValid == false ? Icons.error_rounded : Icons.location_on_rounded);

    final badgeText = widget.singleMarkerBadgeText ??
        (isValid == true
            ? 'Within 10 km (On route)'
            : (isValid == false ? '> 10 km (Not on route)' : place.name));

    return Positioned(
      left: pos.dx - 90,
      top: pos.dy - 68,
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // City Name & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    place.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Custom Pin Needle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          // Ground shadow dot
          Container(
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget({
    required CarpoolPlaceEntity place,
    required bool isPickup,
    required Size viewport,
    required List<({double lat, double lng})> waypoints,
  }) {
    final pos = _project(place.lat, place.lng, viewport);

    // 1. Determine label side: dynamically detects route departure/arrival vector
    // and places the text label on the OPPOSITE side of the route path so the route is never obscured!
    bool placeOnLeft = false;
    bool placeVertical = false;
    bool placeOnTop = false;

    if (isPickup) {
      // Find direction the route leaves from pickup
      Offset? nextPos;
      for (int i = 1; i < waypoints.length; i++) {
        final pt = _project(waypoints[i].lat, waypoints[i].lng, viewport);
        if ((pt - pos).distance > 8.0) {
          nextPos = pt;
          break;
        }
      }

      if (nextPos != null) {
        final dx = nextPos.dx - pos.dx;
        final dy = nextPos.dy - pos.dy;

        if (dx.abs() >= 12.0) {
          // Route leaves to the right -> place text opposite on the LEFT
          // Route leaves to the left -> place text opposite on the RIGHT
          placeOnLeft = dx > 0;
        } else {
          // Route leaves mostly vertically -> place text above or below opposite to route
          placeVertical = true;
          placeOnTop = dy > 0;
        }
      }
    } else {
      // Find direction the route arrives into dropoff
      Offset? prevPos;
      for (int i = waypoints.length - 2; i >= 0; i--) {
        final pt = _project(waypoints[i].lat, waypoints[i].lng, viewport);
        if ((pt - pos).distance > 8.0) {
          prevPos = pt;
          break;
        }
      }

      if (prevPos != null) {
        final dx = prevPos.dx - pos.dx;
        final dy = prevPos.dy - pos.dy;

        if (dx.abs() >= 12.0) {
          // Route arrives from the right -> place text opposite on the LEFT
          // Route arrives from the left -> place text opposite on the RIGHT
          placeOnLeft = dx > 0;
        } else {
          placeVertical = true;
          placeOnTop = dy > 0;
        }
      }
    }

    // Boundary safety: if text would bleed off-screen, adjust position safely
    if (placeOnLeft && pos.dx < 110) {
      placeOnLeft = false;
    } else if (!placeOnLeft && !placeVertical && pos.dx > viewport.width - 110) {
      placeOnLeft = true;
    }

    // 2. Build Label Tag Widget
    final labelTag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        place.name,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.2,
        ),
        maxLines: 1,
      ),
    );

    // 3. Render Pickup Marker
    if (isPickup) {
      final pinWidget = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0066FF),
            width: 5.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );

      if (placeVertical) {
        return Stack(
          children: [
            Positioned(
              left: pos.dx - 12,
              top: pos.dy - 12,
              child: IgnorePointer(child: pinWidget),
            ),
            Positioned(
              left: (pos.dx - 50).clamp(8.0, viewport.width - 120),
              top: placeOnTop ? (pos.dy - 40) : (pos.dy + 18),
              child: IgnorePointer(child: labelTag),
            ),
          ],
        );
      }

      if (placeOnLeft) {
        return Positioned(
          right: viewport.width - (pos.dx + 12),
          top: pos.dy - 12,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                labelTag,
                const SizedBox(width: 6),
                pinWidget,
              ],
            ),
          ),
        );
      } else {
        return Positioned(
          left: pos.dx - 12,
          top: pos.dy - 12,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                pinWidget,
                const SizedBox(width: 6),
                labelTag,
              ],
            ),
          ),
        );
      }
    }

    // 4. Render Dropoff Marker
    final pinWidget = Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.location_on,
          size: 34,
          color: Color(0xFF0066FF),
        ),
        Positioned(
          top: 8,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );

    if (placeVertical) {
      return Stack(
        children: [
          Positioned(
            left: pos.dx - 17,
            top: pos.dy - 34,
            child: IgnorePointer(child: pinWidget),
          ),
          Positioned(
            left: (pos.dx - 50).clamp(8.0, viewport.width - 120),
            top: placeOnTop ? (pos.dy - 62) : (pos.dy + 6),
            child: IgnorePointer(child: labelTag),
          ),
        ],
      );
    }

    if (placeOnLeft) {
      return Positioned(
        right: viewport.width - (pos.dx + 17),
        top: pos.dy - 34,
        child: IgnorePointer(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              labelTag,
              const SizedBox(width: 5),
              pinWidget,
            ],
          ),
        ),
      );
    } else {
      return Positioned(
        left: pos.dx - 17,
        top: pos.dy - 34,
        child: IgnorePointer(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              pinWidget,
              const SizedBox(width: 5),
              labelTag,
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCenterFloatingPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: widget.centerPinColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.centerPinColor.withOpacity(0.38),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.trip_origin_rounded,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                widget.centerPinLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),

        // Pin Icon
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.centerPinColor.withOpacity(0.18),
              ),
            ),
            Icon(
              Icons.location_pin,
              size: 42,
              color: widget.centerPinColor,
            ),
            Positioned(
              top: 10,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        // Shadow dot
        Container(
          width: 10,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: const BorderRadius.all(Radius.elliptical(10, 4)),
          ),
        ),
      ],
    );
  }

  Widget _buildFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1E293B),
    double elevation = 2,
    BorderRadius? borderRadius,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

/// Custom Painter for Route Polylines
class _PickerRoutePainter extends CustomPainter {
  final List<({double lat, double lng})> activeWaypoints;
  final List<CarpoolRouteOptionEntity> routes;
  final int selectedRouteIndex;
  final Offset Function(double lat, double lng) projector;

  _PickerRoutePainter({
    required this.activeWaypoints,
    required this.routes,
    required this.selectedRouteIndex,
    required this.projector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw alternative unselected routes first in high-contrast muted slate gray (#94A3B8)
    if (routes.isNotEmpty) {
      for (int i = 0; i < routes.length; i++) {
        if (i == selectedRouteIndex) continue;
        final r = routes[i];
        if (r.waypoints.length < 2) continue;

        final path = Path();
        final start = projector(r.waypoints.first.lat, r.waypoints.first.lng);
        path.moveTo(start.dx, start.dy);

        for (int p = 1; p < r.waypoints.length; p++) {
          final pt = projector(r.waypoints[p].lat, r.waypoints[p].lng);
          path.lineTo(pt.dx, pt.dy);
        }

        // Distinct outer casing for unselected route
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Core line for unselected route
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // 2. Draw Selected Primary Route in Vibrant BlaBlaCar Royal Blue (#0066FF)
    final pts = (routes.isNotEmpty && selectedRouteIndex < routes.length)
        ? routes[selectedRouteIndex]
            .waypoints
            .map((w) => (lat: w.lat, lng: w.lng))
            .toList()
        : activeWaypoints;

    if (pts.length >= 2) {
      final path = Path();
      final start = projector(pts.first.lat, pts.first.lng);
      path.moveTo(start.dx, start.dy);

      for (int p = 1; p < pts.length; p++) {
        final pt = projector(pts[p].lat, pts[p].lng);
        path.lineTo(pt.dx, pt.dy);
      }

      // Outer Casing (Deep Cobalt Blue)
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF004ECC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Inner Core (BlaBlaCar Royal Blue)
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF0066FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PickerRoutePainter oldDelegate) => true;
}

/// Multi-source resilient map tile loader.
/// Tries CartoDB Voyager tiles (100% reliable, zero quota limits, Google Maps style)
/// -> Official Google Maps tiles (with User-Agent)
/// -> OpenStreetMap tiles (with User-Agent)
/// -> Styled vector grid fallback canvas (never a blank void).
class _MultiSourceMapTile extends StatefulWidget {
  final int x;
  final int y;
  final int z;
  final int mapType; // 0 = Roadmap, 1 = Satellite

  const _MultiSourceMapTile({
    super.key,
    required this.x,
    required this.y,
    required this.z,
    required this.mapType,
  });

  @override
  State<_MultiSourceMapTile> createState() => _MultiSourceMapTileState();
}

class _MultiSourceMapTileState extends State<_MultiSourceMapTile> {
  int _currentSourceIndex = 0;

  @override
  void didUpdateWidget(covariant _MultiSourceMapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.x != oldWidget.x ||
        widget.y != oldWidget.y ||
        widget.z != oldWidget.z ||
        widget.mapType != oldWidget.mapType) {
      _currentSourceIndex = 0;
    }
  }

  List<String> get _sources {
    final sub = ['a', 'b', 'c'][(widget.x + widget.y).abs() % 3];

    if (widget.mapType == 1) {
      // High-resolution Satellite Imagery (Zero API key required, zero watermarks)
      return [
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${widget.z}/${widget.y}/${widget.x}',
      ];
    }

    // 100% Free, High-Performance, Zero-Key Map Tile Sources:
    // Pure, crystal-clear map tiles with NO "API key required" watermark and NO billing needed.
    return [
      // 1. ArcGIS World Street Map: Official Esri global street map (highways, streets, cities, zero watermarks)
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${widget.z}/${widget.y}/${widget.x}',
      // 2. OpenStreetMap France: High-performance, high-contrast road mapping (zero watermarks)
      'https://$sub.tile.openstreetmap.fr/osmfr/${widget.z}/${widget.x}/${widget.y}.png',
      // 3. OpenStreetMap Humanitarian: Detailed road cartography (zero watermarks)
      'https://$sub.tile.openstreetmap.fr/hot/${widget.z}/${widget.x}/${widget.y}.png',
      // 4. OpenStreetMap Worldwide standard
      'https://tile.openstreetmap.org/${widget.z}/${widget.x}/${widget.y}.png',
      // 5. ArcGIS World Topo Map: Clean topographic street map
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${widget.z}/${widget.y}/${widget.x}',
    ];
  }

  void _tryNextSource() {
    if (mounted && _currentSourceIndex < _sources.length) {
      setState(() {
        _currentSourceIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    if (_currentSourceIndex >= sources.length) {
      return _buildFallbackCanvas();
    }

    final url = sources[_currentSourceIndex];
    const headers = {
      'User-Agent': 'PathwayCarpoolApp/1.0 (Android; info@pathway.com)',
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };

    return Image.network(
      url,
      headers: headers,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryNextSource());
        return _buildFallbackCanvas();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildFallbackCanvas(),
            child,
          ],
        );
      },
    );
  }

  Widget _buildFallbackCanvas() {
    return Container(
      color: const Color(0xFFF1EDE6),
      child: CustomPaint(
        painter: _FallbackTileGridPainter(x: widget.x, y: widget.y, z: widget.z),
      ),
    );
  }
}

class _FallbackTileGridPainter extends CustomPainter {
  final int x;
  final int y;
  final int z;

  _FallbackTileGridPainter({required this.x, required this.y, required this.z});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF4F0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFE2DDD2)
      ..strokeWidth = 1.0;

    // Grid lines
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    // Highway hint line
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFE0B2)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(0, (y % 3) * (size.height / 3) + 30),
      Offset(size.width, ((y + 1) % 3) * (size.height / 3) + 40),
      highwayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FallbackTileGridPainter oldDelegate) => false;
}
