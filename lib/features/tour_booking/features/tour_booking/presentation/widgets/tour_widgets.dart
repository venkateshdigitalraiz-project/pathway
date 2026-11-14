import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_wishlist_bloc.dart';

// ---------------------------------------------------------------------------
// Image with graceful gradient fallback (no assets required)
// ---------------------------------------------------------------------------
class TourImage extends StatelessWidget {
  const TourImage({
    super.key,
    this.url = '',
    this.assetPath,
    this.seedKey = '',
    this.icon = Icons.landscape_rounded,
    this.radius = BorderRadius.zero,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.child,
  });

  final String url;
  final String? assetPath;
  final String seedKey;
  final IconData icon;
  final BorderRadius radius;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? child;

  static const _assetById = <String, String>{
    'p1': 'assets/images/tour_maldives.jpg', // Maldives Getaway
    'p2': 'assets/images/tour_europe.jpg', // Europe Highlights
    'p3': 'assets/images/tour_kerala.jpg', // Kerala Bliss
    'p4': 'assets/images/tour_singapore.jpg', // Singapore Tour
    'p5': 'assets/images/tour_bali.jpg', // Bali Escape
    'p6': 'assets/images/tour_dubai.jpg', // Dubai Delight
    'p7': 'assets/images/tour_switzerland.jpg', // Swiss Alps
    'd1': 'assets/images/tour_bali.jpg',
    'd2': 'assets/images/tour_dubai.jpg',
    'd3': 'assets/images/tour_switzerland.jpg',
    'bali': 'assets/images/tour_bali.jpg',
    'dubai': 'assets/images/tour_dubai.jpg',
    'switzerland': 'assets/images/tour_switzerland.jpg',
    'maldives': 'assets/images/tour_maldives.jpg',
    'europe': 'assets/images/tour_europe.jpg',
    'kerala': 'assets/images/tour_kerala.jpg',
    'singapore': 'assets/images/tour_singapore.jpg',
  };

  static String? assetForPackage(String? id) {
    if (id == null) return null;
    return _assetById[id.toLowerCase()];
  }

  static const _byId = <String, List<Color>>{
    'p1': [Color(0xFF38BDF8), Color(0xFF0F766E)], // Maldives
    'p2': [Color(0xFFFBBF24), Color(0xFF7C2D12)], // Europe
    'p3': [Color(0xFF86EFAC), Color(0xFF14532D)], // Kerala
    'p4': [Color(0xFF60A5FA), Color(0xFF1E1B4B)], // Singapore
    'p5': [Color(0xFF6EE7B7), Color(0xFF065F46)], // Bali
    'p6': [Color(0xFFFB923C), Color(0xFF4C1D95)], // Dubai
    'p7': [Color(0xFF93C5FD), Color(0xFF1E3A8A)], // Switzerland
  };
  static const _fallback = [
    [Color(0xFF38BDF8), Color(0xFF0F766E)],
    [Color(0xFFFB923C), Color(0xFF4C1D95)],
    [Color(0xFF93C5FD), Color(0xFF1E3A8A)],
  ];

  List<Color> get _colors =>
      _byId[seedKey] ?? _fallback[seedKey.hashCode.abs() % _fallback.length];

