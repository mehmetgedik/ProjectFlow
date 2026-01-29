import 'work_package.dart';

/// Bir filtre örneği: alan adı, operatör ve değerler (görüntüleme için).
class QueryFilterDisplay {
  final String filterName;
  final String operatorTitle;
  final List<String> valueTitles;

  const QueryFilterDisplay({
    required this.filterName,
    required this.operatorTitle,
    this.valueTitles = const [],
  });

  String get summary {
    if (valueTitles.isEmpty) return '$filterName · $operatorTitle';
    return '$filterName · $operatorTitle · ${valueTitles.join(', ')}';
  }
}

/// OpenProject'te kayıtlı görünüm (query): filtre, sıralama ve kolon ayarlarıyla iş listesi.
class SavedQuery {
  final int id;
  final String name;
  final String? projectId;
  final List<QueryColumnInfo> columns;
  final String? resultsHref;
  /// Görünüm kullanıcı tarafından favorilere alınmış mı (API: starred).
  final bool starred;
  /// Başkaları görebilir mi (API: public).
  final bool public;
  /// Sorgu gizli mi (API: hidden) – listelemede atlanır.
  final bool hidden;
  /// OpenProject sorgusunda seçili groupBy alanı (örn. 'status', 'type', 'assignee').
  final String? groupBy;
  /// Hiyerarşi gösterimi açık mı (OpenProject query: showHierarchies).
  final bool showHierarchies;
  /// Sorgu filtreleri (API: filters dizisi).
  final List<QueryFilterDisplay> filters;
  /// Sorgu filtreleri (API formatında; filter formuna doldurmak için).
  /// Örnek: [{"status":{"operator":"o","values":[]}}, {"assignee":{"operator":"=","values":["me"]}}]
  final List<Map<String, dynamic>> apiFilters;
  /// Sıralama başlıkları (API: _links.sortBy[].title).
  final List<String> sortByTitles;

  const SavedQuery({
    required this.id,
    required this.name,
    this.projectId,
    required this.columns,
    this.resultsHref,
    this.starred = false,
    this.public = false,
    this.hidden = false,
    this.groupBy,
    this.showHierarchies = false,
    this.filters = const [],
    this.apiFilters = const [],
    this.sortByTitles = const [],
  });

  /// _links.columns dizisinden kolon id ve başlıklarını çıkarır (href: /api/v3/queries/columns/priority -> id: priority).
  static List<QueryColumnInfo> _parseColumns(dynamic linksColumns) {
    if (linksColumns == null) return const [];
    final list = linksColumns is List ? linksColumns : const [];
    final result = <QueryColumnInfo>[];
    for (final e in list) {
      if (e is! Map) continue;
      final href = e['href']?.toString() ?? '';
      final title = e['title']?.toString() ?? '';
      final id = href.contains('/columns/')
          ? href.split('/columns/').last.split('?').first.trim()
          : '';
      if (id.isNotEmpty) result.add(QueryColumnInfo(id: id, name: title.isNotEmpty ? title : id));
    }
    return result;
  }

