import 'dart:convert';
import 'package:batti_nala/features/citizen_dashboard/controllers/create_issue_state.dart';
import 'package:batti_nala/features/citizen_dashboard/repository/citizen_issue_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/citizen_dashboard/models/create_issue_request.dart';
import 'package:batti_nala/features/citizen_dashboard/models/issue_model.dart';
import 'package:batti_nala/features/citizen_dashboard/models/issue_type_model.dart';

final createIssueControllerProvider =
    StateNotifierProvider<CreateIssueController, CreateIssueState>((ref) {
      final repository = ref.read(citizenIssueRepositoryProvider);
      return CreateIssueController(repository);
    });

class CreateIssueController extends StateNotifier<CreateIssueState> {
  final CitizenIssueRepository _repository;

  CreateIssueController(this._repository)
    : super(const CreateIssueState.initial());

  void updateIssueType(IssueType selectedType) {
    state = state.copyWith(
      issueTypeId: selectedType.issueTypeId,
      issueType: selectedType.issueType,
    );
  }

  void updatePriority(String priority) {
    state = state.copyWith(priority: priority);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateLocation(String location, double lat, double lng) {
    state = state.copyWith(
      issueLocation: location,
      latitude: lat,
      longitude: lng,
    );
  }

  void addAttachment(String filePath) {
    final updated = List<String>.from(state.attachments)..add(filePath);
    state = state.copyWith(attachments: updated);
  }

  void removeAttachment(String filePath) {
    final updated = List<String>.from(state.attachments)..remove(filePath);
    state = state.copyWith(attachments: updated);
  }

  void clearAttachments() {
    state = state.copyWith(attachments: []);
  }

  bool validateForm() {
    if (state.issueTypeId == null) {
      state = state.copyWith(errorMessage: 'Please select an issue type');
      return false;
    }
    if (state.description.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a description');
      return false;
    }
    if (state.issueLocation.isEmpty ||
        state.latitude == 0 ||
        state.longitude == 0) {
      state = state.copyWith(errorMessage: 'Please select a location');
      return false;
    }
    if (state.priority != 'LOW' &&
        state.priority != 'NORMAL' &&
        state.priority != 'HIGH') {
      state = state.copyWith(errorMessage: 'Invalid priority selected');
      return false;
    }
    return true;
  }

  Future<IssueModel?> submitIssue() async {
    if (!validateForm()) {
      debugPrint('Form validation failed: ${state.errorMessage}');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = CreateIssueRequest(
        issueTypeId: state.issueTypeId!,
        issuePriority: state.priority,
        description: state.description,
        attachments: state.attachments,
        issueLocation: state.issueLocation,
        latitude: state.latitude,
        longitude: state.longitude,
      );

      debugPrint(
        'CreateIssueRequest: issueTypeId=${request.issueTypeId}, priority=${request.issuePriority}, description=${request.description}, attachments=${request.attachments}, latitude=${request.latitude}, longitude=${request.longitude}',
      );

      final createdIssue = await _repository.createIssue(request);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        createdIssue: createdIssue,
        errorMessage: null,
      );

      debugPrint('Issue created successfully: $createdIssue');
      return createdIssue;
    } on DioException catch (e) {
      final message = _extractDioErrorDetail(e);
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: message,
      );
      debugPrint('Error occurred while creating issue: $message');
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );

      debugPrint('Error occurred while creating issue: ${state.errorMessage}');
      return null;
    }
  }

  String _extractDioErrorDetail(DioException e) {
    final data = e.response?.data;

    // Fast path: backend returns `{ "detail": "..." }`
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      return data.toString();
    }

    // Sometimes Dio returns a JSON string
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return e.message ?? 'An error occurred';

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final detail = decoded['detail'];
          if (detail is String && detail.trim().isNotEmpty) {
            return detail.trim();
          }
          final message = decoded['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      } catch (_) {
        // Ignore JSON parse errors and fall back to raw string.
      }

      return trimmed;
    }

    return e.message ?? 'An error occurred while creating the issue.';
  }

  void resetForm() {
    state = const CreateIssueState.initial();
  }

  /// Clears only the error banner/message so the snackbar can re-trigger
  /// even for the same error text on the next submit attempt.
  void clearErrorMessage() {
    state = state.copyWith(clearError: true);
  }
}
