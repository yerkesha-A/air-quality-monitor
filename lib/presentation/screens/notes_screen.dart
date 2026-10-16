import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../data/local/local_store.dart';
import '../bloc/air_bloc.dart';
import '../widgets/primitives.dart';
import '../widgets/paged_records.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  XFile? _photo;
  int _revision = 0;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _reload();
    _recoverPhoto();
  }

  Future<void> _recoverPhoto() async {
    final recovered = await _picker.retrieveLostData();
    if (mounted && recovered.files?.isNotEmpty == true) {
      setState(() => _photo = recovered.files!.first);
    }
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _revision++);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _camera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (mounted && file != null) setState(() => _photo = file);
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Камера недоступна. Проверьте разрешения Android.',
        );
      }
    }
  }

  Future<void> _save() async {
    final place = context.read<AirBloc>().state.place;
    if (place == null || (_text.text.trim().isEmpty && _photo == null)) return;
    setState(() => _saving = true);
    try {
      String? saved;
      if (_photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        saved = path.join(
          directory.path,
          'note_${DateTime.now().microsecondsSinceEpoch}.jpg',
        );
        await File(_photo!.path).copy(saved);
      }
      if (!mounted) return;
      await context.read<LocalStore>().addNote(place, _text.text.trim(), saved);
      _text.clear();
      setState(() => _photo = null);
      await _reload();
    } catch (_) {
      if (mounted) showMessage(context, 'Не удалось сохранить заметку.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = context.watch<AirBloc>().state.place;
    return AirScaffold(
      appBar: AppBar(title: const Text('Заметки о месте')),
      body: PageBody(
        children: [
          const Eyebrow('ЛИЧНЫЙ ДНЕВНИК'),
          const SizedBox(height: 16),
          Text(
            place?.name ?? 'Выберите город',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'Запишите, что заметили: дым, пыль или необычный запах. Фото и заметки хранятся только на этом устройстве и не измеряют AQI.',
          ),
          const SizedBox(height: 24),
          TextField(
            stylusHandwritingEnabled: false,
            controller: _text,
            onChanged: (_) => setState(() {}),
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Что происходит вокруг?',
            ),
          ),
          if (_photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_photo!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Text('Фото недоступно'),
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _saving || place == null ? null : _camera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Сделать фото'),
              ),
              FilledButton(
                onPressed:
                    _saving ||
                        place == null ||
                        (_text.text.trim().isEmpty && _photo == null)
                    ? null
                    : _save,
                child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
              ),
            ],
          ),
          const SectionTitle('Ваши заметки'),
          if (place != null)
            PagedRecords<Map<String, Object?>>(
              key: ValueKey('${place.id}:$_revision'),
              load: (after) =>
                  context.read<LocalStore>().notesPage(place, after: after),
              emptyMessage: 'Здесь появятся сохранённые заметки.',
              itemBuilder: (note) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(note['image'] as String),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Text('Фото недоступно'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(note['text'] as String),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateLabel(
                                DateTime.fromMillisecondsSinceEpoch(
                                  note['created'] as int,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Удалить заметку',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Удалить заметку?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Отмена'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) return;
                              await context.read<LocalStore>().deleteNote(
                                note['id'] as int,
                              );
                              if (note['image'] != null) {
                                final file = File(note['image'] as String);
                                if (await file.exists()) await file.delete();
                              }
                              await _reload();
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
