import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/tour_booking_bloc.dart';
import 'bloc/tour_my_bookings_bloc.dart';
import 'bloc/tour_nav_cubit.dart';
import 'bloc/tour_wishlist_bloc.dart';

/// In-module navigation helper.
///
/// Pushed pages live outside the shell's widget subtree, so the module-wide
/// blocs are forwarded with `BlocProvider.value`. Child routes are tagged so
/// [popToShell] never pops the host app's own routes.
class TourNavigator {
  TourNavigator._();

  static const String childRouteName = 'tour_child';

  static Widget _scoped(BuildContext context, Widget page) {
    final wishlist = context.read<TourWishlistBloc>();
    final bookings = context.read<TourMyBookingsBloc>();
    final nav = context.read<TourNavCubit>();
    final booking = context.read<TourBookingBloc>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<TourWishlistBloc>.value(value: wishlist),
        BlocProvider<TourMyBookingsBloc>.value(value: bookings),
        BlocProvider<TourNavCubit>.value(value: nav),
        BlocProvider<TourBookingBloc>.value(value: booking),
      ],
      child: page,
    );
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    final scoped = _scoped(context, page);
    return Navigator.of(context).push<T>(MaterialPageRoute<T>(
      settings: const RouteSettings(name: childRouteName),
      builder: (_) => scoped,
    ));
  }

  static Future<T?> replace<T>(BuildContext context, Widget page) {
    final scoped = _scoped(context, page);
    return Navigator.of(context).pushReplacement<T, dynamic>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: childRouteName),
        builder: (_) => scoped,
      ),
    );
  }

  /// Pops every Tour child page and lands back on the Tour shell.
  static void popToShell(BuildContext context) {
    Navigator.of(context)
        .popUntil((route) => route.settings.name != childRouteName);
  }
}
