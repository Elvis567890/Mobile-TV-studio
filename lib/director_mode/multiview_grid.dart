import 'package:flutter/material.dart';

/// One tile in the multiview. In a real broadcast this carries a live
/// video thumbnail. Until the native camera bridge is wired, `preview`
/// can be null and the tile shows its state instead.
class SourceTile {
  final String id;
  final String name;
  final Widget? preview;

  const SourceTile({
    required this.id,
    required this.name,
    this.preview,
  });
}

/// State of a source as seen by the director.
enum TileState { offline, preview, live, ad }

class MultiviewGrid extends StatelessWidget {
  final List<SourceTile> sources;
  final String? liveId;
  final String? previewId;
  final void Function(String id) onTap;
  final int columns;

  const MultiviewGrid({
    super.key,
    required this.sources,
    required this.onTap,
    this.liveId,
    this.previewId,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Center(
        child: Text(
          'No cameras connected',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sources.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 16 / 10,
      ),
      itemBuilder: (_, i) {
        final s = sources[i];
        final state = s.id == liveId
            ? TileState.live
            : s.id == previewId
                ? TileState.preview
                : TileState.offline;
        return _Tile(
          source: s,
          state: state,
          onTap: () => onTap(s.id),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final SourceTile source;
  final TileState state;
  final VoidCallback onTap;

  const _Tile({
    required this.source,
    required this.state,
    required this.onTap,
  });

  Color get _border {
    switch (state) {
      case TileState.live:
        return Colors.redAccent;
      case TileState.preview:
        return Colors.greenAccent;
      case TileState.ad:
        return Colors.orangeAccent;
      case TileState.offline:
        return Colors.white12;
    }
  }

  String get _badge {
    switch (state) {
      case TileState.live:
        return 'LIVE';
      case TileState.preview:
        return 'PREVIEW';
      case TileState.ad:
        return 'AD';
      case TileState.offline:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderWidth = state == TileState.live ? 3.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: borderWidth),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (source.preview != null)
              source.preview!
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: _border.withOpacity(0.7),
                      size: 40,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      source.name,
                      style: TextStyle(
                        color: _border.withOpacity(0.8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (_badge.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _badge,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
