import 'package:flutter/material.dart';

/// App içinde "ana ekrana dön" kısayolu: ProjectFlow logosuna tıklayınca
/// ilk route'a döner (RootRouter -> ProjectsScreen).
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
      message: 'Ana ekran',
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

