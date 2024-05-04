import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

const sigDbName = 'your_database.db';
const sigTableName = 'signatures';
const messageColName = 'message';
const signatureColName = 'signature';

class SignaturesRepository {
  static Database? _database;
  final Logger _logger = Logger();

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // Open the database (create if it doesn't exist)
    _database = await openDatabase(
      path.join(await getDatabasesPath(), sigDbName),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $sigTableName(id INTEGER PRIMARY KEY, $messageColName TEXT, $signatureColName TEXT)',
        );
      },
      version: 1,
    );
    return _database!;
  }

  // Save signature into the database
  Future<void> saveSignature(String message, String signature) async {
    final db = await database;
    try {
      _logger
          .i('Try to save signature message: $message, signature: $signature');
      var res = await db.insert(
        sigTableName,
        {
          messageColName: message,
          signatureColName: signature,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (res > 0) {
        _logger.i(
            'Signature message: $message, signature: $signature saved successfully');
      } else {
        _logger.w(
            'Failed to save signature, errorCode: $res, message: $message, signature: $signature');
      }
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  // Retrieve signature from the database
  Future<String?> getSignature(String message) async {
    final db = await database;
    _logger.i('Try to get signature message: $message');
    final List<Map<String, dynamic>> maps = await db.query(
      sigTableName,
      where: '$messageColName = ?',
      whereArgs: [message],
    );
    if (maps.isNotEmpty) {
      var signature = maps.first[signatureColName] as String;
      _logger.i('Signature message: $message found, signature: $signature');
      return signature;
    }
    _logger.w('Signature message: $message not found');
    return null;
  }
}
