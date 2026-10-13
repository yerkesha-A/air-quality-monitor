import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/settings_controller.dart';
import '../widgets/primitives.dart';

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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.air_rounded, color: AppTheme.forest),
                const SizedBox(width: 10),
                const Expanded(child: Eyebrow('AIR QUALITY MONITOR')),
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
                      aspectRatio: 1.35,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: CustomPaint(painter: _LandscapePainter(index)),
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

class _LandscapePainter extends CustomPainter {
  _LandscapePainter(this.page);
  final int page;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffe4e5d5),
    );
    canvas.drawCircle(
      Offset(size.width * .75, size.height * .25),
      26,
      Paint()..color = const Color(0xffc7cba8),
    );
    for (var layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(0, size.height * (.48 + layer * .13));
      path.cubicTo(
        size.width * .28,
        size.height * (.15 + layer * .2),
        size.width * .55,
        size.height * (.95 - layer * .05),
        size.width,
        size.height * (.4 + layer * .13),
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = [
            const Color(0xffb7c1a3),
            const Color(0xff899e7b),
            const Color(0xff54715b),
            AppTheme.forest,
          ][layer],
      );
    }
    final paint = Paint()
      ..color = const Color(0xfff5f2e9).withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var line = 0; line < 8; line++) {
      final path = Path()..moveTo(0, size.height * .7 + line * 12);
      path.cubicTo(
        size.width * .3,
        size.height * .35 + line * 12,
        size.width * .65,
        size.height + line * 12,
        size.width,
        size.height * .62 + line * 12,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) => oldDelegate.page != page;
}
