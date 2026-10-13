import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import 'air_bloc.dart';

class LoadHistory {
  const LoadHistory(this.place, this.days);
  final Place place;
  final int days;
}

class HistoryState {
  const HistoryState({
    this.status = LoadStatus.initial,
    this.points = const [],
    this.days = 1,
    this.place,
    this.message,
  });
  final LoadStatus status;
  final List<AirPoint> points;
  final int days;
  final Place? place;
  final String? message;
}

class HistoryBloc extends Bloc<LoadHistory, HistoryState> {
  HistoryBloc(this.repository) : super(const HistoryState()) {
    on<LoadHistory>((event, emit) async {
      final revision = ++_revision;
      emit(
        HistoryState(
          status: LoadStatus.loading,
          place: event.place,
          days: event.days,
        ),
      );
      try {
        final points = await repository.history(event.place, event.days);
        if (revision == _revision && !emit.isDone) {
          emit(
            HistoryState(
              status: points.isEmpty ? LoadStatus.empty : LoadStatus.success,
              place: event.place,
              days: event.days,
              points: points,
            ),
          );
        }
      } catch (_) {
        if (revision == _revision && !emit.isDone) {
          emit(
            HistoryState(
              status: LoadStatus.error,
              place: event.place,
              days: event.days,
              message: 'Не удалось прочитать локальную историю.',
            ),
          );
        }
      }
    });
  }
  final AirRepository repository;
  int _revision = 0;
}
