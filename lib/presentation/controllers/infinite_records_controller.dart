import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One keyset request at a time; identities and cursor progress prevent loops.
class InfiniteRecordsController<T> extends ChangeNotifier {
  InfiniteRecordsController({required this.load, required this.identity});
  final Future<List<T>> Function(T? after) load;
  final Object Function(T) identity;
  static const pageSize = 20;
  final List<T> _items = [];
  final Set<Object> _seen = {};
  late final List<T> _view = UnmodifiableListView(_items);
  List<T> get items => _view;
  bool loading = false;
  bool hasMore = true;
  Object? error;
  T? _cursor;
  bool _disposed = false;

  Future<void> next({bool retry = false}) async {
    if (_disposed || loading || !hasMore || (error != null && !retry)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await load(_cursor);
      if (_disposed) return;
      final page = result.take(pageSize).toList();
      final oldCursor = _cursor == null ? null : identity(_cursor as T);
      var added = 0;
      for (final item in page) {
        if (_seen.add(identity(item))) {
          _items.add(item);
          added++;
        }
      }
      if (page.isNotEmpty) _cursor = page.last;
      hasMore = result.length > pageSize;
      if (hasMore &&
          (added == 0 ||
              (_cursor != null && identity(_cursor as T) == oldCursor))) {
        error = StateError('Page cursor did not advance');
      }
    } catch (failure) {
      if (!_disposed) error = failure;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
