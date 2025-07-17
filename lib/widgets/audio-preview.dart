import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPreview extends StatefulWidget {
  final String url;
  const AudioPreview({required this.url});

  @override
  State<AudioPreview> createState() => AudioPreviewState();
}

class AudioPreviewState extends State<AudioPreview> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      title: const Text('Audio'),
      subtitle: Text(widget.url),
      onTap: _togglePlay,
    );
  }
}
