import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/features/auth/presentation/bloc/auth_bloc.dart';

import '../../core/tour_colors.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_my_bookings_bloc.dart';
import '../bloc/tour_nav_cubit.dart';
import '../bloc/tour_wishlist_bloc.dart';
import '../widgets/tour_widgets.dart';

class TourProfilePage extends StatelessWidget {
  const TourProfilePage({super.key});

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name is coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthBloc?>()?.state.user;
    final storage = AuthLocalStorage();
    final savedName = storage.getFullName()?.trim();
    final savedEmail = storage.getEmail()?.trim();

    final displayName = (authUser != null &&
            authUser.fullName.isNotEmpty &&
            !authUser.fullName.toLowerCase().startsWith('user'))
        ? authUser.fullName
        : ((savedName != null &&
                savedName.isNotEmpty &&
                !savedName.toLowerCase().startsWith('user'))
            ? savedName
            : 'User');

    final displayEmail = (authUser != null && authUser.email.isNotEmpty)
        ? authUser.email
        : ((savedEmail != null && savedEmail.isNotEmpty) ? savedEmail : '');

    final bookingsState = context.watch<TourMyBookingsBloc>().state;
    final wishlistState = context.watch<TourWishlistBloc>().state;

    final bookingCount = bookingsState.bookings.length;
    final wishlistCount = wishlistState.packages.length;
    final completedCount = bookingsState.bookings
        .where((b) => b.status == TourBookingStatus.completed || b.isPast)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          TourHeaderBar(
            title: 'Profile',
            showBack: false,
            centerTitle: true,
            trailing: IconButton(
              onPressed: () => _soon(context, 'Settings'),
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                // 1. User Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: TourColors.promoGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: TourColors.primary.withOpacity(.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayEmail,
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF2FE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.flight_takeoff_rounded,
                              size: 14,
                              color: Color(0xFF3B46E8),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Explorer Member',
                              style: TextStyle(
                                color: Color(0xFF3B46E8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Quick Travel Stats Row
                Row(
                  children: [
                    _StatCard(
                      label: 'Bookings',
                      value: '$bookingCount',
                      icon: Icons.calendar_today_rounded,
                      onTap: () => context.read<TourNavCubit>().select(1),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Wishlist',
                      value: '$wishlistCount',
                      icon: Icons.favorite_border_rounded,
                      onTap: () => context.read<TourNavCubit>().select(2),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Completed',
                      value: '$completedCount',
                      icon: Icons.verified_outlined,
                      onTap: () => context.read<TourNavCubit>().select(1),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Travel Management Section
                _SectionTitle(title: 'Travel Activities'),
                const SizedBox(height: 8),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.event_note_rounded,
                      label: 'My Bookings',
                      subtitle: 'Upcoming, past & cancelled tours',
                      badge: bookingCount > 0 ? '$bookingCount' : null,
                      onTap: () => context.read<TourNavCubit>().select(1),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      subtitle: 'Saved packages & destinations',
                      badge: wishlistCount > 0 ? '$wishlistCount' : null,
                      onTap: () => context.read<TourNavCubit>().select(2),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Account & Preferences Section
                _SectionTitle(title: 'Account & Support'),
                const SizedBox(height: 8),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.payments_outlined,
                      label: 'Payment Methods',
                      subtitle: 'Manage cards, UPI & wallets',
                      onTap: () => _soon(context, 'Payment Methods'),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      subtitle: 'Trip alerts, reminders & offers',
                      onTap: () => _soon(context, 'Notifications'),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.headset_mic_outlined,
                      label: 'Help & Support',
                      subtitle: '24/7 customer assistance & FAQs',
                      onTap: () => _soon(context, 'Help & Support'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 5. App & Navigation Section
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.dashboard_outlined,
                      iconColor: const Color(0xFF3B46E8),
                      label: 'Back to Main Dashboard',
                      subtitle: 'Switch to all mobility & services',
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF3B46E8), size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF3B46E8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B46E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: Color(0xFFF1F5F9),
    );
  }
}
