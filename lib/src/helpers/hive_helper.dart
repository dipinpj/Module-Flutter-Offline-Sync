import 'package:hive/hive.dart';

class HiveHelper<T> {
  // The box name is the same throughout the application.
  static const String boxName = 'syncBox';

  HiveHelper();

  Future<List<T>> getItems(String key) async {
    final box = await Hive.openBox(boxName);
    return box.get(key, defaultValue: <T>[])!;
  }

  Future<void> addItem(String key, T item) async {
    final box = await Hive.openBox(boxName);
    final items = box.get(key, defaultValue: <T>[])!;
    items.add(item);
    await box.put(key, items);
  }

  Future<void> editItem(
      String key, bool Function(T) predicate, T newItem) async {
    final box = await Hive.openBox(boxName);
    final items = box.get(key, defaultValue: <T>[])!;
    final index = items.indexWhere(predicate);
    if (index != -1) {
      items[index] = newItem;
      await box.put(key, items);
    }
  }

  Future<void> removeItem(String key, bool Function(T) predicate) async {
    final box = await Hive.openBox(boxName);
    final items = box.get(key, defaultValue: <T>[])!;
    final index = items.indexWhere(predicate);
    if (index != -1) {
      items.removeAt(index);
      await box.put(key, items);
    }
  }

  Future<void> deleteAllKeys() async {
    final box = await Hive.openBox(boxName);
    await box.clear();
  }

  Future<void> deleteItem(String key) async {
    final box = await Hive.openBox(boxName);
    await box.delete(key);
  }

  /// Get sync queue statistics
  Future<Map<String, int>> getSyncQueueStats(List<String> collections) async {
    try {
      final box = await Hive.openBox(boxName);
      final stats = <String, int>{};

      for (String collection in collections) {
        final data = box.get(collection, defaultValue: <dynamic>[]);
        stats[collection] = data.length;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  /// Check if there are any pending items
  Future<bool> hasPendingItems(List<String> collections) async {
    try {
      final box = await Hive.openBox(boxName);

      for (String collection in collections) {
        final items = box.get(collection, defaultValue: <dynamic>[]);
        if (items.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
