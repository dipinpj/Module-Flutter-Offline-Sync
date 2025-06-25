# Migration Guide: From Local Sync Code to Flutter Sync Package

This guide shows how to migrate from your existing sync code to the `flutter_sync_package`.

## Step 1: Add the Package

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_sync_package:
    git:
      url: https://github.com/yourusername/flutter_sync_package.git
      ref: main
```

## Step 2: Update Your Main App

Replace your existing sync initialization in `main.dart`:

### Before:
```dart
// Your existing sync code
await context.viewModelProvider.initializeSyncSystem();
_performBackgroundSyncCheck();
```

### After:
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
    firebaseProjectId: 'flutter-sync-d703d', // Your project ID
    firebaseApiKey: 'AIzaSyC8DhSa77Qb65-ys0x3xAGzSLazeyZwh14', // Your API key
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

## Step 3: Update Your Models

Your models already have the `type` field, so they're compatible with the package.

## Step 4: Replace Helper Classes

### Before:
```dart
import 'package:flutter_syncer/core/helper/firebase_helper.dart';
import 'package:flutter_syncer/offline/hive_helper.dart';
import 'package:flutter_syncer/core/utils/constants.dart';
import 'package:flutter_syncer/core/utils/network_utils.dart';
```

### After:
```dart
import 'package:flutter_sync_package/flutter_sync_package.dart';
```

## Step 5: Update Helper Instances

### Before:
```dart
HiveHelper helper = HiveHelper();
FirestoreHelper firestoreHelper = FirestoreHelper();
```

### After:
```dart
final hiveHelper = HiveHelper<YourModelType>();
final firestoreHelper = FirestoreHelper(
  projectId: 'your-project-id',
  apiKey: 'your-api-key',
);
```

## Step 6: Remove Background Sync Code

Remove the background sync code from your `main.dart`:

### Remove these methods:
- `_performBackgroundSyncCheck()`
- `_hasPendingItems()`
- `_handleUserOperation()`
- `_handleDocumentOperation()`

The package handles all of this automatically.

## Step 7: Update Your Pages

### Before (add_student.dart):
```dart
HiveHelper helper = HiveHelper();
helper.addItem(Collections.students, newStudent);

// Manual sync logic...
```

### After (add_student.dart):
```dart
import 'package:flutter_sync_package/flutter_sync_package.dart';

final hiveHelper = HiveHelper<Student>();
await hiveHelper.addItem('students', newStudent);

// Background sync is automatic!
```

## Step 8: Update Network Checks

### Before:
```dart
bool isConnected = await checkInternetAndAlert(context);
```

### After:
```dart
bool isConnected = await NetworkUtils.checkInternetAndAlert(context);
```

## Step 9: Update Dialog Utils

### Before:
```dart
import 'package:flutter_syncer/core/utils/dialog_utils.dart';
showLoadingDialog(context);
showSnackBarMessage(context, 'Message');
```

### After:
```dart
import 'package:flutter_sync_package/flutter_sync_package.dart';
showLoadingDialog(context);
showSnackBarMessage(context, 'Message');
```

## Step 10: Remove Old Files

You can now remove these files from your project:
- `lib/core/helper/firebase_helper.dart`
- `lib/offline/hive_helper.dart`
- `lib/core/services/background_sync_service.dart`
- `lib/core/services/background_task_handler.dart`
- `lib/core/utils/constants.dart`
- `lib/core/utils/network_utils.dart`
- `lib/core/utils/dialog_utils.dart`

## Benefits of Migration

1. **Cleaner Code**: Less boilerplate code in your app
2. **Reusability**: Can be used in other projects
3. **Maintainability**: Centralized sync logic
4. **Updates**: Easy to get new features and bug fixes
5. **Testing**: Better testability with isolated package

## Example: Complete Migration

Here's how your `main.dart` would look after migration:

```dart
import 'dart:io';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sync_package/flutter_sync_package.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:shared_preferences/shared_preferences.dart';

// Your model imports...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  
  // Register your Hive adapters
  Hive.registerAdapter(AnnouncementAdapter());
  Hive.registerAdapter(AttendanceAdapter());
  // ... other adapters
  
  await Hive.openBox('hive_box');

  // Configure the sync package
  final config = SyncConfig(
    firebaseProjectId: 'flutter-sync-d703d',
    firebaseApiKey: 'AIzaSyC8DhSa77Qb65-ys0x3xAGzSLazeyZwh14',
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

  // Get user preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String userType = prefs.getString('type') ?? '';

  runApp(MyApp(isLoggedIn: isLoggedIn, userType: userType));
}

class MyApp extends StatelessWidget {
  // Your existing app code...
}

class AppHomePage extends StatefulWidget {
  // Your existing app code...
}

class _AppHomePageState extends State<AppHomePage> {
  @override
  void initState() {
    super.initState();
    // No need for manual sync initialization - it's handled by the package
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method...
  }
}
```

That's it! Your app now uses the centralized sync package with all the same functionality but much cleaner code. 