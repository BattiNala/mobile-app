// lib/features/citizen_dashboard/models/create_issue_request.dart

class CreateIssueRequest {
  final int issueTypeId;
  final String issuePriority;
  final String description;
  final List<String> attachments;
  final String issueLocation;
  final double latitude;
  final double longitude;

  CreateIssueRequest({
    required this.issueTypeId,
    required this.issuePriority,
    required this.description,
    required this.attachments,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'issue_type_id': issueTypeId,
      'issue_priority': issuePriority,
      'description': description,
      'issue_location': issueLocation,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
