import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/carpool_status.dart';
import '../../data/datasources/carpool_settings_local_data_source.dart';
import '../../domain/entities/carpool_settings_entity.dart';
import '../bloc/carpool_profile_bloc.dart';
import '../bloc/carpool_settings_bloc.dart';

/// Clean Architecture Carpool Settings Screen.
/// Dynamically connects to CarpoolSettingsBloc (and /api/settings/carpool)
/// to display active Safety Advisories, Cancellation Policy, Fare Limits, and Preferences.
class CarpoolSettingsPage extends StatelessWidget {
  final CarpoolSettingsBloc? settingsBloc;
  final CarpoolProfileBloc? profileBloc;

  const CarpoolSettingsPage({
    super.key,
    this.settingsBloc,
    this.profileBloc,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = const _SettingsView();

    if (profileBloc != null) {
      content = BlocProvider.value(value: profileBloc!, child: content);
    }
    if (settingsBloc != null) {
      content = BlocProvider.value(value: settingsBloc!, child: content);
    }

    return content;
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  void _snack(BuildContext c, String name) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text('$name is up to date'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clean Architecture with BLoC: Retrieve dynamic settings from CarpoolSettingsBloc
    CarpoolSettingsEntity settings = CarpoolSettingsStorage.current;
    bool isLoading = false;

    try {
      final settingsState = context.watch<CarpoolSettingsBloc>().state;
      isLoading = settingsState.status == CarpoolStatus.loading;
      if (settingsState.settings.pricePerKm > 0 ||
          settingsState.settings.safetyAdvisories.isNotEmpty ||
          settingsState.settings.cancellationPolicy.isNotEmpty) {
        settings = settingsState.settings;
      }
    } catch (_) {
      settings = CarpoolSettingsStorage.current;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDE8FF),
              Color(0xFFF7F5FE),
              Colors.white,
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFF5D24F7),
            onRefresh: () async {
              try {
                context.read<CarpoolSettingsBloc>().add(
                      const FetchCarpoolSettingsEvent(forceRefresh: true),
                    );
              } catch (_) {}
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                // ── 1. Top Navigation Bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF140D43),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Carpool Settings',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF140D43),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Official safety advisories & platform rules',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B658C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5D24F7),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF5D24F7),
                            size: 22,
                          ),
                          onPressed: () {
                            try {
                              context.read<CarpoolSettingsBloc>().add(
                                    const FetchCarpoolSettingsEvent(
                                      forceRefresh: true,
                                    ),
                                  );
                            } catch (_) {}
                          },
                          visualDensity: VisualDensity.compact,
                          splashRadius: 20,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── 2. DYNAMIC SAFETY ADVISORIES (From API Response) ───────
                _buildSafetyAdvisoriesSection(context, settings.safetyAdvisories),

                const SizedBox(height: 18),

                // ── 3. GENERAL APP PREFERENCES ─────────────────────────────
                _buildAppPreferencesCard(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. DYNAMIC SAFETY ADVISORIES SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSafetyAdvisoriesSection(
    BuildContext context,
    List<CarpoolSafetyAdvisoryEntity> advisories,
  ) {
    if (advisories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE8FF)),
        ),
        child: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text(
              'No active safety advisories currently reported.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B658C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 15,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Safety & Security Advisories',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF140D43),
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                '${advisories.length} Active Notice',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...advisories.map((adv) => _buildSingleAdvisoryCard(context, adv)),
      ],
    );
  }

  Widget _buildSingleAdvisoryCard(
    BuildContext context,
    CarpoolSafetyAdvisoryEntity adv,
  ) {
    final bool isSecurity =
        adv.severity.toLowerCase().contains('security') ||
        adv.severity.toLowerCase().contains('warning') ||
        adv.severity.toLowerCase().contains('danger');

    final Color cardBg =
        isSecurity ? const Color(0xFFFFFBEB) : const Color(0xFFF7F5FE);
    final Color cardBorder =
        isSecurity ? const Color(0xFFFDE68A) : const Color(0xFFEDE8FF);
    final Color badgeBg =
        isSecurity ? const Color(0xFFFEF3C7) : const Color(0xFFEDE8FF);
    final Color badgeFg =
        isSecurity ? const Color(0xFFB45309) : const Color(0xFF5D24F7);
    final IconData badgeIcon =
        isSecurity ? Icons.shield_rounded : Icons.info_outline_rounded;

    final List<String> modules = adv.module;
    final List<String> platforms = adv.platform;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isSecurity ? const Color(0xFFF59E0B) : const Color(0xFF5D24F7))
                .withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(badgeIcon, color: badgeFg, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adv.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isSecurity
                            ? const Color(0xFF78350F)
                            : const Color(0xFF140D43),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (adv.id.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        'ID: ${adv.id}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isSecurity
                              ? const Color(0xFF92400E).withOpacity(0.8)
                              : const Color(0xFF8B85A8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (adv.severity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 10, color: badgeFg),
                      const SizedBox(width: 3),
                      Text(
                        adv.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeFg,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Message Body
          Text(
            adv.message,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isSecurity
                  ? const Color(0xFF78350F).withOpacity(0.95)
                  : const Color(0xFF4B4668),
              height: 1.45,
            ),
          ),

          // Line 1: Module (e.g. "carpool")
          if (modules.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: modules.map(
                (m) => _buildMiniTag(
                  label: m,
                  icon: Icons.directions_car_rounded,
                  bgColor: Colors.white,
                  fgColor: const Color(0xFF059669),
                  borderColor: const Color(0xFFA7F3D0),
                ),
              ).toList(),
            ),
          ],

          // Line 2: Next line Wrap widget with platform texts ("checkout", "chat", "banner", "ticket")
          if (platforms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: platforms.map(
                (p) => _buildMiniTag(
                  label: p,
                  bgColor: Colors.white,
                  fgColor: isSecurity
                      ? const Color(0xFFB45309)
                      : const Color(0xFF5D24F7),
                  borderColor: cardBorder,
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniTag({
    required String label,
    IconData? icon,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. GENERAL APP PREFERENCES CARD
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAppPreferencesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE8FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D24F7).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _SettingsRow(
              icon: Icons.notifications_rounded,
              title: 'Notification Settings',
              subtitle: 'Ride alerts & push messages',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8B85A8),
                size: 20,
              ),
              onTap: () => _snack(context, 'Notifications'),
            ),
            const _SettingsDivider(),

            _SettingsRow(
              icon: Icons.translate_rounded,
              title: 'Language',
              subtitle: 'English (US)',
              onTap: () => _snack(context, 'Language'),
            ),
            const _SettingsDivider(),

            _SettingsRow(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQs & dispute assistance',
              onTap: () => _snack(context, 'Help & Support'),
            ),
          ],
        ),
      ),
    );
  }

}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF5D24F7), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: Color(0xFF140D43),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF6B658C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8B85A8),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F0FD),
    );
  }
}
