import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/tour_colors.dart';
import '../bloc/tour_booking_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_payment_page.dart';

/// Screen 5: "Customer Details".
class TourCustomerDetailsPage extends StatefulWidget {
  const TourCustomerDetailsPage({super.key});

  @override
  State<TourCustomerDetailsPage> createState() =>
      _TourCustomerDetailsPageState();
}

class _TourCustomerDetailsPageState extends State<TourCustomerDetailsPage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final s = context.read<TourBookingBloc>().state;
    _name = TextEditingController(text: s.name);
    _email = TextEditingController(text: s.email);
    _phone = TextEditingController(text: s.phone);
    _notes = TextEditingController(text: s.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _icon(IconData i) => Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: TourColors.chip,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(i, color: TourColors.text, size: 21),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TourBookingBloc>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TourHeaderBar(title: 'Customer Details', centerTitle: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) => bloc.add(TourBookingNameChanged(v)),
                    decoration: InputDecoration(
                        labelText: 'Full Name', prefixIcon: _icon(Icons.person_outline_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => bloc.add(TourBookingEmailChanged(v)),
                    decoration: InputDecoration(
                        labelText: 'Email Address', prefixIcon: _icon(Icons.mail_outline_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (v) => bloc.add(TourBookingPhoneChanged(v)),
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixText: '+91  ',
                      prefixIcon: _icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text.rich(
                    TextSpan(
                      text: 'Special Requests ',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(
                            text: '(Optional)',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    onChanged: (v) => bloc.add(TourBookingNotesChanged(v)),
                    decoration:
                        const InputDecoration(hintText: 'Any special request...'),
                  ),
                  const SizedBox(height: 14),
                  BlocBuilder<TourBookingBloc, TourBookingState>(
                    buildWhen: (p, c) => p.agreed != c.agreed,
                    builder: (context, s) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: s.agreed,
                          activeColor: TourColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          onChanged: (v) =>
                              bloc.add(TourBookingTermsToggled(v ?? false)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: TourColors.text),
                                children: [
                                  TextSpan(
                                      text: 'Terms & Conditions',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: TourColors.primary)),
                                  const TextSpan(text: '\nand '),
                                  TextSpan(
                                      text: 'Privacy Policy',
                                      style: AppTypography.bodyMedium.copyWith(
                                          color: TourColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'Proceed to Pay →',
                height: 54,
                backgroundColor: TourColors.primary,
                onPressed: () {
                  final error = bloc.state.detailsError;
                  if (error != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                    return;
                  }
                  TourNavigator.push(context, const TourPaymentPage());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
