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

  group('SignaturesRepository', () {
    SignaturesRepository signaturesRepository = SignaturesRepository();

    test('should save & get signature', () async {
      // Given
      const message = 'message';
      const signature = 'signature';
      // When
      await signaturesRepository.saveSignature(message, signature);
      // Then
      final result = await signaturesRepository.getSignature(message);
      expect(result, signature);
    });

    test('should fail get signature', () async {
      // Given
      const message = 'other_message';

      // When
      final result = await signaturesRepository.getSignature(message);
      // Then
      expect(result, null);
    });
  });
}
