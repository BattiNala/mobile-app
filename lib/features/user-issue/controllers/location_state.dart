class LocationState {
  final bool isLoading;
  final String? errorMessage;
  final bool isPermissionPermanentlyDenied;

  /// Display/send-ready location string (area/address).
  final String issueLocation;
  final double latitude;
  final double longitude;

  const LocationState({
    required this.isLoading,
    required this.errorMessage,
    required this.isPermissionPermanentlyDenied,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
  });

  const LocationState.initial()
      : isLoading = false,
        errorMessage = null,
        isPermissionPermanentlyDenied = false,
        issueLocation = '',
        latitude = 0,
        longitude = 0;

  LocationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPermissionPermanentlyDenied,
    String? issueLocation,
    double? latitude,
    double? longitude,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPermissionPermanentlyDenied:
          isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      issueLocation: issueLocation ?? this.issueLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
