import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../data/legal.dart';
import '../theme.dart';

/// Política de privacidade dentro do app (exigida pelo Google Play).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.volt.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.volt, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sem conta, sem servidor, sem anúncios. Seus dados ficam só neste celular.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          for (final s in privacyPolicy) ...[
            const SizedBox(height: 20),
            Text(s.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final p in s.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p,
                    style: const TextStyle(
                        color: AppColors.muted, height: 1.45, fontSize: 15)),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: AppInfo.privacyUrl));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Link da política copiado')));
            },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Copiar link da versão on-line'),
          ),
        ],
      ),
    );
  }
}

/// Explicação mostrada antes de pedir a permissão de localização.
/// Retorna true se a pessoa quiser continuar.
Future<bool> showLocationRationale(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.volt, size: 48),
            const SizedBox(height: 12),
            const Text('Usar o GPS na corrida',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'Para medir distância, ritmo e desenhar o percurso, o Forja usa sua localização '
              'somente enquanto uma corrida iniciada por você estiver ativa, inclusive com a tela bloqueada. '
              'Uma notificação fica visível o tempo todo.\n\n'
              'O percurso fica só no seu celular e não é enviado para ninguém.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Agora não (usar modo esteira)'),
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}
