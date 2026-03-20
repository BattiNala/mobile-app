import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/networks/dio_client.dart';
import 'package:batti_nala/features/citizen_dashboard/models/issue_type_model.dart';
import 'package:batti_nala/features/citizen_dashboard/models/create_issue_request.dart';
import 'package:batti_nala/features/citizen_dashboard/models/issue_model.dart';

final citizenIssueRepositoryProvider = Provider<CitizenIssueRepository>((ref) {
  final dioClient = ref.read(dioProvider);
  return CitizenIssueRepository(dioClient);
});

class CitizenIssueRepository {
  final Dio _dioClient;

  CitizenIssueRepository(this._dioClient);

  /// Fetch available issue types
  Future<IssueTypeModel> getIssueTypes() async {
    final response = await _dioClient.get('/issues/get-issue-types');
    return IssueTypeModel.fromJson(response.data);
  }

  /// Create a new issue
  Future<IssueModel> createIssue(CreateIssueRequest request) async {
    final issueMetadata = {
      'issue_type': request.issueTypeId,
      'issue_priority': request.issuePriority,
      'description': request.description,
      'issue_location': request.issueLocation,
      'latitude': request.latitude,
      'longitude': request.longitude,
    };

    // Create FormData for multipart upload
    final formData = FormData.fromMap({
      'issue_create': MultipartFile.fromString(jsonEncode(issueMetadata)),
    });

    // Add photo attachments
    for (final filePath in request.attachments) {
      final fileName = filePath.split('/').last;
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(filePath, filename: fileName),
        ),
      );
    }

    final response = await _dioClient.post('/issues/create', data: formData);
    return IssueModel.fromJson(response.data);
  }

  /// Get user's issues
  Future<List<IssueModel>> getUserIssues() async {
    final response = await _dioClient.get('/issues/my-issues');
    final issues = response.data['issues'] as List? ?? [];
    return issues.map((json) => IssueModel.fromJson(json)).toList();
  }
}
