import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/theme/party_theme.dart';
import 'package:pathway/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pathway/features/auth/presentation/bloc/auth_event.dart';

import '../../domain/entities/party_entities.dart';
import '../bloc/party_favorites_bloc.dart';
import '../bloc/party_my_bookings_bloc.dart';
import '../bloc/party_nav_cubit.dart';
import '../widgets/party_widgets.dart';

class PartyProfilePage extends StatelessWidget {
  const PartyProfilePage({super.key});

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name is coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: Color(0xFF140D43),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access your account.',
          style: TextStyle(color: Color(0xFF6B658C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Stay',
              style: TextStyle(
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        context.read<PartyNavCubit>().select(0);
        context.read<AuthBloc>().add(LogoutEvent());
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = 'Venkatesh Kumar';
    String displayEmail = 'venkatesh@gmail.com';
    try {
      final user = context.watch<AuthBloc>().state.user;
      if (user != null && user.fullName.isNotEmpty) {
        displayName = user.fullName;
      }
      if (user != null && user.email.isNotEmpty) {
        displayEmail = user.email;
      }
    } catch (_) {}

    final bookingsState = context.watch<PartyMyBookingsBloc>().state;
    final favoritesState = context.watch<PartyFavoritesBloc>().state;

    final bookingCount = bookingsState.bookings.length;
    final favoritesCount = favoritesState.venues.length;
    final completedCount = bookingsState.bookings
        .where((b) => b.status == PartyBookingStatus.completed || !b.isUpcoming)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          PartyHeaderBar(
            title: 'Profile',
            showBack: false,
            trailing: IconButton(
              onPressed: () => _soon(context, 'Settings'),
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
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
                        color: const Color(0xFF4A21C4).withOpacity(.05),
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
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: PartyTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: PartyTheme.primary.withOpacity(.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 46,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
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
                          color: const Color(0xFF140D43),
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
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F1FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.celebration_rounded,
                              size: 15,
                              color: Color(0xFF4A21C4),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'VIP Party Host',
                              style: TextStyle(
                                color: Color(0xFF4A21C4),
                                fontSize: 12.5,
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

                // 2. Quick Stats Row
                Row(
                  children: [
                    _StatCard(
                      label: 'Bookings',
                      value: '$bookingCount',
                      icon: Icons.calendar_month_rounded,
                      onTap: () => context.read<PartyNavCubit>().select(1),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Favorites',
                      value: '$favoritesCount',
                      icon: Icons.favorite_rounded,
                      onTap: () => context.read<PartyNavCubit>().select(2),
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Completed',
                      value: '$completedCount',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => context.read<PartyNavCubit>().select(1),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Party & Events Section
                _SectionTitle(title: 'Party & Events'),
                const SizedBox(height: 8),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.event_note_rounded,
                      label: 'My Bookings',
                      subtitle: 'Upcoming & past event reservations',
                      badge: bookingCount > 0 ? '$bookingCount' : null,
                      onTap: () => context.read<PartyNavCubit>().select(1),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.favorite_border_rounded,
                      label: 'Saved Favorites',
                      subtitle: 'Venues, clubs & party spaces you saved',
                      badge: favoritesCount > 0 ? '$favoritesCount' : null,
                      onTap: () => context.read<PartyNavCubit>().select(2),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.celebration_rounded,
                      label: 'Explore Venues',
                      subtitle: 'Discover trending clubs & banquet halls',
                      onTap: () => context.read<PartyNavCubit>().select(0),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Booking & Planning Section
                _SectionTitle(title: 'Account & Planning'),
                const SizedBox(height: 8),
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.payments_outlined,
                      label: 'Payment Methods',
                      subtitle: 'Cards, UPI & advance payment options',
                      onTap: () => _soon(context, 'Payment Methods'),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Event Notifications',
                      subtitle: 'Booking alerts & special discounts',
                      onTap: () => _soon(context, 'Event Notifications'),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.headset_mic_outlined,
                      label: 'Help & Support',
                      subtitle: '24/7 event planning assistance & FAQs',
                      onTap: () => _soon(context, 'Help & Support'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 5. Navigation & Logout Section
                _MenuCard(
                  children: [
                    _MenuTile(
                      icon: Icons.dashboard_outlined,
                      iconColor: PartyTheme.primary,
                      label: 'Back to Main Dashboard',
                      subtitle: 'Switch to all mobility & services',
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .maybePop(),
                    ),
                    const _Divider(),
                    _MenuTile(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFE53935),
                      label: 'Log Out',
                      subtitle: 'Sign out of your account',
                      onTap: () => _logout(context),
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
                color: const Color(0xFF4A21C4).withOpacity(.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF4A21C4), size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF140D43),
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
            color: const Color(0xFF4A21C4).withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
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
                  color: const Color(0xFFF3F1FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF4A21C4),
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
                        color: const Color(0xFF140D43),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A21C4),
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
