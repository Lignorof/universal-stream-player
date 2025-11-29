import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final Duration progress;
  final Duration total;
  final void Function(Duration)? onSeek;

  const ProgressBar({
    super.key,
    required this.progress,
    required this.total,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          min: 0.0,
          max: total.inMilliseconds.toDouble(),
          value: progress.inMilliseconds.toDouble().clamp(0.0, total.inMilliseconds.toDouble()),
          onChanged: (value) {
            onSeek?.call(Duration(milliseconds: value.toInt()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(progress)),
              Text(_formatDuration(total)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
