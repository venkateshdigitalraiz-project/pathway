import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_my_bookings_bloc.dart';
import '../bloc/tour_nav_cubit.dart';
import '../tour_navigator.dart';
import '../widgets/tour_painters.dart';
import '../widgets/tour_widgets.dart';

/// Screen 7: "Booking Confirmed!".
class TourBookingConfirmedPage extends StatelessWidget {
  const TourBookingConfirmedPage({super.key, required this.booking});
  final TourBookingEntity booking;

  void _go(BuildContext context, int tab) {
    context.read<TourMyBookingsBloc>().add(const TourMyBookingsStarted());
    context.read<TourNavCubit>().select(tab);
    TourNavigator.popToShell(context);
  }

  String get _invoiceText => [
        'INVOICE – ${booking.reference}',
        booking.package.title,
        'Travel: ${TourFormatters.range(booking.travelDate, booking.endDate)}',
        'Travellers: ${booking.travellers}',
        'Customer: ${booking.customerName} (${booking.email})',
        'Total paid: ${TourFormatters.rupee(booking.totalAmount)}',
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    final pkg = booking.package;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _go(context, 0);
      },
      child: Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: TourColors.confirmedGradient),
          child: Stack(
            children: [
              const Positioned.fill(
                  child: CustomPaint(painter: TourConfettiPainter())),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 36, 16, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: TourColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: TourColors.success.withOpacity(.4),
                                blurRadius: 22,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 56),
                      ),
                      const SizedBox(height: 20),
                      Text('Booking Confirmed!',
                          style: AppTypography.displayMedium
                              .copyWith(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        'Your tour package has been booked\nsuccessfully.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w400,
                            color: TourColors.muted),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: TourColors.chip,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('Booking ID',
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: TourColors.text)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(booking.reference,
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded,
                                          size: 16, color: TourColors.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: booking.reference));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Booking ID copied')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: TourColors.primary.withOpacity(.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            TourImage(
                              seedKey: pkg.id,
                              url: pkg.coverImage,
                              width: 84,
                              height: 70,
                              radius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pkg.title,
                                      style: AppTypography.titleMedium.copyWith(
                                          fontWeight: FontWeight.w800)),
                                  Text(pkg.duration,
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: TourColors.text, fontSize: 12.5)),
                                  Text(
                                      TourFormatters.range(
                                          booking.travelDate, booking.endDate),
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: TourColors.text, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _OutlineButton(
                        label: 'View Booking',
                        onTap: () => _go(context, 1),
                      ),
                      const SizedBox(height: 10),
                      _OutlineButton(
                        label: 'Download Invoice',
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: _invoiceText));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Invoice details copied')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Back to Home',
                        height: 50,
                        backgroundColor: TourColors.primary,
                        onPressed: () => _go(context, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomButton(
        text: label,
        height: 48,
        backgroundColor: Colors.white,
        textColor: TourColors.primary,
        borderSide: const BorderSide(color: TourColors.primary, width: 1.4),
        onPressed: onTap,
      );
}
