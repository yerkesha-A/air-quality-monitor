import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/air_advice.dart';
import '../bloc/air_bloc.dart';
import '../widgets/primitives.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AirBloc, AirState>(
    builder: (context, state) {
      final aqi = state.report?.current.aqi;
      return AirScaffold(
        appBar: AppBar(title: const Text('Рекомендации')),
        body: PageBody(
          children: [
            const Eyebrow('БЕРЕГИТЕ СЕБЯ'),
            const SizedBox(height: 16),
            Text(
              'Маленькие решения.\nЛегче дышать.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Text(
              AirAdvice.summary(aqi),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SectionTitle('На улице'),
            ...[
              ('Прогулка', false),
              ('Пробежка', true),
              ('Тренировка', true),
            ].map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AirSurface(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Icon(
                      activity.$2
                          ? Icons.directions_run_outlined
                          : Icons.directions_walk_outlined,
                    ),
                    contentPadding: EdgeInsets.zero,
                    title: Text(activity.$1),
                    subtitle: Text(
                      AirAdvice.activity(aqi, intense: activity.$2),
                    ),
                  ),
                ),
              ),
            ),
            const SectionTitle('Дома'),
            Text(
              aqi == null
                  ? 'Для рекомендации по проветриванию нужны данные о воздухе.'
                  : aqi > 100
                  ? 'При повышенном загрязнении ограничьте длительное проветривание. Выберите час с более низким AQI и используйте очиститель воздуха, если он есть.'
                  : 'Для проветривания выбирайте часы с более низким AQI. Избегайте дыма и других источников загрязнения в помещении.',
            ),
            const SectionTitle('Чувствительные группы'),
            const Text(
              'Дети, пожилые люди и люди с заболеваниями сердца или дыхательных путей могут быть чувствительнее к загрязнению. Учитывайте самочувствие и индивидуальные рекомендации врача.',
            ),
            const SizedBox(height: 24),
            const Surface(
              child: Text(
                'Рекомендации информационные. Приложение не ставит диагноз и не заменяет медицинскую консультацию или официальные предупреждения.',
              ),
            ),
          ],
        ),
      );
    },
  );
}
