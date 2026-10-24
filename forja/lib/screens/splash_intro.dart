import 'package:flutter/material.dart';

import '../theme.dart';

/// Continuação animada da tela de abertura nativa.
/// O logo começa no mesmo tamanho e posição da splash nativa (256 dp),
/// então a troca é imperceptível; depois ele "pulsa" e o nome aparece.
class SplashIntro extends StatefulWidget {
  final VoidCallback onDone;
  const SplashIntro({super.key, required this.onDone});

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.86)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25),
    TweenSequenceItem(
        tween: Tween(begin: 0.86, end: 0.72)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 75),
  ]).animate(_c);

  late final Animation<double> _glow = CurvedAnimation(
      parent: _c, curve: const Interval(0.15, 0.6, curve: Curves.easeOut));

  late final Animation<double> _text = CurvedAnimation(
      parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            // Brilho atrás do logo
            Opacity(
              opacity: (_glow.value * (1 - _text.value * 0.4)).clamp(0.0, 1.0),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withValues(alpha: 0.35),
                      blurRadius: 90,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -40 * _text.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Image.asset('assets/splash/splash_logo.png',
                    width: 256, height: 256),
              ),
            ),
            Transform.translate(
              offset: Offset(0, 90 + 16 * (1 - _text.value)),
              child: Opacity(
                opacity: _text.value,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('FORJA',
                        style: TextStyle(
                            color: AppColors.volt,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10)),
                    SizedBox(height: 6),
                    Text('Treino. Corrida. Constância.',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
            // Marca no rodapé, igual à splash nativa, que some suavemente
            Positioned(
              bottom: 48,
              child: Opacity(
                opacity: 1 - _text.value,
                child: Image.asset('assets/splash/branding.png', width: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
