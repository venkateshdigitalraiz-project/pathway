import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';
import 'package:pathway/core/widgets/custom_button.dart';

import '../../core/tour_colors.dart';
import '../../core/tour_formatters.dart';
import '../../core/tour_injector.dart';
import '../../core/tour_status.dart';
import '../../domain/entities/tour_entities.dart';
import '../bloc/tour_detail_bloc.dart';
import '../bloc/tour_wishlist_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_book_trip_page.dart';

/// Screen 3: package details.
class TourDetailPage extends StatelessWidget {
  const TourDetailPage({
    super.key,
    required this.packageId,
    this.heroImage,
  });
  final String packageId;
  final String? heroImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TourInjector.I.detailBloc()..add(TourDetailStarted(packageId)),
      child: _DetailView(heroImage: heroImage),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({this.heroImage});
  final String? heroImage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourDetailBloc, TourDetailState>(
      builder: (context, state) {
        final p = state.package;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: state.status == TourStatus.failure
                  ? Text(state.error ?? 'Could not load this package.')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Gallery(
                      package: p,
                      index: state.imageIndex,
                      heroImage: heroImage,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TourRatingRow(
                            rating: p.rating,
                            reviewsLabel: TourFormatters.reviewsFull(
                              p.reviewCount,
                            ),
                            size: 14,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TourPriceRow(package: p, big: true),
                              const Spacer(),
                              TourDiscountChip(
                                percent: p.discountPercent,
                                large: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: TourColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  p.location,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const VerticalDivider(width: 1),
                                const SizedBox(width: 14),
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 20,
                                  color: TourColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  p.duration,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'About This Package',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.description,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              height: 1.45,
                              color: TourColors.muted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _Included(
                                icon: Icons.flight_rounded,
                                label: 'Flights',
                                included: p.includesFlights,
                              ),
                              _Included(
                                icon: Icons.bed_rounded,
                                label: 'Hotels',
                                included: p.includesHotels,
                              ),
                              _Included(
                                icon: Icons.directions_car_rounded,
                                label: 'Transfers',
                                included: p.includesTransfers,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Itinerary Highlights',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final h in p.highlights)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    color: TourColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      h,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _BottomBar(package: p),
            ],
          ),
        );
      },
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.package,
    required this.index,
    this.heroImage,
  });
  final TourPackageEntity package;
  final int index;
  final String? heroImage;

  Widget _circle(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final count = package.imageCount;
    final effectiveAsset = heroImage ?? TourImage.assetForPackage(package.id);
    final galleryHeight = (media.size.height * 0.38).clamp(310.0, 360.0);

    return SizedBox(
      height: galleryHeight + top,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 22,
            child: PageView.builder(
              itemCount: count,
              onPageChanged: (i) =>
                  context.read<TourDetailBloc>().add(TourDetailImageChanged(i)),
              itemBuilder: (_, i) => TourImage(
                url: i < package.imageUrls.length ? package.imageUrls[i] : '',
                assetPath: effectiveAsset,
                seedKey: package.id,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _circle(
                  Icons.arrow_back_ios_new_rounded,
                  () => Navigator.maybePop(context),
                ),
                const Spacer(),
                BlocBuilder<TourWishlistBloc, TourWishlistState>(
                  builder: (context, wish) {
                    final saved = wish.isSaved(package.id);
                    return GestureDetector(
                      onTap: () => context.read<TourWishlistBloc>().add(
                        TourWishlistToggled(package.id),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              saved ? const Color(0xFFFF4D6A) : Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${index + 1}/$count',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Included extends StatelessWidget {
  const _Included({
    required this.icon,
    required this.label,
    required this.included,
  });
  final IconData icon;
  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: TourColors.tile,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: included ? TourColors.primary : TourColors.subtle,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: TourColors.text,
                fontSize: 12.5,
              ),
            ),
            Text(
              included ? 'Included' : 'Not included',
              style: AppTypography.bodySmall.copyWith(
                color: TourColors.muted,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.package});
  final TourPackageEntity package;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: TourColors.border.withOpacity(.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            BlocBuilder<TourWishlistBloc, TourWishlistState>(
              builder: (context, wish) {
                final saved = wish.isSaved(package.id);
                return GestureDetector(
                  onTap: () => context.read<TourWishlistBloc>().add(
                    TourWishlistToggled(package.id),
                  ),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: TourColors.chip,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: TourColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Book Now',
                height: 54,
                backgroundColor: TourColors.primary,
                onPressed: () => TourNavigator.push(
                  context,
                  TourBookTripPage(package: package),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
