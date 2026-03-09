import 'package:batti_nala/core/models/user_model.dart';

class AuthState {
  final String name;
  final String phone;
  final String? email;
  final String homeAddress;
  final String password;
  final String confirmPassword;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final String verificationCode;
  final bool isVerified;
  final String? verificationMessage;

  AuthState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.homeAddress = '',
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.verificationCode = '',
    this.isVerified = false,
    this.verificationMessage,
  });

  AuthState copyWith({
    String? name,
    String? phone,
    String? email,
    String? homeAddress,
    String? password,
    String? confirmPassword,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    bool? isLoading,
    String? errorMessage,
    User? user,
    String? verificationCode,
    bool? isVerified,
    String? verificationMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      homeAddress: homeAddress ?? this.homeAddress,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: clearUser ? null : (user ?? this.user),
      verificationCode: verificationCode ?? this.verificationCode,
      isVerified: isVerified ?? this.isVerified,
      verificationMessage: verificationMessage ?? this.verificationMessage,
    );
  }
}
