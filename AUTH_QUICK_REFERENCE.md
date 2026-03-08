# Authentication Integration - Quick Reference

## Files Created

### 1. Models Layer

- **[lib/features/auth/models/auth_request_model.dart](lib/features/auth/models/auth_request_model.dart)**
  - `LoginRequest` → `{ username, password }`
  - `RegisterRequest` → `{ username, password, name, phone_number, email, home_address }`
  - `RefreshTokenRequest` → `{ refresh_token }`

- **[lib/features/auth/models/auth_response_model.dart](lib/features/auth/models/auth_response_model.dart)**
  - `AuthResponse` → `{ access_token, refresh_token, role_name, is_verified? }`
  - `AuthError` → `{ detail }`

### 2. Repository/Service Layer

- **[lib/features/auth/repositories/auth_repository.dart](lib/features/auth/repositories/auth_repository.dart)**
  - `AuthRepository` class with methods:
    - `login(username, password)` → `AuthResponse`
    - `register(username, password, name, phoneNumber, email, homeAddress)` → `AuthResponse`
    - `refreshToken()` → `AuthResponse`
    - `logout()` → `void`
  - Automatic token storage to secure storage
  - Automatic token refresh on 401 responses
  - Provider: `authRepositoryProvider`

## Files Modified

### 1. State Management

- **[lib/features/auth/controllers/auth_controller.dart](lib/features/auth/controllers/auth_controller.dart)**
  - **Added:** `homeAddress: String` field to `AuthState`
  - **Added:** `homeAddress` parameter to `copyWith()` method

- **[lib/features/auth/controllers/auth_notifier.dart](lib/features/auth/controllers/auth_notifier.dart)**
  - **Modified Constructor:** Now accepts `AuthRepository` dependency
  - **Added:** `updateHomeAddress(String homeAddress)` method
  - **Updated:** `login()` method to make actual API calls with validation
  - **Updated:** `signup()` method to make actual API calls with validation
  - **Modified Provider:** Injects `authRepositoryProvider` dependency

## API Endpoints Integrated

| Endpoint          | Method | Path                            | Handler                         |
| ----------------- | ------ | ------------------------------- | ------------------------------- |
| **Login**         | POST   | `/api/v1/auth/login`            | `AuthRepository.login()`        |
| **Register**      | POST   | `/api/v1/auth/citizen-register` | `AuthRepository.register()`     |
| **Refresh Token** | POST   | `/api/v1/auth/refresh`          | `AuthRepository.refreshToken()` |

## Architecture Pattern

```
User Input (UI)
    ↓
AuthNotifier (State Management + Business Logic)
    ↓
AuthRepository (API Service Layer)
    ↓
Dio Client (HTTP + Auth Interceptor)
    ↓
Backend API
    ↓
Secure Storage (Token Management)
```

## Key Implementation Details

### ✅ Login Flow

1. User enters username/email and password
2. `AuthNotifier.login()` validates inputs
3. Calls `AuthRepository.login()`
4. API response parsed as `AuthResponse`
5. Tokens saved to secure storage automatically
6. Returns `true` on success
7. Error message set on failure

### ✅ Register Flow

1. User enters all required fields (name, email, phone, password, home_address)
2. `AuthNotifier.signup()` validates all inputs
3. Calls `AuthRepository.register()`
4. API response parsed as `AuthResponse`
5. Tokens saved to secure storage automatically
6. Returns `true` on success
7. Error message set on failure

### ✅ Token Refresh (Automatic)

- `AuthInterceptor` intercepts all API requests
- Adds `Authorization: Bearer <token>` header
- On 401 response: Automatically calls `AuthRepository.refreshToken()`
- Updates both tokens in secure storage
- Retries original request with new token

### ✅ Logout

- Call `AuthRepository.logout()`
- Clears all tokens from secure storage

## Field Mapping

### Login Request

```json
{
  "username": "email or phone",
  "password": "password"
}
```

### Register Request

```json
{
  "username": "email",
  "password": "password",
  "name": "full name",
  "phone_number": "phone",
  "email": "email",
  "home_address": "address"
}
```

### Auth Response

```json
{
  "access_token": "jwt token",
  "refresh_token": "refresh jwt",
  "role_name": "citizen/staff/admin",
  "is_verified": true
}
```

## State Management Hooks

### In UI Components (e.g., LoginScreen)

```dart
// Watch auth state
final authState = ref.watch(authProvider);

// Update fields
ref.read(authProvider.notifier).updateEmail(value);
ref.read(authProvider.notifier).updatePassword(value);

// Perform login
await ref.read(authProvider.notifier).login();

// Listen for errors
ref.listen(authProvider, (previous, next) {
  if (next.errorMessage != null) {
    SnackbarService.showError(context, next.errorMessage!);
  }
});

// Access loading state
if (authState.isLoading) {
  // Show loading indicator
}
```

## Error Handling

| Error Type        | Source       | Handling                               |
| ----------------- | ------------ | -------------------------------------- |
| Validation Errors | AuthNotifier | Check input before API call            |
| 401 Unauthorized  | API          | Trigger token refresh or clear storage |
| 400 Bad Request   | API          | Display server error message           |
| Network Errors    | DIO          | Display generic error message          |

## Testing Checklist

- [ ] Backend running at `http://127.0.0.1:8000`
- [ ] Login with valid credentials → Dashboard
- [ ] Register with new user → Dashboard + tokens saved
- [ ] Login after token expiry → Auto refresh works
- [ ] Invalid credentials → Shows error message
- [ ] Network error → Shows connection error
- [ ] Logout → Tokens cleared

## Dependencies

All required dependencies already in `pubspec.yaml`:

- ✅ `dio: ^5.9.2` - HTTP client
- ✅ `flutter_riverpod: ^2.5.1` - State management
- ✅ `flutter_secure_storage: ^10.0.0` - Token storage

## Next Steps

1. **UI Updates (Optional):**
   - Add home address input field to signup screen
   - Update signup form validation

2. **Backend Integration (Required):**
   - Verify backend endpoints match API spec
   - Test with actual backend

3. **Security (Optional):**
   - Implement rate limiting
   - Add request signing
   - Implement CSRF protection

4. **Features (Optional):**
   - Password reset endpoint
   - Social authentication
   - Multi-factor authentication
