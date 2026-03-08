# Authentication Integration - Implementation Guide

## Overview

Integrated the authentication endpoints into your Flutter MVC architecture using Riverpod state management, Dio HTTP client, and secure token storage.

---

## Architecture Structure

```
lib/features/auth/
├── controllers/
│   ├── auth_controller.dart      (AuthState - UI state management)
│   └── auth_notifier.dart        (AuthNotifier - business logic with API)
├── models/
│   ├── auth_request_model.dart   (LoginRequest, RegisterRequest, RefreshTokenRequest)
│   └── auth_response_model.dart  (AuthResponse, AuthError)
├── repositories/
│   └── auth_repository.dart      (API service layer)
└── view/
    ├── login_screen.dart
    └── signup_screen.dart
```

---

## Core Components

### 1. **Models** (`auth_request_model.dart` & `auth_response_model.dart`)

#### Request Models:

- `LoginRequest`: username, password
- `RegisterRequest`: username, password, name, phone_number, email, home_address
- `RefreshTokenRequest`: refresh_token

#### Response Models:

- `AuthResponse`: access_token, refresh_token, role_name, is_verified (optional)
- `AuthError`: detail (error message)

### 2. **Repository/Service Layer** (`auth_repository.dart`)

Handles all API communication with proper error handling:

```dart
Future<AuthResponse> login({required String username, required String password})
Future<AuthResponse> register({...all required fields...})
Future<AuthResponse> refreshToken()
Future<void> logout()
```

**Features:**

- Automatic token storage to secure storage after successful login/register
- Proper error handling with `DioException` management
- Status code-specific error handling (401 for unauthorized, 400 for bad request)
- Riverpod provider: `authRepositoryProvider`

### 3. **State Management** (`auth_notifier.dart` & `auth_controller.dart`)

#### AuthState:

Manages form UI state:

- `name, phone, email, password, confirmPassword`
- `isPasswordObscured, isConfirmPasswordObscured`
- `isLoading, errorMessage`

#### AuthNotifier:

Business logic methods:

- `updateName(), updateEmail(), updatePhone(), updatePassword(), updateConfirmPassword()`
- `togglePasswordVisibility(), toggleConfirmPasswordVisibility()`
- `login()` - Validates input → calls API → stores tokens → returns boolean
- `signup()` - Validates input → calls API → stores tokens → returns boolean
- `clearError(), resetForm()`

**Provider:**

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
```

---

## API Endpoints Integration

### 1. Login Endpoint

- **Endpoint:** `POST /api/v1/auth/login`
- **Implementation:** `AuthRepository.login()`
- **Flow:**
  1. Validates email/username and password
  2. Makes POST request with `LoginRequest` body
  3. On success (200): Parses `AuthResponse`, saves tokens to secure storage
  4. On failure (401): Throws `AuthError` with "Invalid credentials"

### 2. Register Endpoint

- **Endpoint:** `POST /api/v1/auth/citizen-register`
- **Implementation:** `AuthRepository.register()`
- **Flow:**
  1. Validates all required fields (name, email, phone, password)
  2. Makes POST request with `RegisterRequest` body
  3. On success (200): Parses `AuthResponse`, saves tokens to secure storage
  4. On failure (400): Throws `AuthError` with "User already exists"

### 3. Refresh Token Endpoint

- **Endpoint:** `POST /api/v1/auth/refresh`
- **Implementation:** `AuthRepository.refreshToken()`
- **Usage:** Automatically called by `AuthInterceptor` when access token expires (401 response)
- **Flow:**
  1. Retrieves stored refresh token from secure storage
  2. Makes POST request with `RefreshTokenRequest` body
  3. On success (200): Updates both tokens in secure storage
  4. On failure (401): Clears all tokens and throws `AuthError`

---

## Token Storage

Tokens are stored using [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage):

```dart
StorageServices._accessTokenKey = 'access_token'
StorageServices._refreshTokenKey = 'refresh_token'
StorageServices._userRole = 'user_role'
```

**Methods:**

- `saveAccessToken(String token)` - Save after login/register
- `getAccessToken()` - Retrieved by `AuthInterceptor` for API requests
- `saveRefreshToken(String token)` - Save after login/register
- `getRefreshToken()` - Retrieved when access token expires
- `saveUserRole(String role)` - Save user role for authorization
- `clearAll()` - Clear on logout

---

## Auth Interceptor Integration

**File:** `core/networks/auth_interceptor.dart`

**Automatic Token Handling:**

1. **On Request:**
   - Skips login/register endpoints (no token needed)
   - Adds `Authorization: Bearer <access_token>` header to all other requests

2. **On Error (401 Response):**
   - If refresh token available: Attempts token refresh
   - If refresh fails (401): Clears storage and requires new login
   - Queues requests while refresh is in progress to prevent race conditions

---

## Usage in UI Components

### LoginScreen Implementation:

```dart
// Update form fields
ref.read(authProvider.notifier).updateEmail(value);
ref.read(authProvider.notifier).updatePassword(value);

