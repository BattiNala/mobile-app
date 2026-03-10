import 'package:batti_nala/core/models/issue_model.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CitizenDashboardController extends StateNotifier<List<Issue>> {
  CitizenDashboardController(this.ref) : super(_mockReports());

  final Ref ref;

  static List<Issue> _mockReports() {
    return [
      Issue(
        id: '1',
        category: IssueCategory.water,
        description: 'Water leak on main street near temple',
        locationName: 'Thamel, Kathmandu',
        status: IssueStatus.inProgress,
        reportedBy: 'Citizen User',
        reportedAt: '2026-01-12 14:30',
      ),
      Issue(
        id: '2',
        category: IssueCategory.electricity,
        description: 'Street light not working',
        locationName: 'Durbarmarg, Kathmandu',
        status: IssueStatus.pending,
        reportedBy: 'Citizen User',
        reportedAt: '2026-01-11 09:15',
      ),
      Issue(
        id: '3',
        category: IssueCategory.water,
        description: 'Empty water tank in neighborhood',
        locationName: 'Patan Dhoka, Lalitpur',
        status: IssueStatus.resolved,
        reportedBy: 'Citizen User',
        reportedAt: '2026-01-10 16:45',
      ),
    ];
  }

  // Pull to refresh - simulates fetching latest reports
  Future<void> refreshReports() async {
    await ref.read(profileNotifierProvider.notifier).fetchProfile('citizen');
    state = _mockReports();
  }

  int get pendingCount =>
      state.where((r) => r.status == IssueStatus.pending).length;

  int get resolvedCount =>
      state.where((r) => r.status == IssueStatus.resolved).length;
}

final dashboardProvider =
    StateNotifierProvider<CitizenDashboardController, List>(
      (ref) => CitizenDashboardController(ref),
    );
