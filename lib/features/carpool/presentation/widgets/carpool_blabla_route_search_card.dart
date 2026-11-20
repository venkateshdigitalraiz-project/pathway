import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/carpool_location_picker_bloc.dart';

/// BlaBlaCar-style route search card containing either:
/// 1. Single-step search field (Step 1: Pick-up, Step 2: Drop-off) for published ride flow.
/// 2. Dual-step search fields with connected vertical dotted line and location swap.
class CarpoolBlaBlaRouteSearchCard extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final FocusNode pickupFocusNode;
  final FocusNode dropoffFocusNode;
  final ValueChanged<String> onPickupChanged;
  final ValueChanged<String> onDropoffChanged;
  final VoidCallback onClearPickup;
  final VoidCallback onClearDropoff;
  final bool isSingleStepMode;
  final String? confirmedPickupName;

  const CarpoolBlaBlaRouteSearchCard({
    super.key,
    required this.pickupController,
    required this.dropoffController,
    required this.pickupFocusNode,
    required this.dropoffFocusNode,
    required this.onPickupChanged,
    required this.onDropoffChanged,
    required this.onClearPickup,
    required this.onClearDropoff,
    this.isSingleStepMode = true,
    this.confirmedPickupName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarpoolLocationPickerBloc, CarpoolLocationPickerState>(
      builder: (context, state) {
        final bool isPickupActive = state.step == CarpoolLocationStep.pickup;
        final bool isDropoffActive =
            state.step == CarpoolLocationStep.dropoff ||
            state.step == CarpoolLocationStep.routeReady;

        if (isSingleStepMode) {
          return _buildSingleStepSearchCard(context, state, isPickupActive);
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Route Connector Icons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5D24F7),
                              width: 3.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 24,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: CustomPaint(
                            painter: _DottedLinePainter(
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Middle: Pick-up and Drop-off Text Fields
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Pick-up Input
                          InkWell(
                            onTap: () {
                              context.read<CarpoolLocationPickerBloc>().add(
                                    const CarpoolLocationPickerStepChanged(
                                      CarpoolLocationStep.pickup,
                                    ),
                                  );
                              pickupFocusNode.requestFocus();
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: pickupController,
                                    focusNode: pickupFocusNode,
                                    onChanged: onPickupChanged,
                                    onTap: () {
                                      context
                                          .read<CarpoolLocationPickerBloc>()
                                          .add(
                                            const CarpoolLocationPickerStepChanged(
                                              CarpoolLocationStep.pickup,
                                            ),
                                          );
                                    },
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isPickupActive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Pick-up (City, town, village...)',
                                      hintStyle: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                if (pickupController.text.isNotEmpty && isPickupActive)
                                  GestureDetector(
                                    onTap: onClearPickup,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE2E8F0),
                          ),

                          // 2. Drop-off Input
                          InkWell(
                            onTap: () {
                              context.read<CarpoolLocationPickerBloc>().add(
                                    const CarpoolLocationPickerStepChanged(
                                      CarpoolLocationStep.dropoff,
                                    ),
                                  );
                              dropoffFocusNode.requestFocus();
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: dropoffController,
                                    focusNode: dropoffFocusNode,
                                    onChanged: onDropoffChanged,
                                    onTap: () {
                                      context
                                          .read<CarpoolLocationPickerBloc>()
                                          .add(
                                            const CarpoolLocationPickerStepChanged(
                                              CarpoolLocationStep.dropoff,
                                            ),
                                          );
                                    },
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isDropoffActive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Drop-off (City, town, village...)',
                                      hintStyle: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                if (dropoffController.text.isNotEmpty && isDropoffActive)
                                  GestureDetector(
                                    onTap: onClearDropoff,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right: Swap Locations Button
                    InkWell(
                      onTap: () {
                        context.read<CarpoolLocationPickerBloc>().add(
                              const CarpoolLocationPickerSwapLocations(),
                            );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          size: 18,
                          color: Color(0xFF5D24F7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Bottom quick actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      context.read<CarpoolLocationPickerBloc>().add(
                            const CarpoolLocationPickerSelectCurrentLocation(),
                          );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: isPickupActive
                                ? const Color(0xFF5D24F7)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPickupActive
                                ? 'Use my location for pick-up'
                                : 'Use my location for drop-off',
                            style: TextStyle(
                              color: isPickupActive
                                  ? const Color(0xFF5D24F7)
                                  : const Color(0xFFEF4444),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPickupActive
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPickupActive ? 'STEP 1: PICK-UP' : 'STEP 2: DROP-OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPickupActive
                            ? const Color(0xFF5D24F7)
                            : const Color(0xFFEF4444),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleStepSearchCard(
    BuildContext context,
    CarpoolLocationPickerState state,
    bool isPickupActive,
  ) {
    final activeController =
        isPickupActive ? pickupController : dropoffController;
    final activeFocusNode =
        isPickupActive ? pickupFocusNode : dropoffFocusNode;
    final activeOnChanged =
        isPickupActive ? onPickupChanged : onDropoffChanged;
    final activeOnClear = isPickupActive ? onClearPickup : onClearDropoff;
    final accentColor =
        isPickupActive ? const Color(0xFF5D24F7) : const Color(0xFFEF4444);
    final hint = isPickupActive
        ? 'Pick-up (City, town, village...)'
        : 'Drop-off (City, town, village...)';
    final pickupName = confirmedPickupName ?? state.pickupPlace?.name;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPickupActive && pickupName != null && pickupName.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: Color(0xFF5D24F7),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Leaving from: $pickupName',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5D24F7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isPickupActive
                          ? Icons.trip_origin_rounded
                          : Icons.location_on_rounded,
                      color: accentColor,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: activeController,
                    focusNode: activeFocusNode,
                    onChanged: activeOnChanged,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (activeController.text.isNotEmpty)
                  GestureDetector(
                    onTap: activeOnClear,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 17,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  context.read<CarpoolLocationPickerBloc>().add(
                        const CarpoolLocationPickerSelectCurrentLocation(),
                      );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPickupActive
                            ? 'Use my location for pick-up'
                            : 'Use my location for drop-off',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPickupActive
                      ? const Color(0xFFEDE9FE)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPickupActive ? 'STEP 1: PICK-UP' : 'STEP 2: DROP-OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 3.0;
    const double dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
