import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'ad_playlist.dart';

/// Manage the list of commercial clips stored on this phone.
class AdLibraryScreen extends StatefulWidget {
  const AdLibraryScreen({super.key});

  @override
  State<AdLibraryScreen> createState() => _AdLibraryScreenState();
}

class _AdLibraryScreenState extends State<AdLibraryScreen> {
  final _playlist = AdPlaylist();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _playlist.load();
    await _playlist.pruneMissing();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addAd() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    if (picked.path == null) return;

    final name = await _askName(
      suggested: picked.name.split('.').first,
    );
    if (name == null) return;

    final seconds = await _askDuration();
    if (seconds == null) return;

    await _playlist.addFromFile(
      source: File(picked.path!),
      name: name,
      durationSeconds: seconds,
    );

    if (mounted) setState(() {});
  }

  Future<String?> _askName({required String suggested}) async {
    final controller = TextEditingController(text: suggested);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ad name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Coca-Cola 15s'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<int?> _askDuration() async {
    final controller = TextEditingController(text: '15');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duration (seconds)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(AdClip clip) async {
    final name = await _askName(suggested: clip.name);
    if (name == null || name.isEmpty) return;
    await _playlist.rename(clip.id, name);
    if (mounted) setState(() {});
  }

  Future<void> _delete(AdClip clip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ad?'),
        content: Text(clip.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _playlist.remove(clip.id);
    if (mounted) setState(() {});
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AD LIBRARY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAd,
            tooltip: 'Add ad',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _playlist.clips.isEmpty
              ? _EmptyState(onAdd: _addAd)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _playlist.clips.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (_, i) {
                          final c = _playlist.clips[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.movie,
                              color: Colors.orangeAccent,
                            ),
                            title: Text(c.name),
                            subtitle: Text(
                              _formatDuration(c.durationSeconds),
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white54),
                                  onPressed: () => _rename(c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () => _delete(c),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${_playlist.clips.length} ads • '
                        'total ${_formatDuration(_playlist.totalSeconds)}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_outlined,
              size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No ads yet',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a video file to use as a commercial break.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('ADD AD'),
          ),
        ],
      ),
    );
  }
}