// Handle login
Future<void> _handleLogin() async {
  final success = await ref.read(authProvider.notifier).login();
  if (success) {
    // Navigate to dashboard
    Navigator.pushReplacementNamed(context, '/staff_dashboard');
  }
  // Errors are automatically shown via listener
}

// Listen for errors
ref.listen(authProvider, (previous, next) {
  if (next.errorMessage != null) {
    SnackbarService.showError(context, next.errorMessage!);
  }
});
```

### SignupScreen Implementation:

```dart
// Update form fields
ref.read(authProvider.notifier).updateName(value);
ref.read(authProvider.notifier).updateEmail(value);
ref.read(authProvider.notifier).updatePhone(value);
ref.read(authProvider.notifier).updatePassword(value);
ref.read(authProvider.notifier).updateConfirmPassword(value);

// Handle signup
Future<void> _handleSignup() async {
  final success = await ref.read(authProvider.notifier).signup();
  if (success) {
    Navigator.pushReplacementNamed(context, '/staff_dashboard');
  }
}
```

---

## Error Handling

### Error Types:

1. **Validation Errors:** Caught in Notifier before API call
2. **API Errors:** Returned as `AuthError` with server detail message
3. **Network Errors:** Generic "Connection error. Please try again." message

### Error Flow:

1. Error occurs → `AuthNotifier` catches it
2. Updates state with `errorMessage`
3. UI listener captures error
4. `SnackbarService.showError()` displays error to user
5. Error clears when user starts typing

---

## Configuration

**API Base URL:** `lib/core/constants/api_url.dart`

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
static const String login = '$baseUrl/auth/login';
static const String citzenRegister = '$baseUrl/auth/citizen-register';
static const String getRefreshToken = '$baseUrl/auth/refresh';
```

**Dependencies:** Already included in `pubspec.yaml`

- `dio: ^5.9.2` - HTTP client
- `flutter_riverpod: ^2.5.1` - State management
- `flutter_secure_storage: ^10.0.0` - Token storage

---

## Key Features

✅ **Secure Token Storage** - Tokens stored in platform-secure storage  
✅ **Automatic Token Refresh** - Handled by interceptor on 401 responses  
✅ **Request Queuing** - Prevents race conditions during token refresh  
✅ **Comprehensive Validation** - Client-side validation before API calls  
✅ **Error Handling** - Specific handling for different error scenarios  
✅ **Loading States** - Loading indicator during API calls  
✅ **MVC Pattern** - Clean separation of concerns  
✅ **Riverpod Integration** - Type-safe dependency injection

---

## Next Steps (Optional Enhancements)

1. Add **Logout endpoint** if backend requires it
2. Implement **Password reset** endpoint
3. Add **Other authentication methods** (Google, Apple, etc.)
4. Create **User model** to store additional user information
5. Add **Role-based access control** using stored role_name
6. Implement **Remember me** functionality

---

## Testing the Integration

1. **Mock API Server:** Ensure backend is running at `http://127.0.0.1:8000`
2. **Test Login:**
   - Enter valid username and password
   - Verify tokens are stored
   - Check API interceptor adds Bearer token to requests

3. **Test Register:**
   - Fill all required fields
   - Verify new user is created
   - Check tokens are automatically stored

4. **Test Token Refresh:**
   - Wait for access token to expire (set short TTL in backend)
   - Make API request
   - Verify interceptor refreshes token automatically
