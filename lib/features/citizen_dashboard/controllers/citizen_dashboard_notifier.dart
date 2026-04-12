import 'package:batti_nala/features/shared-issue/models/issue_type_model.dart';
import 'package:batti_nala/features/shared-issue/repository/issue_repository.dart';
import 'package:batti_nala/features/shared-issue/models/issue_model.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CitizenDashboardController extends StateNotifier<List<IssueModel>> {
  CitizenDashboardController(this.ref, this._repository) : super([]) {
    _loadIssues();
  }

  final Ref ref;
  final IssueRepository _repository;

  // Load issues from API
  Future<void> _loadIssues() async {
    if (ref.read(authNotifierProvider).user == null) return;
    try {
      final issues = await _repository.getCitizenIssues();
      if (!mounted) return;
      state = issues;
    } catch (e) {
      if (!mounted) return;
      state = [];
    }
  }

  // Pull to refresh - fetch latest issues
  Future<void> refreshReports() async {
    await Future.wait([
      ref.read(profileNotifierProvider.notifier).fetchProfile('citizen'),
      _loadIssues(),
    ]);
  }

  int get pendingCount =>
      state.where((i) => i.status.toUpperCase() == 'OPEN').length;

  int get resolvedCount =>
      state.where((i) => i.status.toUpperCase() == 'RESOLVED').length;
}

final dashboardProvider =
    StateNotifierProvider<CitizenDashboardController, List<IssueModel>>((ref) {
      final repository = ref.read(issueRepositoryProvider);
      return CitizenDashboardController(ref, repository);
    });

final issueTypeProvider = FutureProvider<IssueTypeModel>((ref) {
  final repository = ref.read(issueRepositoryProvider);
  return repository.getIssueTypes();
});
