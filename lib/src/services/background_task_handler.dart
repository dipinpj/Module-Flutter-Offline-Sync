import 'dart:developer';
import 'package:workmanager/workmanager.dart';
import 'background_sync_service.dart';

class BackgroundTaskHandler {
  static const String _syncTaskName = 'background_sync_task';
  static const String _syncTaskTag = 'background_sync';

  static BackgroundSyncService? _syncService;

  /// Initialize background tasks
  static Future<void> initialize() async {
    try {
      log('Initializing WorkManager...', name: 'background_task');
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
      log('WorkManager initialized successfully', name: 'background_task');
    } catch (e) {
      log('Error initializing WorkManager: $e', name: 'background_task');
      rethrow;
    }
  }

  /// Set the sync service instance
  static void setSyncService(BackgroundSyncService syncService) {
    _syncService = syncService;
  }

  /// Register periodic background sync task
  static Future<void> registerPeriodicSync({Duration? frequency}) async {
    try {
      log('Registering periodic sync task...', name: 'background_task');

      // Cancel any existing tasks first
      await Workmanager().cancelAll();

      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskTag,
        frequency: frequency ?? Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: Duration(minutes: 1), // Start after 1 minute
      );
      log(
        'Periodic sync task registered successfully with ${frequency?.inMinutes ?? 15}-minute frequency',
        name: 'background_task',
      );
    } catch (e) {
      log('Error registering periodic sync task: $e', name: 'background_task');
      rethrow;
    }
  }

  /// Register one-time background sync task
  static Future<void> registerOneTimeSync() async {
    try {
      await Workmanager().registerOneOffTask(
        '${_syncTaskName}_once',
        _syncTaskTag,
        initialDelay: Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      log(
        'One-time sync task registered successfully',
        name: 'background_task',
      );
    } catch (e) {
      log('Error registering one-time sync task: $e', name: 'background_task');
    }
  }

  /// Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      log('All background tasks cancelled', name: 'background_task');
    } catch (e) {
      log('Error cancelling background tasks: $e', name: 'background_task');
    }
  }

  /// Cancel specific task
  static Future<void> cancelTask(String taskName) async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      log('Task $taskName cancelled', name: 'background_task');
    } catch (e) {
      log('Error cancelling task $taskName: $e', name: 'background_task');
    }
  }

  /// Get sync status
  static Future<String> getSyncStatus() async {
    if (_syncService == null) {
      throw StateError(
          'Sync service not initialized. Call setSyncService() first.');
    }
    return await _syncService!.getSyncStatus();
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTimestamp() async {
    if (_syncService == null) {
      throw StateError(
          'Sync service not initialized. Call setSyncService() first.');
    }
    return await _syncService!.getLastSyncTimestamp();
  }

  /// Get sync queue statistics
  static Future<Map<String, int>> getSyncQueueStats() async {
    if (_syncService == null) {
      throw StateError(
          'Sync service not initialized. Call setSyncService() first.');
    }
    return await _syncService!.getSyncQueueStats();
  }

  /// Check if background sync system is properly initialized
  static Future<bool> isBackgroundSyncInitialized() async {
    try {
      if (_syncService == null) return false;
      final syncInitialized = await _syncService!.isSyncSystemInitialized();
      log(
        'Background sync initialization check: $syncInitialized',
        name: 'background_task',
      );
      return syncInitialized;
    } catch (e) {
      log(
        'Error checking background sync initialization: $e',
        name: 'background_task',
      );
      return false;
    }
  }

  /// Get detailed background sync status
  static Future<Map<String, dynamic>> getDetailedBackgroundSyncStatus() async {
    try {
      if (_syncService == null) {
        return {'error': 'Sync service not initialized'};
      }
      final syncStatus = await _syncService!.getDetailedSyncStatus();
      log(
        'Detailed background sync status: $syncStatus',
        name: 'background_task',
      );
      return syncStatus;
    } catch (e) {
      log(
        'Error getting detailed background sync status: $e',
        name: 'background_task',
      );
      return {'error': e.toString()};
    }
  }
}

/// Callback function that WorkManager will call
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    log(
      'Background task started: $taskName at ${DateTime.now()}',
      name: 'background_task',
    );

    try {
      // Log task details
      log('Task input data: $inputData', name: 'background_task');

      // Perform the background sync if service is available
      if (BackgroundTaskHandler._syncService != null) {
        await BackgroundTaskHandler._syncService!.performBackgroundSync();
      } else {
        log('Sync service not available', name: 'background_task');
      }

      log(
        'Background task completed successfully: $taskName at ${DateTime.now()}',
        name: 'background_task',
      );
      return Future.value(true);
    } catch (e, stackTrace) {
      log(
        'Background task failed: $taskName, Error: $e\nStackTrace: $stackTrace',
        name: 'background_task',
      );
      return Future.value(false);
    }
  });
}
