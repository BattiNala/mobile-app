import 'package:batti_nala/features/profile/controller/profile_state.dart';
import 'package:batti_nala/features/profile/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileNotifier(repository);
    });

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(ProfileState());

  Future<void> fetchProfile(String role) async {
    if (role == 'citizen') {
      await fetchCitizenProfile();
    } else {
      await fetchEmployeeProfile();
    }
  }

  Future<void> fetchCitizenProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _repository.getCitizenProfile();

      state = state.copyWith(citizenProfile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load citizen profile',
      );
    }
  }

  Future<void> fetchEmployeeProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _repository.getEmployeeProfile();

      state = state.copyWith(employeeProfile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load employee profile',
      );
    }
  }
}
