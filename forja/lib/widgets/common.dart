import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../utils.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.card,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gradient == null ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: gradient == null ? null : BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Valor com botões - e + grandes (fácil de usar na academia).
class NumberStepper extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final String unit;
  final int decimals;
  final ValueChanged<double> onChanged;

  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.unit = '',
    this.decimals = 0,
  });

  void _set(double v) {
    HapticFeedback.selectionClick();
    onChanged(v.clamp(min, max).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final txt = decimals == 0 ? value.round().toString() : fmtNum(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _btn(Icons.remove, () => _set(value - step)),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final v = await showNumberDialog(context,
                        title: label, initial: value, unit: unit);
                    if (v != null) _set(v);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      unit.isEmpty ? txt : '$txt $unit',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              _btn(Icons.add, () => _set(value + step)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      );
}

Future<double?> showNumberDialog(
  BuildContext context, {
  required String title,
  required double initial,
  String unit = '',
  String? helper,
}) {
  final ctrl = TextEditingController(text: fmtNum(initial));
  return showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          suffixText: unit,
          helperText: helper,
          helperMaxLines: 3,
        ),
        onSubmitted: (_) => Navigator.pop(
            ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
              ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Anel de progresso (água, metas).
class RingProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Widget? center;

  const RingProgress({
    super.key,
    required this.progress,
    this.size = 96,
    this.stroke = 10,
    this.color = AppColors.volt,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => CustomPaint(
          painter: _RingPainter(v, stroke, color),
          child: Center(child: child),
        ),
        child: center,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;
  _RingPainter(this.progress, this.stroke, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final bg = Paint()
      ..color = AppColors.cardHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, bg);
    if (progress > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.color = AppColors.volt,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          if (icon != null) const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class Difficulty extends StatelessWidget {
  final int level;
  final Color color;
  const Difficulty(this.level, {super.key, this.color = AppColors.volt});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < level ? Icons.bolt_rounded : Icons.bolt_outlined,
          size: 16,
          color: i < level ? color : AppColors.muted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Seleção em formato de cartão (usada no onboarding e no perfil).
class ChoiceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? leading;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.volt.withValues(alpha: 0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.volt : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leading != null) ...[
                  Text(leading!, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? AppColors.volt : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
