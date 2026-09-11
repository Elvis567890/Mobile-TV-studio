import 'package:flutter/material.dart';

/// A lower-third graphic that goes over the program video.
class TitleData {
  final String line1;
  final String line2;
  final Color accent;

  const TitleData({
    required this.line1,
    this.line2 = '',
    this.accent = Colors.blueAccent,
  });
}

/// The overlay itself. Place inside a Stack over the live program view.
class TitlesOverlay extends StatelessWidget {
  final TitleData? title;

  const TitlesOverlay({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      bottom: 24,
      child: AnimatedSlide(
        offset: Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            border: Border(
              left: BorderSide(color: title!.accent, width: 6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title!.line1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              if (title!.line2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  title!.line2,
                  style: TextStyle(
                    color: title!.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Editor panel used inside the director sidebar.
class TitlesEditor extends StatefulWidget {
  final TitleData? current;
  final void Function(TitleData?) onChanged;

  const TitlesEditor({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  State<TitlesEditor> createState() => _TitlesEditorState();
}

class _TitlesEditorState extends State<TitlesEditor> {
  late final TextEditingController _l1;
  late final TextEditingController _l2;

  @override
  void initState() {
    super.initState();
    _l1 = TextEditingController(text: widget.current?.line1 ?? '');
    _l2 = TextEditingController(text: widget.current?.line2 ?? '');
  }

  @override
  void dispose() {
    _l1.dispose();
    _l2.dispose();
    super.dispose();
  }

  void _apply() {
    if (_l1.text.trim().isEmpty) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(TitleData(
      line1: _l1.text.trim(),
      line2: _l2.text.trim(),
    ));
  }

  void _clear() {
    _l1.clear();
    _l2.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TITLES',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _l1,
            decoration: const InputDecoration(
              labelText: 'Line 1',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _l2,
            decoration: const InputDecoration(
              labelText: 'Line 2',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('CLEAR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('SHOW'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
