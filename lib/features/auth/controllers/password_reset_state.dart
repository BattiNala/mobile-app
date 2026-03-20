enum PasswordResetStep {
  requestOtp,
  verifyOtp,
  confirmPassword,
}

class PasswordResetState {
  final PasswordResetStep step;
  final bool isLoading;
  final String? errorMessage;

  final String username;
  final String otpCode;
  final String newPassword;
  final String confirmPassword;
  final String? resetToken;

  final String? successMessage;

  const PasswordResetState({
    required this.step,
    required this.isLoading,
    required this.errorMessage,
    required this.username,
    required this.otpCode,
    required this.newPassword,
    required this.confirmPassword,
    required this.resetToken,
    required this.successMessage,
  });

  const PasswordResetState.initial()
      : step = PasswordResetStep.requestOtp,
        isLoading = false,
        errorMessage = null,
        username = '',
        otpCode = '',
        newPassword = '',
        confirmPassword = '',
        resetToken = null,
        successMessage = null;

  PasswordResetState copyWith({
    PasswordResetStep? step,
    bool? isLoading,
    String? errorMessage,
    String? username,
    String? otpCode,
    String? newPassword,
    String? confirmPassword,
    String? resetToken,
    String? successMessage,
  }) {
    return PasswordResetState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      username: username ?? this.username,
      otpCode: otpCode ?? this.otpCode,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      resetToken: resetToken ?? this.resetToken,
      successMessage: successMessage,
    );
  }
}

