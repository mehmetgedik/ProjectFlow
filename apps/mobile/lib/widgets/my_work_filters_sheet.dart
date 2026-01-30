import 'package:flutter/material.dart';

import '../constants/my_work_packages_constants.dart';

/// Filtre bottom sheet: kolon/operatör/değer ile OpenProject API filtreleri ekle/kaldır.
/// [initialFilters] OpenProject formatında: her öğe { alan: { operator, values } }.
/// [onApply] kullanıcı "Uygula" dediğinde çağrılır; yeni filtre listesi verilir (aynı format).
class MyWorkFiltersSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialFilters;

  /// Yeni filtre listesi (OpenProject API formatında). Çağıran setState ve Navigator.pop yapmalı.
  final void Function(List<Map<String, dynamic>> filters) onApply;

  const MyWorkFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<MyWorkFiltersSheet> createState() => _MyWorkFiltersSheetState();
}

class _MyWorkFiltersSheetState extends State<MyWorkFiltersSheet> {
  late List<Map<String, dynamic>> _editing;
  final List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    _editing = widget.initialFilters.map((f) {
      final entry = f.entries.first;
      final key = entry.key;
      final val = entry.value as Map<String, dynamic>? ?? {};
      final op = val['operator']?.toString() ?? '=';
      final values = val['values'] as List?;
      final valuesList = values != null ? values.map((e) => e.toString()).toList() : <String>[];
      return {
        'field': key,
        'operator': op,
        'values': valuesList,
        'valuesInput': valuesList.join(', '),
      };
    }).toList();
    for (final f in _editing) {
      _valueControllers.add(TextEditingController(text: f['valuesInput']?.toString() ?? ''));
    }
  }

  @override
  void dispose() {
    for (final c in _valueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final newFilters = <Map<String, dynamic>>[];
    for (var i = 0; i < _editing.length; i++) {
      final f = _editing[i];
      final field = f['field'] as String?;
      final op = f['operator'] as String? ?? '=';
      List<String> values = (f['values'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
      final input = i < _valueControllers.length ? _valueControllers[i].text.trim() : (f['valuesInput']?.toString() ?? '');
      if (input.isNotEmpty) {
        values = input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      if (field == null || field.isEmpty) continue;
      newFilters.add({field: {'operator': op, 'values': values}});
    }
    widget.onApply(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Filtreler'),
              subtitle: Text(
                'Kolon, operatör ve değer seçin. Birden fazla filtre AND ile birleşir.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _editing.length,
                itemBuilder: (context, i) {
                  final f = _editing[i];
                  final field = f['field'] as String? ?? 'status';
                  final op = f['operator'] as String? ?? '=';
                  final needsVal = MyWorkPackagesConstants.operatorNeedsValues(op);
                  final fieldOptions = <String>[
                    if (!MyWorkPackagesConstants.kFilterFieldIds.contains(field)) field,
                    ...MyWorkPackagesConstants.kFilterFieldIds,
                  ];
                  final operatorOptions = <(String, String)>[
                    if (!MyWorkPackagesConstants.kFilterOperatorList.any((e) => e.$1 == op)) (op, op),
                    ...MyWorkPackagesConstants.kFilterOperatorList,
                  ];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: fieldOptions.contains(field) ? field : fieldOptions.first,
                                  isExpanded: true,
                                  iconSize: 18,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  items: fieldOptions.map((id) {
                                    return DropdownMenuItem(
                                      value: id,
                                      child: Text(
                                        MyWorkPackagesConstants.kFilterFieldLabels[id] ?? id,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => f['field'] = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: operatorOptions.any((e) => e.$1 == op) ? op : operatorOptions.first.$1,
                                  isExpanded: true,
                                  iconSize: 18,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  items: operatorOptions.map((e) {
                                    return DropdownMenuItem(
                                      value: e.$1,
                                      child: Text(
                                        e.$2,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => f['operator'] = v);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                tooltip: 'Bu filtre satırını kaldır',
                                onPressed: () {
                                  setState(() {
                                    if (i < _valueControllers.length) {
                                      _valueControllers[i].dispose();
                                      _valueControllers.removeAt(i);
                                    }
                                    _editing.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                          if (needsVal && i < _valueControllers.length) ...[
                            const SizedBox(height: 4),
                            TextField(
                              controller: _valueControllers[i],
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Değerler (virgülle ayırın; assignee için "me")',
                              ),
                              onChanged: (text) {
                                setState(() {
                                  f['valuesInput'] = text;
                                  f['values'] = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _editing.add({'field': 'status', 'operator': '=', 'values': <String>[], 'valuesInput': ''});
                        _valueControllers.add(TextEditingController(text: ''));
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Filtre ekle'),
                  ),
                  const SizedBox(height: 8),
                  if (_editing.isNotEmpty)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (final c in _valueControllers) {
                            c.dispose();
                          }
                          _valueControllers.clear();
                          _editing.clear();
                        });
                      },
                      child: const Text('Tümünü temizle'),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          _apply();
                          Navigator.pop(context, true);
                        },
                        child: const Text('Uygula'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
