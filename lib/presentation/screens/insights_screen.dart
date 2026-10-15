import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import '../widgets/primitives.dart';

const pollutantDescriptions = <String, String>{
  'PM₂.₅': 'Мелкие взвешенные частицы диаметром до 2,5 мкм. Источники: сгорание топлива, транспорт, отопление и дым. Могут проникать глубоко в лёгкие.',
  'PM₁₀': 'Частицы диаметром до 10 мкм, включая дорожную и строительную пыль. Их концентрация зависит от ветра и источников загрязнения.',
  'NO₂': 'Диоксид азота связан с транспортом и сжиганием топлива. Повышенные уровни могут раздражать дыхательные пути.',
  'O₃': 'Приземный озон образуется при химических реакциях под действием солнечного света. Это не защитный озоновый слой в верхней атмосфере.',
  'CO': 'Угарный газ образуется при неполном сгорании топлива. Не имеет цвета и запаха. Модель уличного воздуха не заменяет домашний датчик CO.',
  'SO₂': 'Диоксид серы связан со сжиганием серосодержащего топлива и промышленными выбросами. Может раздражать дыхательные пути.',
};

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context) => AirScaffold(
    appBar: AppBar(title: const Text('О воздухе')),
    body: PageBody(
      children: [
        const Eyebrow('Знать больше'),
        const SizedBox(height: 16),
        Text(
          'Что стоит\nза цифрами',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        const Text(
          'AQI — индекс качества воздуха. В приложении используется только шкала US AQI: чем выше значение, тем больше загрязнение.',
        ),
        const SectionTitle('Загрязнители'),
        ...pollutantDescriptions.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AirSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  e.key,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                childrenPadding: const EdgeInsets.only(bottom: 20),
                children: [Text(e.value)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Surface(
          child: Text(
            'Информация носит ознакомительный характер и не является медицинской диагностикой. При симптомах обратитесь к врачу; следуйте местным предупреждениям.',
          ),
        ),
      ],
    ),
  );
}
