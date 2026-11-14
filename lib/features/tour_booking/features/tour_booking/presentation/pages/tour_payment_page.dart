import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../core/tour_status.dart';
import '../bloc/tour_booking_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_booking_confirmed_page.dart';

/// Screen 6: "Payment".
class TourPaymentPage extends StatelessWidget {
  const TourPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TourBookingBloc, TourBookingState>(
      listenWhen: (p, c) =>
          (c.error != null && p.error != c.error) ||
          (p.status != c.status && c.status == TourStatus.success),
      listener: (context, s) {
        if (s.status == TourStatus.success && s.booking != null) {
          TourNavigator.replace(
              context, TourBookingConfirmedPage(booking: s.booking!));
        } else if (s.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s.error!)));
        }
      },
      builder: (context, s) {
        final bloc = context.read<TourBookingBloc>();
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              const TourHeaderBar(title: 'Payment', centerTitle: true),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    const TourSectionTitle('Select Payment Method'),
                    for (final o in TourPaymentOption.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () =>
                              bloc.add(TourBookingPaymentSelected(o.method)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: s.payment == o.method
                                  ? TourColors.tile
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: s.payment == o.method
                                    ? TourColors.primary
                                    : TourColors.border,
                                width: s.payment == o.method ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(o.icon,
                                    color: TourColors.primary, size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.label,
                                          style: AppTypography.bodyLarge
                                              .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5)),
                                      if (o.subtitle != null)
                                        Text(o.subtitle!,
                                            style: AppTypography.bodyMedium
                                                .copyWith(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  s.payment == o.method
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: s.payment == o.method
                                      ? TourColors.primary
                                      : TourColors.subtle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TourColors.tile,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: TourColors.success, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Your payment information\nis secure and encrypted',
                            style: AppTypography.bodyMedium
                                .copyWith(color: TourColors.text, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SafeArea(
                  top: false,
                  child: CustomButton(
                    text: 'Pay ${TourFormatters.rupee(s.total)}',
                    height: 54,
                    backgroundColor: TourColors.primary,
                    isLoading: s.status == TourStatus.loading,
                    onPressed: () => bloc.add(const TourBookingPayPressed()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
