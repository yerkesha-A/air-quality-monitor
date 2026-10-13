import 'dart:async';

import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:air_quality_monitor/domain/repositories/places_repository.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/bloc/city_search_bloc.dart';
import 'package:air_quality_monitor/presentation/bloc/history_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAir extends Mock implements AirRepository {}

class MockPlaces extends Mock implements PlacesRepository {}

const cityA = Place(id: 'a', name: 'A', latitude: 43, longitude: 76);
const cityB = Place(id: 'b', name: 'B', latitude: 51, longitude: 71);
AirReport report(Place city) => AirReport(
  place: city,
  current: AirPoint(time: DateTime.utc(2026), values: {'us_aqi': 40}),
  forecast: [],
  fetchedAt: DateTime.utc(2026),
);
void main() {
  late MockAir air;
  late MockPlaces places;
  setUp(() {
    air = MockAir();
    places = MockPlaces();
    registerFallbackValue(cityA);
    when(() => places.select(any())).thenAnswer((_) async {});
    when(() => air.cached(any())).thenAnswer((_) async => null);
  });
  blocTest<AirBloc, AirState>(
    'Load emits Loading then Success',
    build: () {
      when(() => air.fetch(cityA)).thenAnswer((_) async => report(cityA));
      return AirBloc(air, places);
    },
    act: (bloc) => bloc.add(const LoadAir(cityA)),
    expect: () => [
      isA<AirState>().having((s) => s.status, 'status', LoadStatus.loading),
      isA<AirState>().having((s) => s.status, 'status', LoadStatus.success),
    ],
  );
  blocTest<AirBloc, AirState>(
    'Cache is visible during refresh and network failure preserves it',
    build: () {
      when(() => air.cached(cityA)).thenAnswer((_) async => report(cityA));
      when(() => air.fetch(cityA))
          .thenAnswer((_) async => report(cityA).asOffline());
      return AirBloc(air, places);
    },
    act: (bloc) => bloc.add(const LoadAir(cityA)),
    expect: () => [
      isA<AirState>().having((s) => s.status, 'status', LoadStatus.loading),
      isA<AirState>().having((s) => s.status, 'status', LoadStatus.refreshing),
      isA<AirState>().having((s) => s.report!.offline, 'offline', true),
    ],
  );
  blocTest<AirBloc, AirState>(
    'Missing data produces Error, not invented success',
    build: () {
      when(() => air.fetch(cityA)).thenThrow(const AirFailure('No data'));
      return AirBloc(air, places);
    },
    act: (bloc) => bloc.add(const LoadAir(cityA)),
    expect: () => [
      isA<AirState>().having((s) => s.status, 'status', LoadStatus.loading),
      isA<AirState>().having((s) => s.message, 'message', 'No data'),
    ],
  );
  test('Slow older request cannot replace newly selected city', () async {
    final pending = Completer<AirReport>();
    when(() => air.fetch(cityA)).thenAnswer((_) => pending.future);
    when(() => air.fetch(cityB)).thenAnswer((_) async => report(cityB));
    final bloc = AirBloc(air, places);
    bloc.add(const LoadAir(cityA));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const LoadAir(cityB));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    pending.complete(report(cityA));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.report!.place.id, 'b');
    await bloc.close();
  });
  test('Search debounce and stale response protection', () async {
    final pending = Completer<List<Place>>();
    when(() => air.search('Al')).thenAnswer((_) => pending.future);
    when(() => air.search('Ast')).thenAnswer((_) async => [cityB]);
    final bloc = CitySearchBloc(air, debounce: Duration.zero);
    bloc.add(const SearchChanged('Al'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const SearchChanged('Ast'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    pending.complete([cityA]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.results.single.id, 'b');
    bloc.add(const SearchChanged(''));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.status, LoadStatus.initial);
    await bloc.close();
  });
  blocTest<HistoryBloc, HistoryState>(
    'History empty is explicit',
    build: () {
      when(() => air.history(cityA, 30)).thenAnswer((_) async => []);
      return HistoryBloc(air);
    },
    act: (bloc) => bloc.add(const LoadHistory(cityA, 30)),
    expect: () => [
      isA<HistoryState>().having((s) => s.status, 'status', LoadStatus.loading),
      isA<HistoryState>().having((s) => s.status, 'status', LoadStatus.empty),
    ],
  );
}
