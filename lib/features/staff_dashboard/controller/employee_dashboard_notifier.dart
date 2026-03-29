import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/issue_report/models/issue_model.dart';
import 'package:batti_nala/features/issue_report/repository/issue_repository.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';

class EmployeeDashboardController extends StateNotifier<List<IssueModel>> {
  EmployeeDashboardController(this.ref, this._repository) : super([]) {
    _loadIssues();
  }

  final Ref ref;
  final IssueRepository _repository;

  /// Load assigned issues from API
  Future<void> _loadIssues() async {
    if (ref.read(authNotifierProvider).user == null) return;
    try {
      final issues = await _repository.getAssignedIssues();
      if (!mounted) return;
      state = issues;
    } catch (e) {
      if (!mounted) return;
      state = [];
    }
  }

  /// Pull to refresh - fetch latest issues
  Future<void> refreshReports() async {
    await Future.wait([
      ref.read(profileNotifierProvider.notifier).fetchProfile('staff'),
      _loadIssues(),
    ]);
  }

  int get pendingCount =>
      state.where((i) => i.status.toUpperCase() == 'OPEN').length;

  int get inProgressCount =>
      state.where((i) => i.status.toUpperCase() == 'IN_PROGRESS').length;

  int get resolvedCount =>
      state.where((i) => i.status.toUpperCase() == 'RESOLVED').length;
}

final employeeDashboardProvider =
    StateNotifierProvider<EmployeeDashboardController, List<IssueModel>>((ref) {
  final repository = ref.read(issueRepositoryProvider);
  return EmployeeDashboardController(ref, repository);
});
