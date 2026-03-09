// Enums for Issue
enum IssueCategory { water, electricity }

enum IssueStatus { pending, inProgress, resolved }

class Issue {
  final String id;
  final IssueCategory category;
  final String description;
  final String locationName;
  final IssueStatus status;
  final String reportedBy;
  final String reportedAt;

  Issue({
    required this.id,
    required this.category,
    required this.description,
    required this.locationName,
    required this.status,
    required this.reportedBy,
    required this.reportedAt,
  });

  // Helper method to convert category enum to string
  String get categoryString {
    return category.toString().split('.').last;
  }

  // Helper method to convert status enum to string
  String get statusString {
    return status.toString().split('.').last;
  }
}
