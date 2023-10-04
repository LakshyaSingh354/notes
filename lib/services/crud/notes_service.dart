import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;


class DatabaseAlreadyOpenException implements Exception {}
class UnableToGetDocumentsDirectory implements Exception {}
class DatabaseIsNotOpen implements Exception {}
class CouldNotDeleteUser implements Exception {}
class UserAlreadyExists implements Exception {}
class UserDoesNotExist implements Exception {}
class CouldNotDeleteNote implements Exception {}
class CouldNotFindNote implements Exception {}


class NotesService {

  Database? _db;

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDBOrThrow();

    await getNote(
      id: note.id,
    );

    db.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    final db = _getDBOrThrow();
    final notes = await db.query(noteTable);
    
    return notes.map((note) => DatabaseNote.fromRow(note));
  } 

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDBOrThrow();
    final notes = await db.query(
      noteTable, 
      limit: 1, 
      where: 'id = ?', 
      whereArgs: [id]);
      if (notes.isEmpty) {
        throw CouldNotFindNote();
      } else {
        return DatabaseNote.fromRow(notes.first);
      }
  }

  Future<int> deleteAllNotes() async {
    final db = _getDBOrThrow();
    return await db.delete(noteTable);
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
    }
  }

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
  }) async {
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
    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
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