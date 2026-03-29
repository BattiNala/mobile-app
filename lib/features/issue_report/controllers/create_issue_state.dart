import 'package:batti_nala/features/issue_report/models/issue_model.dart';

class CreateIssueState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final IssueModel? createdIssue;
  final int? issueTypeId;
  final String issueType;
  final String priority;
  final String description;
  final List<String> attachments;
  final String issueLocation;
  final double latitude;
  final double longitude;

  const CreateIssueState({
    required this.isLoading,
    this.errorMessage,
    required this.isSuccess,
    this.createdIssue,
    this.issueTypeId,
    required this.issueType,
    required this.priority,
    required this.description,
    required this.attachments,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
  });

  const CreateIssueState.initial()
    : isLoading = false,
      errorMessage = null,
      isSuccess = false,
      createdIssue = null,
      issueTypeId = null,
      issueType = '',
      priority = 'NORMAL',
      description = '',
      attachments = const [],
      issueLocation = '',
      latitude = 0,
      longitude = 0;

  CreateIssueState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    IssueModel? createdIssue,
    int? issueTypeId,
    String? issueType,
    String? priority,
    String? description,
    List<String>? attachments,
    String? issueLocation,
    double? latitude,
    double? longitude,
    bool clearError = false,
  }) {
    return CreateIssueState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      createdIssue: createdIssue ?? this.createdIssue,
      issueTypeId: issueTypeId ?? this.issueTypeId,
      issueType: issueType ?? this.issueType,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      issueLocation: issueLocation ?? this.issueLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
