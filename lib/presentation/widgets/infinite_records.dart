import 'package:flutter/material.dart';

import '../controllers/infinite_records_controller.dart';

/// A real lazy sliver in the parent's viewport, not a shrink-wrapped nested list.
class InfiniteRecords<T> extends StatefulWidget {
  const InfiniteRecords({
    super.key,
    required this.load,
    required this.identity,
    required this.itemBuilder,
    this.emptyMessage = 'Записей пока нет.',
    this.emptyState,
    this.showCompletionMessage = true,
  });
  final Future<List<T>> Function(T? after) load;
  final Object Function(T) identity;
  final Widget Function(T) itemBuilder;
  final String emptyMessage;
  final Widget? emptyState;
  final bool showCompletionMessage;
  @override
  State<InfiniteRecords<T>> createState() => _InfiniteRecordsState<T>();
}

class _InfiniteRecordsState<T> extends State<InfiniteRecords<T>> {
  late final _records = InfiniteRecordsController<T>(
    load: widget.load,
    identity: widget.identity,
  )..addListener(_changed);
  ScrollPosition? _position;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_scroll);
      _position = position;
      _position?.addListener(_scroll);
    }
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _scroll();
    });
  }

  void _scroll() {
    final p = _position;
    if (_records.items.isEmpty ||
        (p != null && p.hasContentDimensions && p.extentAfter < 500)) {
      _records.next();
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _schedule();
  }

  @override
  void dispose() {
    _position?.removeListener(_scroll);
    _records.removeListener(_changed);
    _records.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _records.items;
    return SliverMainAxisGroup(
      slivers: [
        SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (_, index) => widget.itemBuilder(rows[index]),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _records.loading
                ? const Center(child: CircularProgressIndicator())
                : _records.error != null
                ? Column(
                    children: [
                      const Text('Не удалось загрузить записи.'),
                      TextButton(
                        onPressed: () => _records.next(retry: true),
                        child: const Text('Повторить'),
                      ),
                    ],
                  )
                : rows.isEmpty
                ? widget.emptyState ?? Text(widget.emptyMessage)
                : !_records.hasMore && widget.showCompletionMessage
                ? const Center(child: Text('Все записи загружены'))
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