  Widget _placeholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _colors,
      ),
    ),
    child: Center(
      child: Icon(icon, color: Colors.white.withOpacity(.35), size: 46),
    ),
  );

  Widget _buildContent() {
    final effectiveAsset = (assetPath != null && assetPath!.isNotEmpty)
        ? assetPath
        : _assetById[seedKey.toLowerCase()];

    if (effectiveAsset != null && effectiveAsset.isNotEmpty) {
      return Image.asset(
        effectiveAsset,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [_buildContent(), if (child != null) child!],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// White header bar (title left, optional back + trailing)
// ---------------------------------------------------------------------------
class TourHeaderBar extends StatelessWidget {
  const TourHeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
    this.centerTitle = false,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54,
          child: NavigationToolbar(
            leading: showBack
                ? IconButton(
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF0F172A),
                    ),
                  )
                : const SizedBox(width: 48),
            middle: Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18.5,
                color: const Color(0xFF0F172A),
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: trailing ?? const SizedBox(width: 40),
            ),
            centerMiddle: centerTitle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wishlist heart (reads TourWishlistBloc)
// ---------------------------------------------------------------------------
class TourWishlistButton extends StatelessWidget {
  const TourWishlistButton({
    super.key,
    required this.packageId,
    this.size = 34,
    this.dark = false,
  });

  final String packageId;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourWishlistBloc, TourWishlistState>(
      buildWhen: (p, c) => p.isSaved(packageId) != c.isSaved(packageId),
      builder: (context, state) {
        final saved = state.isSaved(packageId);
        return GestureDetector(
          onTap: () => context.read<TourWishlistBloc>().add(
            TourWishlistToggled(packageId),
          ),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? Colors.black.withOpacity(.3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: saved
                  ? const Color(0xFFFF4D6A)
                  : (dark ? Colors.white : const Color(0xFF94A3B8)),
              size: size * .62,
            ),
          ),
        );
      },
    );
  }
}

class TourRatingRow extends StatelessWidget {
  const TourRatingRow({
    super.key,
    required this.rating,
    required this.reviewsLabel,
    this.size = 13,
  });
  final double rating;
  final String reviewsLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, color: TourColors.star, size: 18),
      const SizedBox(width: 3),
      Text(
        rating.toStringAsFixed(1),
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: size + 1,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '($reviewsLabel reviews)',
        style: AppTypography.bodyMedium.copyWith(fontSize: size),
      ),
    ],
  );
}

class TourDiscountChip extends StatelessWidget {
  const TourDiscountChip({
    super.key,
    required this.percent,
    this.large = false,
  });
  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(large ? 14 : 9),
      ),
      child: Text(
        '$percent% OFF',
        style: AppTypography.labelMedium.copyWith(
          color: const Color(0xFFEF4444),
          fontWeight: FontWeight.w800,
          fontSize: large ? 13 : 11,
        ),
      ),
    );
  }
}

