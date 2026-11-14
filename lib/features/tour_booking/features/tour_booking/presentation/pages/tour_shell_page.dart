import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tour_injector.dart';
import '../bloc/tour_booking_bloc.dart';
import '../bloc/tour_home_bloc.dart';
import '../bloc/tour_my_bookings_bloc.dart';
import '../bloc/tour_nav_cubit.dart';
import '../bloc/tour_wishlist_bloc.dart';
import '../widgets/tour_widgets.dart';
import 'tour_home_page.dart';
import 'tour_my_bookings_page.dart';
import 'tour_profile_page.dart';
import 'tour_wishlist_page.dart';

/// Entry point of the Tour Booking module (route: `/tour`).
/// Provides all module-wide blocs and hosts the 4 bottom tabs.
class TourShellPage extends StatelessWidget {
  const TourShellPage({super.key});

  static const List<Widget> _tabs = [
    TourHomePage(),
    TourMyBookingsPage(),
    TourWishlistPage(),
    TourProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final di = TourInjector.I;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TourNavCubit()),
        BlocProvider(create: (_) => di.homeBloc()..add(const TourHomeStarted())),
        BlocProvider(
            create: (_) => di.wishlistBloc()..add(const TourWishlistStarted())),
        BlocProvider(
            create: (_) =>
                di.myBookingsBloc()..add(const TourMyBookingsStarted())),
        BlocProvider<TourBookingBloc>(create: (_) => di.bookingBloc()),
      ],
      child: BlocBuilder<TourNavCubit, int>(
        builder: (context, index) {
          return PopScope(
            canPop: index == 0,
            onPopInvoked: (didPop) {
              if (!didPop) context.read<TourNavCubit>().select(0);
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: IndexedStack(index: index, children: _tabs),
              bottomNavigationBar: TourBottomNav(
                currentIndex: index,
                onTap: context.read<TourNavCubit>().select,
              ),
            ),
          );
        },
      ),
    );
  }
}
