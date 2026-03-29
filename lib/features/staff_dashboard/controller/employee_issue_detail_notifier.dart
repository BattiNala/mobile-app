import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/issue_report/models/issue_model.dart';
import 'package:batti_nala/features/issue_report/repository/issue_repository.dart';
import 'package:batti_nala/features/staff_dashboard/controller/employee_dashboard_notifier.dart';

class EmployeeIssueDetailNotifier extends StateNotifier<AsyncValue<IssueModel>> {
  EmployeeIssueDetailNotifier(this.ref, this._repository, this.issueLabel)
      : super(const AsyncValue.loading()) {
    fetchIssueDetail();
  }

  final Ref ref;
  final IssueRepository _repository;
  final String issueLabel;

  /// Fetch single issue detail
  Future<void> fetchIssueDetail() async {
    state = const AsyncValue.loading();
    try {
      final detail = await _repository.getIssueDetail(issueLabel);
      state = AsyncValue.data(detail);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update status (e.g. IN_PROGRESS, RESOLVED)
  Future<bool> updateStatus(String newStatus) async {
    try {
      await _repository.updateIssueStatus(
        issueLabel: issueLabel,
        status: newStatus,
      );
      // Re-fetch detail to reflect changes
      await fetchIssueDetail();
      // Also refresh the dashboard list
      ref.read(employeeDashboardProvider.notifier).refreshReports();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final employeeIssueDetailProvider = StateNotifierProvider.family<
    EmployeeIssueDetailNotifier, AsyncValue<IssueModel>, String>((ref, label) {
  final repository = ref.read(issueRepositoryProvider);
  return EmployeeIssueDetailNotifier(ref, repository, label);
});
