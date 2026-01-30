import 'work_package.dart';

/// Query görünümü için tek bir liste modeli:
/// - Grup başlık satırları
/// - İş paketi satırları (opsiyonel hiyerarşi derinliği ile)
class QueryRow {
  const QueryRow._({
    required this.isGroupHeader,
    this.groupLabel,
    this.workPackage,
    this.depth = 0,
    this.hasChildren = false,
  });

  final bool isGroupHeader;
  final String? groupLabel;
  final WorkPackage? workPackage;
  final int depth;
  /// Hiyerarşik görünümde: bu satırın çocukları var mı?
  final bool hasChildren;

  factory QueryRow.groupHeader(String label) {
    return QueryRow._(
      isGroupHeader: true,
      groupLabel: label,
      workPackage: null,
      depth: 0,
      hasChildren: false,
    );
  }

  factory QueryRow.workPackage(WorkPackage wp, {int depth = 0, bool hasChildren = false}) {
    return QueryRow._(
      isGroupHeader: false,
      groupLabel: null,
      workPackage: wp,
      depth: depth,
      hasChildren: hasChildren,
    );
  }
}
