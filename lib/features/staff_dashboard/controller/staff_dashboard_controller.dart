import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/models/issue_model.dart';

class StaffDashboardController extends StateNotifier<List<Issue>> {
  StaffDashboardController() : super(_mockIssues());

  static List<Issue> _mockIssues() {
    return [
      Issue(
        id: '1',
        category: IssueCategory.water,
        description: 'Water leak on main street near temple',
        locationName: 'Thamel, Kathmandu',
        status: IssueStatus.inProgress,
        reportedBy: 'Ram Sharma',
        reportedAt: '2026-01-12 14:30',
      ),
      Issue(
        id: '2',
        category: IssueCategory.electricity,
        description: 'Street light not working',
        locationName: 'Durbarmarg, Kathmandu',
        status: IssueStatus.pending,
        reportedBy: 'Hari Bahadur',
        reportedAt: '2026-01-12 09:15',
      ),
      Issue(
        id: '3',
        category: IssueCategory.water,
        description: 'Empty water tank in neighborhood',
        locationName: 'Patan Dhoka, Lalitpur',
        status: IssueStatus.pending,
        reportedBy: 'Sita Devi',
        reportedAt: '2026-01-11 16:45',
      ),
      Issue(
        id: '4',
        category: IssueCategory.electricity,
        description: 'Power outage in residential area',
        locationName: 'Jawalakhel, Lalitpur',
        status: IssueStatus.pending,
        reportedBy: 'Krishna Prasad',
        reportedAt: '2026-01-11 11:20',
      ),
      Issue(
        id: '5',
        category: IssueCategory.water,
        description: 'Broken water pipe',
        locationName: 'Maitighar, Kathmandu',
        status: IssueStatus.resolved,
        reportedBy: 'Maya Gurung',
        reportedAt: '2026-01-10 08:00',
      ),
    ];
  }

  List<Issue> get activeIssues =>
      state.where((i) => i.status != IssueStatus.resolved).toList();

  List<Issue> get resolvedIssues =>
      state.where((i) => i.status == IssueStatus.resolved).toList();

  int get pendingCount =>
      state.where((i) => i.status == IssueStatus.pending).length;

  int get inProgressCount =>
      state.where((i) => i.status == IssueStatus.inProgress).length;

  int get resolvedCount =>
      state.where((i) => i.status == IssueStatus.resolved).length;

  int get totalIssues => state.length;
}

final staffDashboardProvider =
    StateNotifierProvider<StaffDashboardController, List<Issue>>(
      (ref) => StaffDashboardController(),
    );
