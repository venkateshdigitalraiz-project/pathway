import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/storage/auth_local_storage.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/features/auth/presentation/bloc/auth_bloc.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../core/tour_status.dart';
import '../bloc/tour_home_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_detail_page.dart';
import 'tour_packages_page.dart';

class TourHomePage extends StatelessWidget {
  const TourHomePage({super.key});

  static const _tileStyle = <String, _TileStyle>{
    'international': _TileStyle(
      Icons.flight_rounded,
      Color(0xFF1D61E7),
      Color(0xFFE8F1FF),
    ),
    'domestic': _TileStyle(
      Icons.location_on_rounded,
      Color(0xFFEF4444),
      Color(0xFFFFECEF),
    ),
    'honeymoon': _TileStyle(
      Icons.beach_access_rounded,
      Color(0xFF16A34A),
      Color(0xFFEAF8ED),
    ),
    'weekend': _TileStyle(
      Icons.star_rounded,
      Color(0xFFF59E0B),
      Color(0xFFFFF7E6),
    ),
  };

  static const _destinationAssets = <String, String>{
    'd1': 'assets/images/tour_bali.jpg',
    'd2': 'assets/images/tour_dubai.jpg',
    'd3': 'assets/images/tour_switzerland.jpg',
    'bali': 'assets/images/tour_bali.jpg',
    'dubai': 'assets/images/tour_dubai.jpg',
    'switzerland': 'assets/images/tour_switzerland.jpg',
  };

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocBuilder<TourHomeBloc, TourHomeState>(
        builder: (context, state) {
          final width = MediaQuery.of(context).size.width;
          final cardWidth = (width - 40 - 24) / 3;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Hero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    for (final c in state.categories)
                      Expanded(
                        child: _CategoryTile(
                          label: c.name,
                          style:
                              _tileStyle[c.id] ??
                              const _TileStyle(
                                Icons.explore_rounded,
                                TourColors.primary,
                                TourColors.tile,
                              ),
                          onTap: () => TourNavigator.push(
                            context,
                            TourPackagesPage(categoryId: c.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Popular Destinations',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          TourNavigator.push(context, const TourPackagesPage()),
                      child: Text(
                        'See all →',
                        style: AppTypography.labelMedium.copyWith(
                          color: TourColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 150,
                child:
                    state.status == TourStatus.loading &&
                        state.destinations.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final d = state.destinations[i];
                          final assetPath =
                              _destinationAssets[d.id] ??
                              _destinationAssets[d.name.toLowerCase()];
                          return GestureDetector(
                            onTap: () => TourNavigator.push(
                              context,
                              TourDetailPage(
                                packageId: d.packageId,
                                heroImage: assetPath,
                              ),
                            ),
                            child: TourImage(
                              assetPath: assetPath,
                              seedKey: d.packageId,
                              url: d.imageUrl,
                              width: cardWidth,
                              height: 150,
                              radius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(.6),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyLarge
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      'from ${TourFormatters.rupee(d.fromPrice)}',
                                      style: AppTypography.bodySmall
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: _PromoBanner(
                  onTap: () =>
                      TourNavigator.push(context, const TourPackagesPage()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TileStyle {
  const _TileStyle(this.icon, this.color, this.background);
  final IconData icon;
  final Color color;
  final Color background;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.style,
    required this.onTap,
  });
  final String label;
  final _TileStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(style.icon, color: style.color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label == 'Weekend Getaway' ? 'Weekend\nGetaway' : label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final authUser = context.watch<AuthBloc?>()?.state.user;
    final storageName = AuthLocalStorage().getFullName()?.trim();
    final displayName = (authUser != null &&
            authUser.fullName.isNotEmpty &&
            !authUser.fullName.toLowerCase().startsWith('user'))
        ? authUser.fullName.split(' ').first
        : ((storageName != null &&
                storageName.isNotEmpty &&
                !storageName.toLowerCase().startsWith('user'))
            ? storageName.split(' ').first
            : null);

    return SizedBox(
      height: 345 + top,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/tour_hero_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.12),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.15),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'India',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (displayName != null) ...[
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hi, $displayName',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(.4),
                                offset: const Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  'Explore the\nWorld Together',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover amazing tour packages\nfor your next journey',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(.95),
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(.25),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 36,
            child: GestureDetector(
              onTap: () => TourNavigator.push(
                context,
                const TourPackagesPage(openSearch: true),
              ),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: TourColors.muted),
                    const SizedBox(width: 10),
                    Text(
                      'Search destinations or packages...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: TourColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/tour_promo_banner.jpg',
          width: double.infinity,
          height: 112,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
