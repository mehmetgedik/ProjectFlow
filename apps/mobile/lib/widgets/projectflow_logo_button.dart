import 'package:flutter/material.dart';

/// App içinde "ana ekrana dön" kısayolu: ProjectFlow logosuna tıklayınca
/// ilk route'a döner (RootRouter -> ProjectsScreen).
class ProjectFlowLogoButton extends StatelessWidget {
  const ProjectFlowLogoButton({super.key, this.size = 28});

  final double size;

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ana ekran',
      onPressed: () => _goHome(context),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
      ),
      icon: Image.asset(
        'assets/brand/projectflow_mark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

