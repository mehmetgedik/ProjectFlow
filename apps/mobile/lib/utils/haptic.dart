import 'package:flutter/services.dart';

/// Hafif dokunma geri bildirimi (liste seçimi, chip, switch).
void lightImpact() {
  HapticFeedback.lightImpact();
}

/// Orta tıklama (buton, onay).
void mediumImpact() {
  HapticFeedback.mediumImpact();
}

/// Seçim tik sesi (radio, checkbox).
void selectionClick() {
  HapticFeedback.selectionClick();
}
