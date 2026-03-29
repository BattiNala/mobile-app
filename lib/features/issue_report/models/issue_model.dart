class IssueModel {
  final String issueLabel;
  final String issueType;
  final String issuePriority;
  final String description;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final List<String> attachments;
  final String issueLocation;
  final double latitude;
  final double longitude;
  final String? detail;

  IssueModel({
    required this.issueLabel,
    required this.issueType,
    required this.issuePriority,
    required this.description,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    required this.attachments,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
    required this.detail,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      issueLabel: json['issue_label'] ?? '',
      issueType: json['issue_type'] ?? '',
      issuePriority: json['issue_priority'] ?? 'NORMAL',
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      assignedTo: json['assigned_to'],
      createdAt: DateTime.parse(json['created_at']),
      attachments: List<String>.from(json['attachments'] ?? []),
      issueLocation: json['issue_location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      detail: json['detail'],
    );
  }
}
