import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../bloc/air_bloc.dart';
import '../providers/places_controller.dart';
import '../widgets/primitives.dart';

class CityLinkScreen extends StatefulWidget {
  const CityLinkScreen({super.key, required this.id});
  final String id;
  @override
  State<CityLinkScreen> createState() => _CityLinkScreenState();
}

class _CityLinkScreenState extends State<CityLinkScreen> {
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = context.read<PlacesController>();
      final matches = [
        ...saved.recent,
        ...saved.favorites,
      ].where((p) => p.id == widget.id);
      final Place place = matches.isNotEmpty
          ? matches.first
          : await context.read<AirRepository>().resolve(widget.id);
      if (!mounted) return;
      context.read<AirBloc>().add(LoadAir(place));
      context.go('/');
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AirFailure
              ? e.message
              : 'Не удалось открыть город.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AirScaffold(
    appBar: AppBar(title: const Text('Открыть город')),
    body: _error == null
        ? const Center(child: CircularProgressIndicator())
        : PageBody(
            children: [
              EmptyMessage(
                title: 'Город недоступен',
                message: _error!,
                action: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Найти город'),
                ),
              ),
            ],
          ),
  );
}
