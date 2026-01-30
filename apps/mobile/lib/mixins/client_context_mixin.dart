import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../state/auth_state.dart';

/// StatefulWidget state'lerinde [OpenProjectClient] erişimini sağlar.
/// Kullanım: `class _MyScreenState extends State<MyScreen> with ClientContextMixin<MyScreen>`
/// Sonra `client` getter ile erişim.
mixin ClientContextMixin<T extends StatefulWidget> on State<T> {
  OpenProjectClient? get client => context.read<AuthState>().client;
}
