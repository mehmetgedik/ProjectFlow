import 'package:flutter/material.dart';

import '../constants/my_work_packages_constants.dart';

/// Kolon seçim bottom sheet içeriği: listede hangi alanların görüneceğini seçtirir.
class MyWorkColumnSelector extends StatefulWidget {
  /// Başlangıçta seçili kolon id'leri.
  final Set<String> initialSelected;

  /// Kullanıcı "Uygula" dediğinde çağrılır; yeni seçilen kolon seti verilir.
  final void Function(Set<String> selected) onApply;

  const MyWorkColumnSelector({
    super.key,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<MyWorkColumnSelector> createState() => _MyWorkColumnSelectorState();
}

class _MyWorkColumnSelectorState extends State<MyWorkColumnSelector> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Kolonlar'),
                subtitle: Text('Listede hangi alanlar görünsün?'),
              ),
              ...MyWorkPackagesConstants.kColumnIds.map((id) => SwitchListTile(
                    value: _selected.contains(id),
                    title: Text(MyWorkPackagesConstants.kColumnLabels[id] ?? id),
                    onChanged: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(id);
                        } else {
                          _selected.remove(id);
                        }
                      });
                    },
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => widget.onApply(_selected),
                      child: const Text('Uygula'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
