import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../../domain/repositories/places_repository.dart';

enum LoadStatus { initial, loading, success, empty, error, refreshing }

sealed class AirEvent {
  const AirEvent();
}

class LoadAir extends AirEvent {
  const LoadAir(this.place);
  final Place place;
}

class RefreshAir extends AirEvent {
  const RefreshAir();
}

class LocateAir extends AirEvent {
  const LocateAir();
}

class AirState {
  const AirState({
    this.status = LoadStatus.initial,
    this.place,
    this.report,
    this.message,
  });
  final LoadStatus status;
  final Place? place;
  final AirReport? report;
  final String? message;
  bool get busy =>
      status == LoadStatus.loading || status == LoadStatus.refreshing;
}

class AirBloc extends Bloc<AirEvent, AirState> {
  AirBloc(this.repository, this.places) : super(const AirState()) {
    on<LoadAir>((event, emit) => _load(event.place, emit));
    on<RefreshAir>((event, emit) async {
      final place = state.place;
      if (place != null) await _load(place, emit);
    });
    on<LocateAir>((event, emit) async {
      final revision = ++_revision;
      final previous = state;
      emit(
        AirState(
          status: LoadStatus.loading,
          place: previous.place,
          report: previous.report,
        ),
      );
      try {
        final place = await repository.locate();
        if (revision != _revision || emit.isDone) return;
        await _load(place, emit);
      } catch (error) {
        if (revision == _revision && !emit.isDone) {
          emit(
            AirState(
              status: LoadStatus.error,
              place: previous.place,
              report: previous.report,
              message: error is AirFailure
                  ? error.message
                  : 'Не удалось определить местоположение.',
            ),
          );
        }
      }
    });
  }
  final AirRepository repository;
  final PlacesRepository places;
  int _revision = 0;
  Future<void> _load(Place place, Emitter<AirState> emit) async {
    final revision = ++_revision;
    final previous = state.place?.id == place.id ? state.report : null;
    emit(
      AirState(
        status: previous == null ? LoadStatus.loading : LoadStatus.refreshing,
        place: place,
        report: previous,
      ),
    );
    try {
      await places.select(place);
      if (revision != _revision || emit.isDone) return;
      final cache = await repository.cached(place);
      if (revision != _revision || emit.isDone) return;
      if (cache != null) {
        emit(
          AirState(status: LoadStatus.refreshing, place: place, report: cache),
        );
      }
      final report = await repository.fetch(place);
      if (revision == _revision && !emit.isDone) {
        emit(
          AirState(
            status: report.current.aqi == null
                ? LoadStatus.empty
                : LoadStatus.success,
            place: place,
            report: report,
          ),
        );
      }
    } catch (error) {
      if (revision == _revision && !emit.isDone) {
        emit(
          AirState(
            status: error is AirEmpty ? LoadStatus.empty : LoadStatus.error,
            place: place,
            report: state.report,
            message: error is AirFailure
                ? error.message
                : 'Не удалось загрузить данные. Повторите запрос.',
          ),
        );
      }
    }
  }
}
