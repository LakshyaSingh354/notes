import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';



class NotesService {

  Database? _db;

  List<DatabaseNote> _notes = [];

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance();
  factory NotesService() => _shared;

  final _notesStreamController = StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      return await getUser(email: email);
    } on UserDoesNotExist {
      return await createUser(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();

    await getNote(
      id: note.id,
    );

    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    }else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final notes = await db.query(noteTable);
    
    return notes.map((note) => DatabaseNote.fromRow(note));
  } 

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final notes = await db.query(
      noteTable, 
      limit: 1, 
      where: 'id = ?', 
      whereArgs: [id]);
      if (notes.isEmpty) {
        throw CouldNotFindNote();
      } else {
        final note = DatabaseNote.fromRow(notes.first);
        _notes.removeWhere((note) => note.id == id);
        _notes.add(note);
        _notesStreamController.add(_notes);
        return note;
      }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final numberOfDeletions =  await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);

    return numberOfDeletions;
  }

  Future<void> deleteNote({
    required int id,
  }) async {
    final db = _getDBOrThrow();
    final deletedCount = await db.delete(
      noteTable, 
      where: 'id = ?', 
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw UserDoesNotExist();
    }
    // create note
    final noteID = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: '',
      isSyncedWithCloudColumn: 0,
    });

    final note = DatabaseNote(
      id: noteID,
      userId: owner.id,
      text: '',
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final results = await db.query(userTable, 
    limit: 1, 
    where: 'email = ?', 
    whereArgs: [email.toLowerCase()]
    );
    if (results.isEmpty) {
      throw UserDoesNotExist();
    }
    return DatabaseUser.fromRow(results.first);
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final results = await db.query(userTable, 
    limit: 1, 
    where: 'email = ?', 
    whereArgs: [email.toLowerCase()]
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(id: userId, email: email.toLowerCase());
  }

  Future<void> deleteuser({required String email}) async {
    await _ensureDbIsOpen();
    await _ensureDbIsOpen();
    final db = _getDBOrThrow();
    final deletedCount = await db.delete(
      userTable, where: 'email = ?', 
      whereArgs: [email.toLowerCase(),]);
  if (deletedCount != 1) {
    throw CouldNotDeleteUser();
  }
  }

  Database _getDBOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();    
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();

    } on DatabaseAlreadyOpenException {
      // do nothing
    }
  }
  
  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    } 
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;      

      await db.execute(createUserTableQuery);
      await db.execute(createNoteTableQuery);

      await _cacheNotes();

    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}


class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id, 
    required this.email,
  });
  
  DatabaseUser.fromRow(Map<String, Object?> map) 
    : id = map[idColumn] as int, 
    email = map[emailColumn] as String;

  @override
  String toString() {
    return 'Person, ID = $id, email = $email';
  }

  @override bool operator == (covariant DatabaseUser other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  

}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  const DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
    : id = map[idColumn] as int,
      userId = map[userIdColumn] as int,
      text = map[textColumn] as String,
      isSyncedWithCloud = (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() {
    return 'Note, ID = $id, userID = $userId, isSyncedWithCloud = $isSyncedWithCloud';
  }

  @override bool operator == (covariant DatabaseNote other) => id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const textColumn = "text";
const isSyncedWithCloudColumn = "is_synced_with_cloud";
const createNoteTableQuery = '''
        CREATE TABLE "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("user_id") REFERENCES "user"("id")
      );
      ''';
const createUserTableQuery = '''
        CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
      ''';