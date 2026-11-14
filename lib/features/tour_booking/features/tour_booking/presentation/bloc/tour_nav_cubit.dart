import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom tabs: 0 Home, 1 My Bookings, 2 Wishlist, 3 Profile.
class TourNavCubit extends Cubit<int> {
  TourNavCubit() : super(0);
  void select(int index) => emit(index);
}