  /// API filters dizisinden görüntüleme bilgisi çıkarır (_links.filter.title, _links.operator.title, values veya _links.values).
  static List<QueryFilterDisplay> _parseFilters(dynamic filtersJson) {
    if (filtersJson == null) return const [];
    final list = filtersJson is List ? filtersJson : const [];
    final result = <QueryFilterDisplay>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final links = e['_links'] as Map<String, dynamic>? ?? {};
      final filterLink = links['filter'];
      final operatorLink = links['operator'];
      final filterName = (filterLink is Map ? filterLink['title'] : null)?.toString() ?? e['name']?.toString() ?? '';
      final operatorTitle = (operatorLink is Map ? operatorLink['title'] : null)?.toString() ?? '';
      List<String> valueTitles = <String>[];
      if (e.containsKey('values') && e['values'] is List) {
        valueTitles = (e['values'] as List).map((v) => v?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      final valuesLink = links['values'];
      if (valueTitles.isEmpty && valuesLink is List) {
        for (final v in valuesLink) {
          if (v is Map && v['title'] != null) valueTitles.add(v['title'].toString());
        }
      }
      if (filterName.isNotEmpty || operatorTitle.isNotEmpty) {
        result.add(QueryFilterDisplay(
          filterName: filterName,
          operatorTitle: operatorTitle,
          valueTitles: valueTitles,
        ));
      }
    }
    return result;
  }

  static String? _idFromHref(dynamic href) {
    if (href == null) return null;
    final s = href.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split('?').first.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final last = parts.last;
    return last.isNotEmpty ? last : null;
  }

  static String? _operatorIdFromLinks(Map<String, dynamic> links) {
    final op = links['operator'];
    if (op is Map) {
      final href = op['href']?.toString();
      if (href != null && href.contains('/operators/')) {
        return href.split('/operators/').last.split('?').first.trim();
      }
      final id = op['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  /// API filters dizisini OpenProject work_packages filter formatına çevirir.
  static List<Map<String, dynamic>> _parseApiFilters(dynamic filtersJson) {
    if (filtersJson == null) return const [];
    final list = filtersJson is List ? filtersJson : const [];
    final result = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final links = e['_links'] as Map<String, dynamic>? ?? const {};
      // Filter id: önce kök `name`, yoksa _links.filter.href (.../filters/<id>)
      String name = e['name']?.toString() ?? '';
      if (name.isEmpty) {
        final filter = links['filter'];
        if (filter is Map) {
          final href = filter['href']?.toString();
          if (href != null && href.contains('/filters/')) {
            name = href.split('/filters/').last.split('?').first.trim();
          }
        }
      }
      if (name.isEmpty) continue;

      // Operator id: string ise kullan; değilse _links.operator.href (.../operators/<id>)
      String op = '=';
      final rawOp = e['operator'];
      if (rawOp is String && rawOp.trim().isNotEmpty) {
        op = rawOp.trim();
      } else {
        op = _operatorIdFromLinks(links) ?? '=';
      }

      final values = <String>[];
      if (e['values'] is List) {
        for (final v in (e['values'] as List)) {
          if (v is Map) {
            final hrefId = _idFromHref(v['href']);
            final id = v['id']?.toString();
            final s = (hrefId != null && hrefId.isNotEmpty)
                ? hrefId
                : ((id != null && id.isNotEmpty) ? id : (v['title']?.toString() ?? ''));
            if (s.isNotEmpty) values.add(s);
          } else {
            final s = v?.toString() ?? '';
            if (s.isNotEmpty) values.add(s);
          }
        }
      } else {
        final valuesLink = links['values'];
        if (valuesLink is List) {
          for (final v in valuesLink) {
            if (v is Map) {
              final fromHref = _idFromHref(v['href']);
              final fromTitle = v['title']?.toString();
              final s = (fromHref != null && fromHref.isNotEmpty) ? fromHref : (fromTitle ?? '');
              if (s.isNotEmpty) values.add(s);
            }
          }
        }
      }
      result.add({
        name: {
          'operator': op,
          'values': values,
        },
      });
    }
    return result;
  }

  /// _links.sortBy dizisinden sıralama başlıklarını çıkarır.
  static List<String> _parseSortBy(dynamic linksSortBy) {
    if (linksSortBy == null) return const [];
    final list = linksSortBy is List ? linksSortBy : const [];
    final result = <String>[];
    for (final e in list) {
      if (e is Map && e['title'] != null) {
        final t = e['title'].toString();
        if (t.isNotEmpty) result.add(t);
      }
    }
    return result;
  }

  /// groupBy: önce _links.groupBy href'ten id, yoksa root json['groupBy'].
  static String? _parseGroupBy(Map<String, dynamic> json, Map<String, dynamic> links) {
    final groupByLink = links['groupBy'];
    if (groupByLink is Map) {
      final href = groupByLink['href']?.toString();
      if (href != null && href.isNotEmpty && href.contains('/group')) {
        final id = href.split('/').last.split('?').first.trim();
        if (id.isNotEmpty) return id;
      }
      final title = groupByLink['title']?.toString();
      if (title != null && title.isNotEmpty) return title;
    }
    return json['groupBy']?.toString();
  }

  factory SavedQuery.fromJson(Map<String, dynamic> json) {
    final links = json['_links'] as Map<String, dynamic>? ?? {};
    final project = links['project'] as Map<String, dynamic>?;
    final projectHref = project?['href']?.toString() ?? '';
    final projectId = projectHref.contains('/projects/')
        ? projectHref.split('/projects/').last.split('/').first.trim()
        : null;
    final results = links['results'] as Map<String, dynamic>?;
    final resultsHref = results?['href']?.toString();

    final starred = json['starred'] == true;
    final public = json['public'] == true;
    final hidden = json['hidden'] == true;
    final groupBy = _parseGroupBy(json, links);
    final showHierarchies = json['showHierarchies'] == true;
    final filters = _parseFilters(json['filters']);
    final apiFilters = _parseApiFilters(json['filters']);
    final sortByTitles = _parseSortBy(links['sortBy']);

    return SavedQuery(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      projectId: projectId?.isEmpty == true ? null : projectId,
      columns: _parseColumns(links['columns']),
      resultsHref: resultsHref?.isEmpty == true ? null : resultsHref,
      starred: starred,
      public: public,
      hidden: hidden,
      groupBy: groupBy?.isEmpty == true ? null : groupBy,
      showHierarchies: showHierarchies,
      filters: filters,
      apiFilters: apiFilters,
      sortByTitles: sortByTitles,
    );
  }
}

class QueryColumnInfo {
  final String id;
  final String name;

  const QueryColumnInfo({required this.id, required this.name});
}

/// Bir görünümün sayfalı sonuçları.
class QueryResults {
  final SavedQuery query;
  final List<WorkPackage> workPackages;
  final int total;

  const QueryResults({
    required this.query,
    required this.workPackages,
    required this.total,
  });
}
