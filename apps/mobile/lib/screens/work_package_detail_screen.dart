import 'package:flutter/material.dart';

import '../app_navigation.dart';
import '../mixins/client_context_mixin.dart';
import '../models/work_package.dart';
import '../state/dashboard_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../constants/app_strings.dart';
import '../widgets/async_content.dart';
import '../widgets/free_plan_banner.dart';
import '../widgets/notification_badge_button.dart';
import '../widgets/projectflow_logo_button.dart';
import '../widgets/work_package_activity_tab.dart';
import '../widgets/work_package_detail_tab.dart';
import '../widgets/work_package_time_entries_tab.dart';

class WorkPackageDetailScreen extends StatefulWidget {
  final WorkPackage workPackage;

  const WorkPackageDetailScreen({super.key, required this.workPackage});

  @override
  State<WorkPackageDetailScreen> createState() => _WorkPackageDetailScreenState();
}

class _WorkPackageDetailScreenState extends State<WorkPackageDetailScreen>
    with RouteAware, ClientContextMixin<WorkPackageDetailScreen> {
  WorkPackage? _wp;
  String? _error;
  bool _loading = true;
  final GlobalKey<WorkPackageTimeEntriesTabState> _timeTabKey = GlobalKey<WorkPackageTimeEntriesTabState>();
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    DashboardPrefs.addRecentlyOpened(widget.workPackage.id);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = this.client;
      if (client == null) throw Exception('Oturum bulunamadı.');
      final wp = await client.getWorkPackage(widget.workPackage.id);
      if (mounted) {
        setState(() {
          _wp = wp;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.logError('İş detayı yüklenirken hata oluştu', error: e);
      if (mounted) {
        setState(() {
          _error = ErrorMessages.userFriendly(e);
          _loading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeSubscribed) return;
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void> && route.isCurrent) {
      appRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Üzerine push edilen ekran kapatıldığında (örn. bildirimler) Zaman sekmesini yenile;
    // zaman takibi formundan veya başka yerden eklenen kayıtlar listede görünsün.
    _timeTabKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.workPackage.subject;
    final titleText = subject.isNotEmpty ? '#${widget.workPackage.id} · $subject' : '#${widget.workPackage.id}';
    if (_loading || _error != null) {
      final errorText = _error != null
          ? (_error!.contains('bulunamadı') || _error!.contains('404')
              ? AppStrings.errorWorkNotFound
              : _error!)
          : null;
      return Scaffold(
        appBar: AppBar(
          title: Text(titleText, overflow: TextOverflow.ellipsis, maxLines: 1),
          actions: const [ProjectFlowLogoButton()],
        ),
        body: AsyncContent(
          loading: _loading,
          error: errorText,
          onRetry: _load,
          errorTrailing: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(AppStrings.buttonBack),
          ),
          child: const SizedBox.shrink(),
        ),
      );
    }
    final wp = _wp!;
    final contentTitle = wp.subject.trim().isNotEmpty
        ? '#${wp.id} · ${wp.subject}'
        : '#${wp.id}';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Tooltip(
            message: wp.subject.trim().isNotEmpty ? wp.subject : contentTitle,
            child: Text(
              contentTitle,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          actions: [
            const ProjectFlowLogoButton(),
            const NotificationBadgeButton(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.tabDetail),
              Tab(text: AppStrings.tabActivity),
              Tab(text: AppStrings.tabTime),
            ],
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FreePlanBanner(compact: true),
            Expanded(
              child: TabBarView(
                children: [
                  WorkPackageDetailTab(workPackage: wp, onRefresh: _load),
                  WorkPackageActivityTab(workPackageId: wp.id),
                  WorkPackageTimeEntriesTab(key: _timeTabKey, workPackageId: wp.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
