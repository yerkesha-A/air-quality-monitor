// Отдельный учебный пример; не использует и не имитирует данные AQI.
// Запускать только на отдельном учебном AVD, не поверх приложения с данными.
// flutter run -t docs/state_examples.dart -d <учебный-device-id>
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MaterialApp(home: StateExamples()));

class CounterModel extends ChangeNotifier {
  int value = 0;
  void increment() {
    value++;
    notifyListeners();
  }
}

class CounterScope extends InheritedWidget {
  const CounterScope({
    super.key,
    required this.value,
    required this.increment,
    required super.child,
  });
  final int value;
  final VoidCallback increment;
  static CounterScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CounterScope>()!;
  @override
  bool updateShouldNotify(CounterScope oldWidget) => value != oldWidget.value;
}

class StateExamples extends StatefulWidget {
  const StateExamples({super.key});
  @override
  State<StateExamples> createState() => _StateExamplesState();
}

class _StateExamplesState extends State<StateExamples> {
  int _local = 0;
  int _inherited = 0;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CounterModel(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Учебный пример состояния')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('setState: $_local'),
            FilledButton(
              onPressed: () => setState(() => _local++),
              child: const Text('Локальное состояние'),
            ),
            const SizedBox(height: 24),
            CounterScope(
              value: _inherited,
              increment: () => setState(() => _inherited++),
              child: const _InheritedCounter(),
            ),
            const SizedBox(height: 24),
            const _ProviderCounter(),
          ],
        ),
      ),
    ),
  );
}

class _InheritedCounter extends StatelessWidget {
  const _InheritedCounter();
  @override
  Widget build(BuildContext context) {
    final scope = CounterScope.of(context);
    return Column(
      children: [
        Text('InheritedWidget: ${scope.value}'),
        FilledButton(
          onPressed: scope.increment,
          child: const Text('Обновить зависимые виджеты'),
        ),
      ],
    );
  }
}

class _ProviderCounter extends StatelessWidget {
  const _ProviderCounter();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('Provider: ${context.watch<CounterModel>().value}'),
      FilledButton(
        onPressed: context.read<CounterModel>().increment,
        child: const Text('Изменить модель'),
      ),
    ],
  );
}
