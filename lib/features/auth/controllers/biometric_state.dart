class BiometricState {
  final bool isAvailable;
  final bool isEnabled; // true when the currently signed-in user has biometric saved
  final bool isAuthenticating;
  final bool shouldPromptSetup;
  final String? storedUsername; // email of the current signed-in user (if enabled)
  final List<String> savedAccounts; // all emails with biometric saved on this device
  final String? error;

  const BiometricState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.isAuthenticating = false,
    this.shouldPromptSetup = false,
    this.storedUsername,
    this.savedAccounts = const [],
    this.error,
  });

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    bool? isAuthenticating,
    bool? shouldPromptSetup,
    String? storedUsername,
    bool clearStoredUsername = false,
    List<String>? savedAccounts,
    String? error,
  }) {
    return BiometricState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      shouldPromptSetup: shouldPromptSetup ?? this.shouldPromptSetup,
      storedUsername:
          clearStoredUsername ? null : (storedUsername ?? this.storedUsername),
      savedAccounts: savedAccounts ?? this.savedAccounts,
      error: error,
    );
  }
}
