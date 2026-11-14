import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_booking_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_customer_details_page.dart';

/// Screen 4: "Book Your Trip" – date, travellers, package type, add-ons.
class TourBookTripPage extends StatefulWidget {
  const TourBookTripPage({super.key, required this.package});
  final TourPackageEntity package;

  @override
  State<TourBookTripPage> createState() => _TourBookTripPageState();
}

class _TourBookTripPageState extends State<TourBookTripPage> {
  @override
  void initState() {
    super.initState();
    // (Re)starts the module-wide booking flow for this package.
    context.read<TourBookingBloc>().add(TourBookingStarted(widget.package));
  }

  IconData _addOnIcon(String id) =>
      id == 'insurance' ? Icons.shield_rounded : Icons.airport_shuttle_rounded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<TourBookingBloc, TourBookingState>(
        builder: (context, s) {
          final bloc = context.read<TourBookingBloc>();
          final pkg = s.package;
          final date = s.travelDate;
          if (pkg == null || pkg.id != widget.package.id || date == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              const TourHeaderBar(title: 'Book Your Trip', centerTitle: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TourColors.border),
                        ),
                        child: TourPackageSummary(package: pkg),
                      ),
                      const SizedBox(height: 22),
                      const TourSectionTitle('Select Travel Date'),
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(now.year, now.month, now.day + 1),
                            lastDate: now.add(const Duration(days: 540)),
                          );
                          if (picked != null) {
                            bloc.add(TourBookingDateChanged(picked));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TourColors.tile,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TourColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: TourColors.chip,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.calendar_month_rounded,
                                    color: TourColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(TourFormatters.dateLong(date),
                                        style: AppTypography.bodyLarge
                                            .copyWith(fontWeight: FontWeight.w600)),
                                    Text('(${TourFormatters.weekday(date)})',
                                        style: AppTypography.bodyMedium),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: TourColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const TourSectionTitle('Number of Travellers'),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TourColors.border),
                        ),
                        child: Row(
                          children: [
                            _StepBtn(
                                icon: Icons.remove_rounded,
                                onTap: () => bloc.add(
                                    const TourBookingTravellersChanged(-1))),
                            Expanded(
                              child: Text(TourFormatters.adults(s.travellers),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleMedium
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                            _StepBtn(
                                icon: Icons.add_rounded,
                                onTap: () => bloc.add(
                                    const TourBookingTravellersChanged(1))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const TourSectionTitle('Package Type'),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeTile(
                              label: 'Standard',
                              price: pkg.priceFor(TourPackageType.standard),
                              selected: s.packageType == TourPackageType.standard,
                              onTap: () => bloc.add(
                                  const TourBookingPackageTypeChanged(
                                      TourPackageType.standard)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TypeTile(
                              label: 'Premium',
                              price: pkg.priceFor(TourPackageType.premium),
                              selected: s.packageType == TourPackageType.premium,
                              onTap: () => bloc.add(
                                  const TourBookingPackageTypeChanged(
                                      TourPackageType.premium)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const TourSectionTitle('Add-ons (Optional)'),
                      for (final a in s.addOns)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => bloc.add(TourBookingAddOnToggled(a.id)),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: s.selectedAddOnIds.contains(a.id),
                                  activeColor: TourColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  onChanged: (_) =>
                                      bloc.add(TourBookingAddOnToggled(a.id)),
                                ),
                                const SizedBox(width: 4),
                                Icon(_addOnIcon(a.id),
                                    color: TourColors.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name,
                                          style: AppTypography.bodyLarge
                                              .copyWith(fontSize: 14.5)),
                                      Text(
                                          a.perPerson
                                              ? '${TourFormatters.rupee(a.price)} / Person'
                                              : TourFormatters.rupee(a.price),
                                          style: AppTypography.bodyMedium
                                              .copyWith(fontSize: 12.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: TourColors.border.withOpacity(.6))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontSize: 12.5)),
                          Text(TourFormatters.rupee(s.total),
                              style: AppTypography.titleLarge
                                  .copyWith(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: CustomButton(
                          text: 'Continue →',
                          height: 54,
                          backgroundColor: TourColors.primary,
                          onPressed: () => TourNavigator.push(
                              context, const TourCustomerDetailsPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 42,
          decoration: BoxDecoration(
            color: TourColors.chip,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: TourColors.primary),
        ),
      );
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : TourColors.text;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? TourColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? TourColors.primary : TourColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(label,
                    style: AppTypography.bodyLarge
                        .copyWith(color: fg, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 2),
            Text(TourFormatters.rupee(price),
                style: AppTypography.bodyLarge
                    .copyWith(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
