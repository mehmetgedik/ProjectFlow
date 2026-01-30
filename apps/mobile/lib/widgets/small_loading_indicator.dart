import 'package:flutter/material.dart';

/// İnline yükleme göstergesi (ince stroke); buton içi veya küçük alanlarda kullanılır.
class SmallLoadingIndicator extends StatelessWidget {
  const SmallLoadingIndicator({super.key, this.size});

  /// İsteğe bağlı boyut (varsayılan 24).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 24.0;
    return SizedBox(
      width: s,
      height: s,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
