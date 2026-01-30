import '../models/project.dart';
import '../models/saved_query.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../models/work_package_activity.dart';
import '../models/time_entry.dart';
import '../models/time_entry_activity.dart';
import '../models/notification_item.dart';
import '../models/week_day.dart';

import 'openproject_base.dart';
import 'user_api.dart';
import 'project_api.dart';
import 'work_package_api.dart';
import 'time_entry_api.dart';
import 'notification_api.dart';

export 'work_package_api.dart' show MyWorkPackagesResult;

/// OpenProject API istemcisi. Tüm public metodlar domain API sınıflarına delegasyon yapar;
/// çağıran kod değişmez.
class OpenProjectClient extends OpenProjectBase {
  OpenProjectClient({required Uri apiBase, required String apiKey})
      : _apiBase = apiBase,
        _apiKey = apiKey {
    _userApi = UserApi(this);
    _projectApi = ProjectApi(this);
    _workPackageApi = WorkPackageApi(this);
    _timeEntryApi = TimeEntryApi(this);
    _notificationApi = NotificationApi(this);
  }

  final Uri _apiBase;
  final String _apiKey;
  late final UserApi _userApi;
  late final ProjectApi _projectApi;
  late final WorkPackageApi _workPackageApi;
  late final TimeEntryApi _timeEntryApi;
  late final NotificationApi _notificationApi;

  @override
  Uri get apiBase => _apiBase;

  @override
  String get apiKey => _apiKey;

  // User
  Future<void> validateMe() => _userApi.validateMe();
  Future<String?> getMeDisplayName() => _userApi.getMeDisplayName();
  Future<Map<String, String>> getMe() => _userApi.getMe();
  Future<void> patchMe({String? firstName, String? lastName}) =>
      _userApi.patchMe(firstName: firstName, lastName: lastName);
  Future<Map<String, dynamic>> getMyPreferences() => _userApi.getMyPreferences();
  Future<void> patchMyPreferences(Map<String, dynamic> body) => _userApi.patchMyPreferences(body);

  // Project
  Future<List<Project>> getProjects() => _projectApi.getProjects();
  Future<List<Version>> getProjectVersions(String projectId) =>
      _projectApi.getProjectVersions(projectId);

