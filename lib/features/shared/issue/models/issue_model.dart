class IssueModel {
  final String issueLabel;
  final String issueType;
  final String issuePriority;
  final String description;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final List<String> attachments;
  final String rejectedReason;
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
    required this.rejectedReason,
    required this.issueLocation,
    required this.latitude,
    required this.longitude,
    required this.detail,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      issueLabel: json['issue_label']?.toString() ?? 'Unknown',
      issueType: json['issue_type']?.toString() ?? 'General',
      issuePriority: json['issue_priority']?.toString() ?? 'NORMAL',
      description: json['description']?.toString() ?? 'No description provided',
      status: json['status']?.toString() ?? 'OPEN',
      assignedTo: json['assigned_to']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(
                  json['created_at'].toString().replaceFirst(' ', 'T'),
                ) ??
                DateTime.now()
          : DateTime.now(),
      attachments:
          (json['attachments'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      rejectedReason: json['rejected_reason']?.toString() ?? '',
      issueLocation: json['issue_location']?.toString() ?? 'Location unknown',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      detail: json['detail']?.toString(),
    );
  }
}
