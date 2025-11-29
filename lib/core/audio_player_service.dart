import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'stream_track.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  StreamTrack? _currentTrack;
  StreamTrack? get currentTrack => _currentTrack;

  Stream<bool> get isPlayingStream => _audioPlayer.playingStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  Future<void> play(StreamTrack track) async {
    if (_currentTrack?.name == track.name && _currentTrack?.artist == track.artist) {
      if (!_audioPlayer.playing) _audioPlayer.play();
      return;
    }
    _currentTrack = track;
    notifyListeners();
    try {
      final searchQuery = '${track.name} ${track.artist}';
      final video = (await _yt.search.search(searchQuery)).first;
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioUrl = manifest.audioOnly.withHighestBitrate().url;
      await _audioPlayer.setUrl(audioUrl.toString());
      _audioPlayer.play();
    } catch (e) {
      print('Erro ao tocar a música: $e');
      _currentTrack = null;
      notifyListeners();
      throw Exception('Não foi possível encontrar uma fonte de áudio para esta música.');
    }
  }

  Future<void> pause() => _audioPlayer.pause();
  Future<void> resume() => _audioPlayer.play();
  Future<void> stop() {
    _audioPlayer.stop();
    _currentTrack = null;
    notifyListeners();
    return Future.value();
  }
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);

  @override
  void dispose() {
    _yt.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}

