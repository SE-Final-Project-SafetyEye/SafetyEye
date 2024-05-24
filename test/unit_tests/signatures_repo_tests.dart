import 'package:flutter_test/flutter_test.dart';
import 'package:safety_eye_app/repositories/signatures_repo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize database before running tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Open the database once for all tests
    sqfliteFfiInit();
    // Set global factory
    databaseFactory = databaseFactoryFfi;
    await SignaturesRepository.database;
  });

  tearDownAll(() async {
    // Close the database once all tests are done
    await SignaturesRepository.deleteDatabase();
  });

  group('SignaturesRepository', () {
    SignaturesRepository signaturesRepository = SignaturesRepository();

    test('should save & get signature', () async {
      // Given
      const message = 'message';
      const signature = 'signature';
      const publicKey = 'publicKey';
      const expected = (signature, publicKey);
      // When
      await signaturesRepository.saveSignature(message, signature, publicKey);
      // Then
      final result = await signaturesRepository.getSignature(message);
      expect(result, expected);
    });

    test('should fail get signature', () async {
      // Given
      const message = 'other_message';
      const expected = (null, null);
      // When
      final result = await signaturesRepository.getSignature(message);
      // Then
      expect(result, expected);
    });
  });
}
