# Flutter Sync Package

A Flutter package for offline-first data synchronization with Firebase. This package provides a complete solution for managing data synchronization between local storage (Hive) and Firebase Firestore, with support for create, update, and delete operations.

## Features

- **Offline-First Architecture**: Data is stored locally first, then synced when online
- **Background Sync**: Automatic background synchronization using WorkManager
- **Operation Type Support**: Full CRUD operations (Create, Read, Update, Delete)
- **Network Awareness**: Intelligent handling of network connectivity
- **Error Handling**: Robust error handling and retry mechanisms
- **Configurable**: Easy to configure for different Firebase projects
- **User Management**: Special handling for Firebase Auth users

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_sync_package:
    git:
      url: https://github.com/yourusername/flutter_sync_package.git
      ref: main
```

## Usage

### 1. Initialize the Package

```dart
import 'package:flutter_sync_package/flutter_sync_package.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Configure the sync package
  final config = SyncConfig(
    firebaseProjectId: 'your-project-id',
    firebaseApiKey: 'your-api-key',
    syncInterval: Duration(minutes: 15),
    enableBackgroundSync: true,
    collections: [
      'students',
      'teachers',
      'subjects',
      'classrooms',
      'announcements',
      'attendance',
    ],
  );
  
  await FlutterSyncPackage.initialize(config);
  
  runApp(MyApp());
}
```

### 2. Set Up Your Models

Your models should include a `type` field to track the operation:

```dart
@HiveType(typeId: 1)
class Student extends HiveObject {
  @HiveField(0)
  final String? name;
  
  @HiveField(1)
  final String? email;
  
  @HiveField(2)
  final String? type; // 'create', 'update', 'delete'
  
  // ... other fields
  
  Student({
    this.name,
    this.email,
    this.type,
    // ... other parameters
  });
}
```

### 3. Use the Sync Helpers

```dart
// Create helpers
final firestoreHelper = FirestoreHelper(
  projectId: 'your-project-id',
  apiKey: 'your-api-key',
);

final hiveHelper = HiveHelper<Student>();

// Add data to local storage
final student = Student(
  name: 'John Doe',
  email: 'john@example.com',
  type: 'create', // or 'update', 'delete'
);

await hiveHelper.addItem('students', student);

// The background sync will automatically handle the Firebase sync
```

### 4. Manual Sync

```dart
// Trigger manual sync
await BackgroundTaskHandler.registerOneTimeSync();

// Check sync status
final status = await BackgroundTaskHandler.getSyncStatus();
final stats = await BackgroundTaskHandler.getSyncQueueStats();
```

## API Reference

### SyncConfig

Configuration class for the sync package:

```dart
class SyncConfig {
  final String firebaseProjectId;
  final String firebaseApiKey;
  final Duration syncInterval;
  final bool enableBackgroundSync;
  final List<String> collections;
}
```

### FirestoreHelper

Helper class for Firebase operations:

```dart
class FirestoreHelper {
  Future<bool> addDocument(String collection, Map<String, dynamic> data);
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data);
  Future<void> deleteDocument(String collection, String docId);
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data);
  Future<bool> deleteUser(String idToken);
}
```

### HiveHelper

Helper class for local storage operations:

```dart
class HiveHelper<T> {
  Future<List<T>> getItems(String key);
  Future<void> addItem(String key, T item);
  Future<void> removeItem(String key, bool Function(T) predicate);
  Future<Map<String, int>> getSyncQueueStats(List<String> collections);
  Future<bool> hasPendingItems(List<String> collections);
}
```

### BackgroundTaskHandler

Handler for background sync operations:

```dart
class BackgroundTaskHandler {
  static Future<void> initialize();
  static Future<void> registerPeriodicSync({Duration? frequency});
  static Future<void> registerOneTimeSync();
  static Future<void> cancelAllTasks();
  static Future<String> getSyncStatus();
  static Future<DateTime?> getLastSyncTimestamp();
  static Future<Map<String, int>> getSyncQueueStats();
}
```

## Operation Types

The package supports three operation types:

- **create**: Creates a new document in Firebase
- **update**: Updates an existing document in Firebase
- **delete**: Deletes a document from Firebase

## Background Sync

The package automatically handles background synchronization:

1. **Periodic Sync**: Runs every 15 minutes (configurable)
2. **Network Constraints**: Only syncs when network is available
3. **Error Handling**: Failed operations remain in queue for retry
4. **Status Tracking**: Tracks sync status and timestamps

## Error Handling

The package provides comprehensive error handling:

- Network connectivity issues
- Firebase API errors
- Local storage errors
- Background task failures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on GitHub or contact the maintainers. 