class LocationState {
  final bool isLoading;
  final String? errorMessage;

  /// Display/send-ready location string (area/address).
  final String issueLocation;
  final double latitude;
  final double longitude;

  const LocationState({
    required this.isLoading,
    required this.errorMessage,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
  });

  const LocationState.initial()
      : isLoading = false,
        errorMessage = null,
        issueLocation = '',
        latitude = 0,
        longitude = 0;

  LocationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? issueLocation,
    double? latitude,
    double? longitude,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      issueLocation: issueLocation ?? this.issueLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

