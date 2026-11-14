import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/tour_formatters.dart';
import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_my_bookings_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_detail_page.dart';

/// Screen 8: "My Bookings".
class TourMyBookingsPage extends StatelessWidget {
  const TourMyBookingsPage({super.key});

  static const _packageAssets = <String, String>{
    'p1': 'assets/images/tour_maldives.jpg',
    'p2': 'assets/images/tour_switzerland.jpg',
    'p3': 'assets/images/tour_bali.jpg',
    'p5': 'assets/images/tour_bali.jpg',
    'p6': 'assets/images/tour_dubai.jpg',
    'p7': 'assets/images/tour_switzerland.jpg',
    'maldives': 'assets/images/tour_maldives.jpg',
    'bali': 'assets/images/tour_bali.jpg',
    'dubai': 'assets/images/tour_dubai.jpg',
    'switzerland': 'assets/images/tour_switzerland.jpg',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TourMyBookingsBloc, TourMyBookingsState>(
      listenWhen: (p, c) => c.message != null && p.message != c.message,
      listener: (context, s) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.message!))),
      builder: (context, state) {
        final items = state.visible;
        return Column(
          children: [
            TourHeaderBar(
              title: 'My Bookings',
              showBack: false,
              trailing: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => context.read<TourMyBookingsBloc>().add(
                            TourMyBookingsTabChanged(i),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: state.tabIndex == i
                                  ? const Color(0xFF3B46E8)
                                  : const Color(0xFFF4F6F9),
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: Text(
                              ['Upcoming', 'Past', 'Cancelled'][i],
                              style: AppTypography.labelMedium.copyWith(
                                color: state.tabIndex == i
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  state.status == TourStatus.loading && state.bookings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                state.tabIndex == 0
                                    ? 'No upcoming trips.\nFind a package and start planning!'
                                    : state.tabIndex == 1
                                    ? 'No past trips yet.'
                                    : 'No cancelled bookings.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          )
                        else
                          for (final b in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _BookingCard(booking: b),
                            ),
                        const SizedBox(height: 6),
                        const _TravelTips(),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final TourBookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final p = booking.package;
    final assetPath =
        TourMyBookingsPage._packageAssets[p.id] ??
        TourMyBookingsPage._packageAssets[p.location.toLowerCase()] ??
        TourMyBookingsPage._packageAssets[p.title.toLowerCase()] ??
        'assets/images/tour_maldives.jpg';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 95,
              height: 145,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => TourImage(
                  seedKey: p.id,
                  url: p.coverImage,
                  width: 95,
                  height: 145,
                  radius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TourStatusChip(status: booking.status),
                ),
                const SizedBox(height: 4),
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                TourMetaRow(
                  icon: Icons.calendar_month_outlined,
                  text: TourFormatters.range(
                    booking.travelDate,
                    booking.endDate,
                  ),
                ),
                const SizedBox(height: 4),
                TourMetaRow(
                  icon: Icons.person_outline_rounded,
                  text: TourFormatters.travellers(booking.travellers),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => TourNavigator.push(
                    context,
                    TourDetailPage(
                      packageId: booking.package.id,
                      heroImage: assetPath,
                    ),
                  ),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC7D2FE),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B46E8).withOpacity(.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFF3B46E8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF3B46E8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelTips extends StatelessWidget {
  const _TravelTips();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Tips',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Carry valid ID and check\nyour travel documents.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF475569),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/tour_luggage.png',
            width: 62,
            height: 70,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
