import 'package:nested/nested.dart' show SingleChildWidget;
import 'package:provider/provider.dart';

import 'state/auth_state.dart';
import 'state/pro_state.dart';
import 'state/theme_state.dart';

/// Uygulama genelinde kullanılan provider listesi.
/// main.dart'ta MultiProvider(providers: appProviders, ...) ile kullanılır.
List<SingleChildWidget> get appProviders => [
      ChangeNotifierProvider(create: (_) => AuthState()),
      ChangeNotifierProvider(create: (_) => ThemeState()),
      ChangeNotifierProvider(create: (_) => ProState()),
    ];