  // Work package
  Future<WorkPackage> getWorkPackage(String id) => _workPackageApi.getWorkPackage(id);
  Future<WorkPackage> createWorkPackage({
    required String projectId,
    required String typeId,
    required String subject,
    String? description,
    String? assigneeId,
    String? priorityId,
    String? statusId,
    String? parentId,
    String? versionId,
    DateTime? startDate,
    DateTime? dueDate,
  }) =>
      _workPackageApi.createWorkPackage(
        projectId: projectId,
        typeId: typeId,
        subject: subject,
        description: description,
        assigneeId: assigneeId,
        priorityId: priorityId,
        statusId: statusId,
        parentId: parentId,
        versionId: versionId,
        startDate: startDate,
        dueDate: dueDate,
      );
  Future<List<WorkPackage>> getWorkPackagesByIds(List<String> ids) =>
      _workPackageApi.getWorkPackagesByIds(ids);
  Future<List<Map<String, String>>> getStatuses() => _workPackageApi.getStatuses();
  Future<List<Map<String, String>>> getPriorities() => _workPackageApi.getPriorities();
  Future<List<Map<String, String>>> getProjectMembers(String projectId) =>
      _workPackageApi.getProjectMembers(projectId);
  Future<List<Map<String, String>>> getProjectTypes(String projectId) =>
      _workPackageApi.getProjectTypes(projectId);
  Future<List<WorkPackage>> searchWorkPackagesForParent({
    required String projectId,
    required String query,
    int pageSize = 20,
  }) =>
      _workPackageApi.searchWorkPackagesForParent(
        projectId: projectId,
        query: query,
        pageSize: pageSize,
      );
  Future<WorkPackage> patchWorkPackage(
    String id, {
    String? statusId,
    String? assigneeId,
    bool clearAssignee = false,
    DateTime? dueDate,
    String? typeId,
    String? parentId,
    bool clearParent = false,
  }) =>
      _workPackageApi.patchWorkPackage(
        id,
        statusId: statusId,
        assigneeId: assigneeId,
        clearAssignee: clearAssignee,
        dueDate: dueDate,
        typeId: typeId,
        parentId: parentId,
        clearParent: clearParent,
      );
  Future<List<SavedQuery>> getQueries({String? projectId}) =>
      _workPackageApi.getQueries(projectId: projectId);
  Future<List<SavedQuery>> getViews({String? projectId}) =>
      _workPackageApi.getViews(projectId: projectId);
  Future<List<SavedQuery>> getQueriesLegacy({String? projectId}) =>
      _workPackageApi.getQueriesLegacy(projectId: projectId);
  Future<QueryResults> getQueryWithResults(
    int queryId, {
    int pageSize = 50,
    int offset = 1,
    List<Map<String, dynamic>>? overrideFilters,
    List<List<String>>? sortBy,
    String? groupBy,
  }) =>
      _workPackageApi.getQueryWithResults(
        queryId,
        pageSize: pageSize,
        offset: offset,
        overrideFilters: overrideFilters,
        sortBy: sortBy,
        groupBy: groupBy,
      );
  Future<MyWorkPackagesResult> getMyOpenWorkPackages({
    String? projectId,
    int pageSize = 20,
    int offset = 1,
    List<Map<String, dynamic>>? extraFilters,
  }) =>
      _workPackageApi.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: pageSize,
        offset: offset,
        extraFilters: extraFilters,
      );
  Future<MyWorkPackagesResult> getWorkPackages({
    String? projectId,
    required List<Map<String, dynamic>> filters,
    List<List<String>>? sortBy,
    int pageSize = 20,
    int offset = 1,
  }) =>
      _workPackageApi.getWorkPackages(
        projectId: projectId,
        filters: filters,
        sortBy: sortBy,
        pageSize: pageSize,
        offset: offset,
      );
  Future<List<WorkPackageActivity>> getWorkPackageActivities(String workPackageId) =>
      _workPackageApi.getWorkPackageActivities(workPackageId);
  Future<void> addWorkPackageComment({
    required String workPackageId,
    required String comment,
  }) =>
      _workPackageApi.addWorkPackageComment(workPackageId: workPackageId, comment: comment);

  // Time entry
  Future<List<WeekDay>> getWeekDays() => _timeEntryApi.getWeekDays();
  Future<List<TimeEntry>> getMyTimeEntries({
    DateTime? from,
    DateTime? to,
    String? userId,
  }) =>
      _timeEntryApi.getMyTimeEntries(from: from, to: to, userId: userId);
  Future<List<TimeEntry>> getWorkPackageTimeEntries(String workPackageId) =>
      _timeEntryApi.getWorkPackageTimeEntries(workPackageId);
  Future<List<TimeEntryActivity>> getTimeEntryActivities() =>
      _timeEntryApi.getTimeEntryActivities();
  Future<void> createTimeEntry({
    required String workPackageId,
    required double hours,
    required DateTime spentOn,
    String? comment,
    String? activityId,
  }) =>
      _timeEntryApi.createTimeEntry(
        workPackageId: workPackageId,
        hours: hours,
        spentOn: spentOn,
        comment: comment,
        activityId: activityId,
      );
  Future<void> updateTimeEntry(
    String timeEntryId, {
    double? hours,
    DateTime? spentOn,
    String? comment,
    String? activityId,
  }) =>
      _timeEntryApi.updateTimeEntry(
        timeEntryId,
        hours: hours,
        spentOn: spentOn,
        comment: comment,
        activityId: activityId,
      );
  Future<void> deleteTimeEntry(String timeEntryId) =>
      _timeEntryApi.deleteTimeEntry(timeEntryId);

  // Notifications
  Future<List<NotificationItem>> getNotifications({bool onlyUnread = false}) =>
      _notificationApi.getNotifications(onlyUnread: onlyUnread);
  Future<int> getUnreadNotificationCount() => _notificationApi.getUnreadNotificationCount();
  Future<void> markNotificationRead(String id) => _notificationApi.markNotificationRead(id);
  Future<void> markAllNotificationsRead() => _notificationApi.markAllNotificationsRead();
}
