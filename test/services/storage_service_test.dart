import 'package:flutter_test/flutter_test.dart';
import 'package:stil_asist/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService service;

    setUp(() {
      service = StorageService();
    });

    test('service instantiates without errors', () {
      expect(() => StorageService(), returnsNormally);
    });

    test('deleteLocalImage handles non-existent file gracefully', () async {
      // Test that deleting a non-existent file doesn't throw
      expect(
        () async => await service.deleteLocalImage('/non/existent/path.jpg'),
        returnsNormally,
      );
    });
  });
}
