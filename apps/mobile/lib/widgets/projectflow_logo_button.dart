import 'package:flutter/material.dart';

/// App içinde "ana ekrana dön" kısayolu: ProjectFlow logosuna tıklayınca
/// ilk route'a döner (RootRouter -> AuthenticatedGateScreen / Dashboard).
/// Şeffaf ikon (app_icon_transpara.png) kullanır.
class ProjectFlowLogoButton extends StatelessWidget {
  const ProjectFlowLogoButton({super.key, this.size = 28});

  final double size;

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ana ekrana (dashboard) dön',
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _goHome(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/icon/app_icon_transpara.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              isAntiAlias: true,
            ),
          ),
        ),
      ),
    );
  }
}

