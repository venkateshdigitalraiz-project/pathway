import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SaveUserDetailsUseCase {
  final AuthRepository repository;

  const SaveUserDetailsUseCase(this.repository);

  Future<UserProfile> call({
    required String fullName,
    required String email,
    String? reference,
    required String gender,
  }) async {
    return await repository.saveUserDetails(
      fullName: fullName,
      email: email,
      reference: reference,
      gender: gender,
    );
  }
}
