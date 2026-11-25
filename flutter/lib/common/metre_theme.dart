// Metre: cores e peças visuais próprias do MetreViewer. Ver METRE-CHANGES.md.
import 'package:flutter/material.dart';

class MetreColors {
  static const primary = Color(0xFF0B5CC4); // azul da logo
  static const primaryLight = Color(0xFF2F80E0);
  static const green = Color(0xFF1E9E5A);
  static const blue = Color(0xFF2563EB);
  static const gray = Color(0xFF6B7280);
  static const offline = Color(0xFFB0B4BB);
}

Widget metreLogo({double size = 40}) =>
    Image.asset('assets/metre_logo.png', width: size, height: size);

/// Cartão branco/escuro com cantos arredondados, usado nas telas da Metre.
class MetreCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const MetreCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (dark ? const Color(0xFF23242A) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: dark ? const Color(0xFF2E3038) : const Color(0xFFE6E7EB)),
      ),
      child: child,
    );
  }
}

/// Bolinha de status (verde = disponível).
Widget metreStatusDot(bool online, {double size = 10}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: online ? MetreColors.green : MetreColors.offline),
    );
