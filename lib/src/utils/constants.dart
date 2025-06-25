/// Common collection names for Firestore
class Collections {
  static const String users = 'users';
  static const String announcements = 'announcements';
  static const String attendance = 'attendance';
  static const String subjects = 'subjects';
  static const String classRooms = 'class';
  static const String students = 'students';
  static const String teachers = 'teachers';
  static const String assignments = 'assignments';
}

/// Common error messages
class ErrorMessages {
  static const String noInternet = 'No internet connection.';
  static const String unknown = 'Something went wrong.';
  static const String syncFailed = 'Sync failed. Please try again.';
  static const String offlineMode =
      'You are offline. Data will be synced when connection is restored.';
}

/// Sync operation types
class SyncOperationType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}

/// Sync status types
class SyncStatusType {
  static const String idle = 'idle';
  static const String syncing = 'syncing';
  static const String error = 'error';
  static const String offline = 'offline';
}
