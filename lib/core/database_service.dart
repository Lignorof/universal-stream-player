import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:universal_stream_player/models/stream_playlist.dart';
import 'package:universal_stream_player/models/stream_track.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'universal_stream_player.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            title TEXT,
            source TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tracks (
            id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            album TEXT,
            durationMs INTEGER,
            url TEXT,
            source TEXT,
            playlistId TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertPlaylist(StreamPlaylist playlist) async {
    final db = _db;
    if (db == null) throw Exception('Database not initialized');
    await db.insert(
      'playlists',
      {'id': playlist.id, 'title': playlist.title, 'source': playlist.source},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final track in playlist.tracks) {
      await db.insert(
        'tracks',
        {
          'id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'durationMs': track.durationMs,
          'url': track.url,
          'source': track.source,
          'playlistId': playlist.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<StreamPlaylist>> getPlaylists() async {
    final db = _db;
    if (db == null) throw Exception('Database not initialized');

    final playlistRows = await db.query('playlists');
    final List<StreamPlaylist> playlists = [];

    for (final row in playlistRows) {
      final tracksRows = await db.query('tracks', where: 'playlistId = ?', whereArgs: [row['id']]);
      final tracks = tracksRows.map((t) => StreamTrack.fromMap(Map<String, dynamic>.from(t))).toList();
      playlists.add(StreamPlaylist(
        id: row['id'] as String,
        title: row['title'] as String,
        source: row['source'] as String?,
        tracks: tracks,
      ));
    }

    return playlists;
  }
}