import 'package:flutter/material.dart';

/// One audio channel in the mixer.
class AudioChannel {
  final String id;
  final String name;
  double volume; // 0.0 .. 1.0
  bool muted;

  AudioChannel({
    required this.id,
    required this.name,
    this.volume = 0.8,
    this.muted = false,
  });
}

/// Simple vertical-strip audio mixer. In the finished app the volume
/// values are pushed to the transport layer per source.
class AudioMixer extends StatefulWidget {
  final List<AudioChannel> channels;
  final void Function(AudioChannel) onChanged;

  const AudioMixer({
    super.key,
    required this.channels,
    required this.onChanged,
  });

  @override
  State<AudioMixer> createState() => _AudioMixerState();
}

class _AudioMixerState extends State<AudioMixer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUDIO',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: widget.channels.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white12),
              itemBuilder: (_, i) {
                final ch = widget.channels[i];
                return _ChannelStrip(
                  channel: ch,
                  onVolume: (v) {
                    ch.volume = v;
                    widget.onChanged(ch);
                    setState(() {});
                  },
                  onMute: () {
                    ch.muted = !ch.muted;
                    widget.onChanged(ch);
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelStrip extends StatelessWidget {
  final AudioChannel channel;
  final ValueChanged<double> onVolume;
  final VoidCallback onMute;

  const _ChannelStrip({
    required this.channel,
    required this.onVolume,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final muted = channel.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              channel.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted ? Colors.white24 : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Slider(
              value: muted ? 0.0 : channel.volume,
              onChanged: muted ? null : onVolume,
              activeColor: muted ? Colors.white24 : Colors.blueAccent,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              muted
                  ? 'MUTE'
                  : '${(channel.volume * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: muted ? Colors.redAccent : Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              muted ? Icons.volume_off : Icons.volume_up,
              color: muted ? Colors.redAccent : Colors.white54,
            ),
            onPressed: onMute,
          ),
        ],
      ),
    );
  }
}
