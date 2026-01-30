import 'package:flutter/material.dart';

import '../utils/error_messages.dart';

/// Ekranlarda tekrarlanan loading/error state ve _load kalıbını tekilleştirir.
/// Kullanım: State sınıfında `with LoadingErrorMixin<MyScreen>` ve `_load()` içinde
/// `await runLoad(() async { ... });` kullanın; build'de [loading] ve [error] kullanın.
mixin LoadingErrorMixin<T extends StatefulWidget> on State<T> {
  bool loading = false;
  String? error;

  /// [load] çağrısını loading=true/error=null ile sarar; hata durumunda [error]'a
  /// kullanıcı dostu mesaj yazar. [onError] ile hata loglanabilir.
  Future<void> runLoad(
    Future<void> Function() load, {
    void Function(dynamic e)? onError,
  }) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await load();
    } catch (e) {
      onError?.call(e);
      if (mounted) {
        setState(() => error = ErrorMessages.userFriendly(e));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
