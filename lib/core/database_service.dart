import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:universal_stream_player/models/stream_playlist.dart';
import 'package:universal_stream_player/models/stream_track.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('usp_main.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imageUrl TEXT,
        owner TEXT,
        source TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlistId TEXT NOT NULL,
        name TEXT NOT NULL,
        artist TEXT NOT NULL,
        albumName TEXT,
        imageUrl TEXT,
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> cachePlaylists(List<StreamPlaylist> playlists) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final playlist in playlists) {
      batch.insert('playlists', playlist.toDbJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheTracks(String playlistId, List<StreamTrack> tracks) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('tracks', where: 'playlistId = ?', whereArgs: [playlistId]);
    for (final track in tracks) {
      batch.insert('tracks', track.toDbJson(playlistId), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<StreamPlaylist>> getCachedPlaylists() async {
    final db = await instance.database;
    final maps = await db.query('playlists', orderBy: 'name');
    if (maps.isEmpty) return [];
    return maps.map((json) => StreamPlaylist.fromDbJson(json)).toList();
  }

  Future<List<StreamTrack>> getCachedTracks(String playlistId) async {
    final db = await instance.database;
    final maps = await db.query('tracks', where: 'playlistId = ?', whereArgs: [playlistId]);
    if (maps.isEmpty) return [];
    return maps.map((json) => StreamTrack.fromDbJson(json)).toList();
  }
}
