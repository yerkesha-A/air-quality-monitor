import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/nature_components.dart';
import '../providers/settings_controller.dart';

/// The welcome choices are a second state of this existing route, not another
/// persistent onboarding flag or a duplicate auth flow.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _choices = false;
  bool _saving = false;
  Future<void> _continue(String route) async {
    setState(() => _saving = true);
    await context.read<SettingsController>().completeOnboarding();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) => AirScaffold(
    immersive: true,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _choices
                    ? Column(
                        key: const ValueKey('welcome-choices'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 60),
                          const Center(child: AirWordmark()),
                          const SizedBox(height: 200),
                          Text(
                            'Дышите свободнее',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text('Ваш город. Ваш воздух. Ваш ритм.'),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : () => _continue('/login'),
                            child: const Text('С возвращением!'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _continue('/login?mode=register'),
                            child: const Text('Создайте аккаунт'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _saving ? null : () => _continue('/'),
                            child: const Text('Продолжить без аккаунта'),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('welcome-hero'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 64),
                          const Center(
                            child: Icon(Icons.air_rounded, size: 38),
                          ),
                          const SizedBox(height: 12),
                          const Center(child: AirWordmark()),
                          const SizedBox(height: 220),
                          Text(
                            'Чистый воздух\nдля лучшей жизни',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 32),
                          FilledButton(
                            onPressed: () => setState(() => _choices = true),
                            child: const Text('Начать'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
