# BattiNala

A civic infrastructure issue reporting and management application built with Flutter. The system enables citizens to report infrastructure hazards (potholes, broken poles, damaged sewage) with photo evidence, while assigning resolution tasks to staff members who can navigate to locations using integrated GPS and mapping capabilities.

---

## Features

### Citizen Features

- Issue Reporting - Report infrastructure hazards with photo evidence and precise location data
- Automated Issue Analysis - Automatic categorization using image processing
- Status Tracking - Real-time monitoring of reported issues from assignment through resolution
- Location Services - Automatic address detection using GPS and reverse geocoding
- Secure Authentication - Email/phone authentication with OTP verification
- User Profile - Personal information management and reporting history

### Staff Features

- Issue Assignment Dashboard - View assigned tasks with priority classification
- Map Navigation - Route planning to issue locations using OpenStreetMap integration
- GPS Tracking - Real-time position tracking for field operations
- Status Management - Update issue status through defined workflow states
- Documentation - Attach verification photos as proof of work completion
- Team Coordination - Role-based access control for different staff levels

### System-Wide Features

- Role-Based Access Control - Separate dashboards and features for Citizens and Staff
- Advanced Geocoding - Multi-tier geocoding strategy for location accuracy
- Token Management - Automatic JWT token refresh for session persistence
- Secure Local Storage - Encrypted storage of authentication tokens
- Consistent UI Framework - Unified design with custom color theme
- Deep Linking Support - Direct navigation via application links

---

## Prerequisites

Before setup, ensure the following are installed and available:

### System Requirements

- Flutter SDK: Version 3.9.2 or higher
- Dart: Included with Flutter installation
- Android Studio (for Android development) or Xcode (for iOS development)
- Git version control system

### API Requirements

