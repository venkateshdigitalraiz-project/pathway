abstract class TourUseCase<Type, Params> {
  Future<Type> call(Params params);
}

class TourNoParams {
  const TourNoParams();
}