class TourPriceRow extends StatelessWidget {
  const TourPriceRow({super.key, required this.package, this.big = false});
  final TourPackageEntity package;
  final bool big;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 6,
    runSpacing: 2,
    children: [
      Text(
        TourFormatters.rupee(package.price),
        style: AppTypography.titleLarge.copyWith(
          fontSize: big ? 26 : 19,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
      if (package.originalPrice > package.price)
        Text(
          TourFormatters.rupee(package.originalPrice),
          style: AppTypography.bodyMedium.copyWith(
            fontSize: big ? 15 : 12.5,
            color: const Color(0xFF94A3B8),
            decoration: TextDecoration.lineThrough,
          ),
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Package card – vertical (image on top) or horizontal (image on left)
// ---------------------------------------------------------------------------
class TourPackageCard extends StatelessWidget {
  const TourPackageCard({
    super.key,
    required this.package,
    required this.onTap,
    this.horizontal = false,
  });

  final TourPackageEntity package;
  final VoidCallback onTap;
  final bool horizontal;

  BoxDecoration get _box => BoxDecoration(
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
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _box,
        clipBehavior: Clip.antiAlias,
        child: horizontal ? _horizontal() : _vertical(),
      ),
    );
  }

  Widget _vertical() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TourImage(
        seedKey: package.id,
        url: package.coverImage,
        height: 140,
        width: double.infinity,
        radius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TourWishlistButton(
              packageId: package.id,
              size: 34,
              dark: true,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17.5,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF3B46E8),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${package.location} • ${package.duration}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TourRatingRow(
              rating: package.rating,
              reviewsLabel: TourFormatters.reviewsShort(package.reviewCount),
              size: 13,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TourPriceRow(package: package)),
                TourDiscountChip(percent: package.discountPercent),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _horizontal() => SizedBox(
    height: 146,
    child: Row(
      children: [
        TourImage(
          seedKey: package.id,
          url: package.coverImage,
          width: 132,
          height: 146,
          radius: const BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        package.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TourWishlistButton(
                      packageId: package.id,
                      size: 28,
                      dark: false,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF3B46E8),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${package.location} • ${package.nights}N / ${package.days}D',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                TourRatingRow(
                  rating: package.rating,
                  reviewsLabel: TourFormatters.reviewsShort(
                    package.reviewCount,
                  ),
                  size: 12,
                ),
                Row(
                  children: [
                    Expanded(child: TourPriceRow(package: package)),
                    TourDiscountChip(percent: package.discountPercent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Small summary row (thumbnail + title + duration)
// ---------------------------------------------------------------------------
class TourPackageSummary extends StatelessWidget {
  const TourPackageSummary({super.key, required this.package, this.subtitle});
  final TourPackageEntity package;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TourImage(
          seedKey: package.id,
          url: package.coverImage,
          width: 76,
          height: 62,
          radius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                package.title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 14,
                    color: TourColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle ?? package.duration,
                    style: AppTypography.bodyMedium.copyWith(
                      color: TourColors.text,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TourStatusChip extends StatelessWidget {
  const TourStatusChip({super.key, required this.status});
  final TourBookingStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color fg;
    late final Color bg;
    late final IconData? icon;
    switch (status) {
      case TourBookingStatus.confirmed:
        label = 'Confirmed';
        fg = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
        icon = Icons.check_circle_rounded;
        break;
      case TourBookingStatus.pending:
        label = 'Pending';
        fg = TourColors.info;
        bg = TourColors.infoSurface;
        icon = null;
        break;
      case TourBookingStatus.completed:
        label = 'Completed';
        fg = TourColors.muted;
        bg = TourColors.chip;
        icon = null;
        break;
      case TourBookingStatus.cancelled:
        label = 'Cancelled';
        fg = TourColors.error;
        bg = TourColors.errorSurface;
        icon = null;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class TourPillButton extends StatelessWidget {
  const TourPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 38,
  });
  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: TourColors.primary, width: 1.4),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: TourColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    ),
  );
}

class TourMetaRow extends StatelessWidget {
  const TourMetaRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 15, color: TourColors.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: TourColors.text,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class TourSectionTitle extends StatelessWidget {
  const TourSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 17,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Payment option metadata
// ---------------------------------------------------------------------------
class TourPaymentOption {
  const TourPaymentOption(this.method, this.label, this.subtitle, this.icon);
  final TourPaymentMethod method;
  final String label;
  final String? subtitle;
  final IconData icon;

  static const all = [
    TourPaymentOption(
      TourPaymentMethod.upi,
      'UPI',
      null,
      Icons.qr_code_2_rounded,
    ),
    TourPaymentOption(
      TourPaymentMethod.card,
      'Credit / Debit Card',
      null,
      Icons.credit_card_rounded,
    ),
    TourPaymentOption(
      TourPaymentMethod.netBanking,
      'Net Banking',
      null,
      Icons.account_balance_rounded,
    ),
    TourPaymentOption(
      TourPaymentMethod.wallet,
      'Wallets',
      '(GPay, PhonePe, Paytm)',
      Icons.account_balance_wallet_rounded,
    ),
    TourPaymentOption(
      TourPaymentMethod.payLater,
      'Pay Later',
      '(JustPay)',
      Icons.event_available_rounded,
    ),
  ];

  static TourPaymentOption of(TourPaymentMethod m) =>
      all.firstWhere((o) => o.method == m);
}

// ---------------------------------------------------------------------------
// Bottom navigation: Home · My Bookings · Wishlist · Profile
// ---------------------------------------------------------------------------
class TourBottomNav extends StatelessWidget {
  const TourBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label) {
      final selected = i == currentIndex;
      final color = selected ? TourColors.primary : TourColors.muted;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: TourColors.border.withOpacity(.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              item(0, Icons.home_rounded, 'Home'),
              item(1, Icons.event_note_rounded, 'My Bookings'),
              item(2, Icons.favorite_border_rounded, 'Wishlist'),
              item(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
