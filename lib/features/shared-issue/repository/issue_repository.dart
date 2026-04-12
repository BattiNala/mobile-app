import 'dart:convert';
import 'package:batti_nala/core/constants/api_url.dart';
import 'package:batti_nala/core/networks/dio_client.dart';
import 'package:batti_nala/features/shared-issue/models/issue_type_model.dart';
import 'package:batti_nala/features/user-issue/models/create_issue_request.dart';
import 'package:batti_nala/features/shared-issue/models/issue_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  final dioClient = ref.read(dioProvider);
  return IssueRepository(dioClient);
});

class IssueRepository {
  final Dio _dioClient;

  IssueRepository(this._dioClient);

  /// Fetch available issue types (used when creating an issue)
  Future<IssueTypeModel> getIssueTypes() async {
    final response = await _dioClient.get(ApiUrl.issueTypes);
    return IssueTypeModel.fromJson(response.data);
  }

  /// Create a new issue (citizen)
  Future<IssueModel> createIssue(CreateIssueRequest request) async {
    final issueMetadata = {
      'issue_type': request.issueTypeId,
      'issue_priority': request.issuePriority,
      'description': request.description,
      'issue_location': request.issueLocation,
      'latitude': request.latitude,
      'longitude': request.longitude,
    };

    final formData = FormData.fromMap({
      'issue_create': MultipartFile.fromString(jsonEncode(issueMetadata)),
    });

    for (final filePath in request.attachments) {
      final fileName = filePath.split('/').last;
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(filePath, filename: fileName),
        ),
      );
    }

    final response = await _dioClient.post(ApiUrl.createIssue, data: formData);
    return IssueModel.fromJson(response.data);
  }

  /// Get all issues reported by the current citizen
  Future<List<IssueModel>> getCitizenIssues() async {
    final response = await _dioClient.get(ApiUrl.citizenIssues);
    final rawIssues = response.data['items'] ?? response.data['issues'] ?? [];
    final issues = rawIssues as List;
    return issues.map((json) => IssueModel.fromJson(json)).toList();
  }

  /// Get all issues assigned to the current staff member
  Future<List<IssueModel>> getAssignedIssues({
    String? status,
    String? priority,
  }) async {
    final response = await _dioClient.get(
      '/issues/',
      queryParameters: {
        if (status != null) 'issue_status': status,
        if (priority != null) 'priority': priority,
      },
    );
    final List items = response.data['items'] ?? [];
    return items.map((json) => IssueModel.fromJson(json)).toList();
  }

  /// Get a specific issue by its label (used by both citizen detail and staff detail)
  Future<IssueModel> getIssueDetail(String issueLabel) async {
    final response = await _dioClient.get('/issues/$issueLabel');
    return IssueModel.fromJson(response.data);
  }

  /// Update the status of an issue (staff only)
  Future<void> updateIssueStatus({
    required String issueLabel,
    required String status,
  }) async {
    await _dioClient.post(
      ApiUrl.updateStatus,
      data: {'issue_label': issueLabel, 'status': status},
    );
  }
}
