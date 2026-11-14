import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pathway/core/theme/app_typography.dart';

import '../bloc/tour_nav_cubit.dart';
import '../bloc/tour_wishlist_bloc.dart';
import '../tour_navigator.dart';
import '../widgets/tour_widgets.dart';
import 'tour_detail_page.dart';

class TourWishlistPage extends StatelessWidget {
  const TourWishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TourHeaderBar(
          title: 'Wishlist',
          onBack: () => context.read<TourNavCubit>().select(0),
        ),
        Expanded(
          child: BlocBuilder<TourWishlistBloc, TourWishlistState>(
            builder: (context, state) {
              if (state.packages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Your wishlist is empty.\nTap the heart on a package to save it here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final p = state.packages[i];
                  return TourPackageCard(
                    package: p,
                    horizontal: i.isOdd,
                    onTap: () => TourNavigator.push(
                      context,
                      TourDetailPage(
                        packageId: p.id,
                        heroImage: TourImage.assetForPackage(p.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
