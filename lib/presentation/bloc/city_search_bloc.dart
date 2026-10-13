import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import 'air_bloc.dart';

sealed class CitySearchEvent {
  const CitySearchEvent();
}

class SearchChanged extends CitySearchEvent {
  const SearchChanged(this.query);
  final String query;
}

class _SearchRequested extends CitySearchEvent {
  const _SearchRequested(this.query, this.revision);
  final String query;
  final int revision;
}

class CitySearchState {
  const CitySearchState({
    this.status = LoadStatus.initial,
    this.query = '',
    this.results = const [],
    this.message,
  });
  final LoadStatus status;
  final String query;
  final List<Place> results;
  final String? message;
}

class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {
  CitySearchBloc(
    this.repository, {
    this.debounce = const Duration(milliseconds: 400),
  }) : super(const CitySearchState()) {
    on<SearchChanged>((event, emit) {
      _timer?.cancel();
      final revision = ++_revision;
      final query = event.query.trim();
      emit(
        CitySearchState(
          query: query,
          status: query.length < 2 ? LoadStatus.initial : LoadStatus.loading,
        ),
      );
      if (query.length >= 2) {
        _timer = Timer(debounce, () {
          if (!isClosed) add(_SearchRequested(query, revision));
        });
      }
    });
    on<_SearchRequested>((event, emit) async {
      try {
        final results = await repository.search(event.query);
        if (event.revision == _revision && !emit.isDone) {
          emit(
            CitySearchState(
              query: event.query,
              status: results.isEmpty ? LoadStatus.empty : LoadStatus.success,
              results: results,
            ),
          );
        }
      } catch (error) {
        if (event.revision == _revision && !emit.isDone) {
          emit(
            CitySearchState(
              query: event.query,
              status: LoadStatus.error,
              message: error is AirFailure
                  ? error.message
                  : 'Поиск недоступен. Повторите запрос.',
            ),
          );
        }
      }
    });
  }
  final AirRepository repository;
  final Duration debounce;
  Timer? _timer;
  int _revision = 0;
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
