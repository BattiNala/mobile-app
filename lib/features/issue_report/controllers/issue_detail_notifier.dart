import 'package:batti_nala/features/issue_report/models/issue_model.dart';
import 'package:batti_nala/features/issue_report/repository/issue_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IssueDetailState {
  final IssueModel? issue;
  final bool isLoading;
  final String? errorMessage;

  IssueDetailState({
    this.issue,
    this.isLoading = false,
    this.errorMessage,
  });

  IssueDetailState copyWith({
    IssueModel? issue,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IssueDetailState(
      issue: issue ?? this.issue,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Used by citizens to view their own reported issue detail.
class IssueDetailNotifier extends StateNotifier<IssueDetailState> {
  final IssueRepository _repository;

  IssueDetailNotifier(this._repository)
      : super(IssueDetailState(isLoading: true));

  Future<void> fetchIssueDetail(String label) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final issue = await _repository.getIssueDetail(label);
      if (!mounted) return;
      state = state.copyWith(issue: issue, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch issue details: ${e.toString()}',
      );
    }
  }
}

final issueDetailProvider =
    StateNotifierProvider.family<IssueDetailNotifier, IssueDetailState, String>(
  (ref, label) {
    final repository = ref.read(issueRepositoryProvider);
    final notifier = IssueDetailNotifier(repository);
    notifier.fetchIssueDetail(label);
    return notifier;
  },
);
