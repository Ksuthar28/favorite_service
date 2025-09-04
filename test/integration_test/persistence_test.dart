import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    // Create a temp dir for Hive
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);

    // Open a box that stores favorite IDs (ints only)
    await Hive.openBox<int>('favoritesBox');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('should persist and restore favorite IDs', () async {
    final box = Hive.box<int>('favoritesBox');

    // Add favorites
    await box.put(1, 1);
    await box.put(2, 2);

    expect(box.values.toSet(), {1, 2});

    // Close + reopen Hive to simulate app restart
    await Hive.close();
    Hive.init(tempDir.path);
    await Hive.openBox<int>('favoritesBox');
    final reopenedBox = Hive.box<int>('favoritesBox');

    expect(reopenedBox.values.toSet(), {1, 2});
  });
}