- Gemini API Key - Available from Google AI Studio (https://aistudio.google.com/app/apikey)
- Backend Server - Running at http://127.0.0.1:8000 (configurable)

### Device Permissions Required

The application requires the following permissions:

- Location Services - GPS access for mapping and geolocation
- Camera Access - Photo capture of reported issues
- Photo Library - Image selection from device storage
- File Storage - Image caching and data persistence

---

## Getting Started

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd batti_nala
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Obtain Gemini API Key

1. Visit https://aistudio.google.com/app/apikey
2. Click "Get API Key" or "Create API Key"
3. Select "Create API key in new project"
4. Copy the generated API key (format: AIzaSy...)
5. Reference the Configuration section below to add the key to your application

### Step 4: Configure Backend Connection

Update the backend API endpoint in lib/core/constants/app_constants.dart:

```dart
const String apiBaseUrl = 'http://127.0.0.1:8000';
```

### Step 5: Run the Application

#### For Android

```bash
flutter run -d android
```

#### For iOS

```bash
flutter run -d ios
```

#### For Web

```bash
flutter run -d web
```

#### Automatic Device Selection

```bash
flutter run
```

---

## Configuration

### Adding Gemini API Key

Important: Do not commit API keys to version control.

1. Open lib/main.dart
2. Locate the geminiApiKey configuration parameter
3. Replace the placeholder with your actual API key:
   ```dart
   geminiApiKey: '',
   ```

#### Production Deployment

For production environments, use environment variables:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
```

Access the variable in code:

```dart
const String? geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
```

### Backend Configuration

Update lib/core/constants/app_constants.dart with your backend details:

```dart
class AppConstants {
  static const String apiBaseUrl = 'your_backend_url';
  static const String apiTimeout = '30000'; // milliseconds
}
```

---

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/                     # Shared utilities and infrastructure
│   ├── constants/           # API URLs, theme colors, layout constants
│   ├── error/              # Custom exceptions and error handling
│   ├── networks/           # Dio HTTP client, interceptors, API configuration
│   ├── router/             # GoRouter navigation definitions and route guards
│   ├── services/           # External service integrations (Gemini, Location, etc.)
│   └── utils/              # Utility functions and helpers
│
└── features/                # Feature modules
    ├── auth/               # Authentication and session management
    ├── citizen_dashboard/  # Citizen interface and dashboard
    ├── onboarding/         # Welcome screens and initial setup
    ├── profile/            # User profile management
    ├── shared/             # Shared components across features
    │   ├── issue/         # Shared issue models and logic
    │   ├── models/        # Global models (User, Issue, etc.)
    │   └── widgets/       # Reusable UI components
    ├── staff-issue/        # Staff issue management and tracking
    ├── staff_dashboard/    # Staff operations interface
    └── user-issue/         # Citizen issue creation and reporting
```

---

## How It Works

### User Authentication Flow

1. Login/Sign-up - User enters credentials
2. API Authentication - Server returns JWT tokens (access and refresh tokens)
3. Token Storage - Tokens stored securely in encrypted local storage
4. OTP Verification - User verification via one-time password
5. Dashboard Access - User routed to appropriate dashboard based on role

### Issue Reporting Flow (Citizens)

1. Photo Capture or Upload - User selects or captures an image of the issue
2. Image Analysis - Automatic categorization based on image content
3. Location Detection - Application retrieves user's current GPS location
4. Report Submission - Issue submitted to backend with all metadata
5. Confirmation - Issue registered in user's dashboard
6. Status Monitoring - User can track resolution progress

### Issue Resolution Flow (Staff)

1. Task Assignment - Staff member receives assigned issue in dashboard
2. Navigation - Staff member uses integrated maps with GPS tracking to reach location
3. Work Initiation - Staff member marks issue status as "In Progress"
4. Documentation - Staff member captures photos documenting the resolution work
5. Completion - Status updated to "Resolved" or "Closed"
6. Synchronization - Changes reflected in citizen's view in real-time

---

## API Endpoints

The application communicates with a backend API through the following key endpoints:

| Endpoint               | Method | Purpose                              |
| ---------------------- | ------ | ------------------------------------ |
| /auth/login            | POST   | User authentication                  |
| /auth/signup           | POST   | User registration                    |
| /auth/verify-otp       | POST   | OTP verification                     |
| /auth/refresh-token    | POST   | JWT token refresh                    |
| /issues/create         | POST   | Create issue report                  |
| /issues/list           | GET    | Retrieve user issues                 |
| /issues/{id}/details   | GET    | Retrieve issue details               |
| /issues/{id}/status    | PATCH  | Update issue status                  |
| /staff/assigned-issues | GET    | Retrieve assigned tasks (Staff only) |

---

## Testing

### Test Credentials

Once the backend is running, the following test credentials can be used:

- Citizen Account: citizen@example.com / password
- Staff Account: staff@example.com / password

Note: Use actual credentials provided by your backend deployment.

### Testing Image Analysis

1. Navigate to the "Report Issue" screen
2. Capture or select a photograph of a road, pothole, or infrastructure issue
3. Wait for image analysis to complete (typically 2-3 seconds)
4. Verify that the issue category and description are accurate

### Testing Staff Navigation

1. Login with a staff account
2. View assigned issues in the dashboard
3. Select "Navigate" to open integrated map view
4. Confirm real-time GPS positioning functionality

---

## Troubleshooting

### Common Issues and Solutions

#### API Error: 400 when analyzing images

Cause: Invalid image analysis API key  
Solution: Regenerate your API key at https://aistudio.google.com/app/apikey and update the configuration in main.dart

#### API Error: 403 when accessing image analysis service

Cause: Required API service not enabled in cloud account  
Solution: Visit https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com and enable the service

#### Location permission denied

Cause: Application does not have permission to access device location  
Solution:

- Android: Grant location permission through application settings
- iOS: Verify location usage keys are present in Info.plist
- Review location service configuration in lib/core/services/location_service.dart

#### Cannot connect to backend server

Cause: Backend server is not running or API URL is incorrect  
Solution:

- Verify backend service is running at http://127.0.0.1:8000
- Update API URL in lib/core/constants/app_constants.dart if necessary
- Verify network connectivity between device and backend

#### Authentication token expired

Cause: JWT authentication token has expired  
Solution: The application automatically refreshes expired tokens. If the error persists, log out and log in again.

#### Images not loading from device gallery

Cause: Storage access permission not granted  
Solution:

- iOS: Add NSPhotoLibraryUsageDescription key to Info.plist
- Android: Verify WRITE_EXTERNAL_STORAGE and READ_EXTERNAL_STORAGE permissions are declared in AndroidManifest.xml

---

## Production Build

### Android Release Build

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release Build

```bash
flutter build ios --release
```

### Web Release Build

```bash
flutter build web --release
```

### Pre-Production Checklist

- Remove test API keys from source code
- Use environment variables for sensitive credentials in production
- Test all functionality on physical devices before deployment

---

## Contributing

Contributions are welcome. The following process should be followed:

1. Fork the repository
2. Create a feature branch (git checkout -b feature/feature-name)
3. Commit your changes (git commit -m 'Add feature description')
4. Push to the branch (git push origin feature/feature-name)
5. Open a Pull Request

### Code Standards

- Follow Dart style conventions: dart format .
- Run the linter: flutter analyze
- Run test suite: flutter test

---

## License

This project is proprietary and confidential. Unauthorized copying or distribution is prohibited.

---

## Support

For issues, questions, or security concerns:

- Open an issue on the project repository
- Contact the development team for additional support
- Report security vulnerabilities privately to the maintainers

---

## Future Roadmap

- Offline issue reporting with automatic synchronization
- Advanced filtering and search functionality
- Team notifications and communication features
- Multi-language localization support
- Dark mode user interface theme

---
