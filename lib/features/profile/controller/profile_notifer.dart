import 'package:batti_nala/features/profile/controller/profile_state.dart';
import 'package:batti_nala/features/profile/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileNotifier(ref, repository);
    });

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;
  final ProfileRepository _repository;

  ProfileNotifier(this.ref, this._repository) : super(ProfileState());

  Future<void> fetchProfile(String role) async {
    final roleLower = role.toLowerCase();
    if (roleLower == 'citizen') {
      await fetchCitizenProfile();
    } else if (roleLower == 'staff') {
      await fetchEmployeeProfile();
    }
  }

  Future<void> fetchCitizenProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _repository.getCitizenProfile();

      if (!mounted) return;
      state = state.copyWith(citizenProfile: profile, isLoading: false);
    } catch (e) {
      if (!mounted) return;
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

      if (!mounted) return;
      state = state.copyWith(employeeProfile: profile, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load employee profile',
      );
    }
  }
}
