class IssueTypeModel {
  final List<IssueType> types;

  IssueTypeModel({required this.types});

  factory IssueTypeModel.fromJson(Map<String, dynamic> json) {
    return IssueTypeModel(
      types: (json['types'] as List? ?? [])
          .map((item) => IssueType.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'types': types.map((type) => type.toJson()).toList()};
  }
}

class IssueType {
  final int issueTypeId;
  final String issueType;

  IssueType({required this.issueTypeId, required this.issueType});

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      issueTypeId: json['issue_type_id'] ?? 0,
      issueType: json['issue_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'issue_type_id': issueTypeId, 'issue_type': issueType};
  }
}
