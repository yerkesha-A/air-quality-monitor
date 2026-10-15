import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/nature_components.dart';
import '../providers/settings_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _saving = false;
  static const _titles = [
    'Больше воздуха.\nМеньше сомнений.',
    'Ваш город.\nВаш ритм.',
    'Планируйте день\nс заботой о себе.',
  ];
  static const _descriptions = [
    'Качество воздуха, которое легко понять. Один взгляд — и вы знаете, что происходит за окном.',
    'Найдите город или используйте GPS. Местоположение запрашивается только по вашему действию.',
    'Сравнивайте часы прогноза и выбирайте время для прогулки. Источник и возраст данных всегда видны.',
  ];
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AirScaffold(
    immersive: true,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(child: AirWordmark()),
                Text('${_page + 1} / 3'),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: 3,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: .95,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              index == 1
                                  ? NatureStyle.blueMountains
                                  : NatureStyle.alpineLake,
                              fit: BoxFit.cover,
                              cacheWidth: 1000,
                              excludeFromSemantics: true,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x11e9f7ff),
                                    Color(0xaa194554),
                                  ],
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 24,
                              right: 24,
                              bottom: 24,
                              child: Text(
                                'Чистый воздух\nдля лучшей жизни',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _titles[index],
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _descriptions[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.all(4),
                      width: index == _page ? 26 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_page < 2) {
                              await _pages.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              setState(() => _saving = true);
                              await context
                                  .read<SettingsController>()
                                  .completeOnboarding();
                            }
                          },
                    child: Text(_page == 2 ? 'Начать' : 'Продолжить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
