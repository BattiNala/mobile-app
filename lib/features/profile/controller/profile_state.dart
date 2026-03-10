import 'package:batti_nala/features/profile/model/profile_response_model.dart';

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final CitizenProfile? citizenProfile;
  final EmployeeProfile? employeeProfile;

  ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.citizenProfile,
    this.employeeProfile,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    CitizenProfile? citizenProfile,
    EmployeeProfile? employeeProfile,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      citizenProfile: citizenProfile ?? this.citizenProfile,
      employeeProfile: employeeProfile ?? this.employeeProfile,
    );
  }
}
