import 'package:flutter/material.dart';

/// Bounded keyset pages: one look-ahead row detects the next page. Neither
/// expanding LIMIT nor repeatedly loading the full database is pagination.
class PagedRecords<T> extends StatefulWidget {
  const PagedRecords({
    super.key,
    required this.load,
    required this.itemBuilder,
    this.emptyMessage = 'Записей пока нет.',
  });
  static const pageSize = 20;
  final Future<List<T>> Function(T? after) load;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  @override
  State<PagedRecords<T>> createState() => _PagedRecordsState<T>();
}

class _PagedRecordsState<T> extends State<PagedRecords<T>> {
  final List<T?> _cursors = [null];
  late Future<List<T>> _page = widget.load(null);
  void _load() => setState(() {
    _page = widget.load(_cursors.last);
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
    future: _page,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            const Text('Не удалось загрузить записи.'),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        );
      }
      if (snapshot.connectionState != ConnectionState.done ||
          !snapshot.hasData) {
        return const LinearProgressIndicator();
      }
      final rows = snapshot.data!.take(PagedRecords.pageSize).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty) Text(widget.emptyMessage),
          ListView.builder(
            primary: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (_, index) => widget.itemBuilder(rows[index]),
          ),
          if (_cursors.length > 1 ||
              snapshot.data!.length > PagedRecords.pageSize)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _cursors.length == 1
                      ? null
                      : () {
                          _cursors.removeLast();
                          _load();
                        },
                  child: const Text('Назад к записям'),
                ),
                Text('Страница ${_cursors.length}'),
                TextButton(
                  onPressed: snapshot.data!.length <= PagedRecords.pageSize
                      ? null
                      : () {
                          _cursors.add(rows.last);
                          _load();
                        },
                  child: const Text('Следующие записи'),
                ),
              ],
            ),
        ],
      );
    },
  );
}
