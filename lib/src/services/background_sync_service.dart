import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/firebase_helper.dart';
import '../helpers/hive_helper.dart';
import '../utils/network_utils.dart';
import '../utils/constants.dart';

class BackgroundSyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncStatusKey = 'sync_status';

  final FirestoreHelper _firestoreHelper;
  final HiveHelper _hiveHelper;
  final List<String> _collections;

  BackgroundSyncService({
    required FirestoreHelper firestoreHelper,
    required HiveHelper hiveHelper,
    required List<String> collections,
  })  : _firestoreHelper = firestoreHelper,
        _hiveHelper = hiveHelper,
        _collections = collections;

  /// Check if internet is available
  Future<bool> _isInternetAvailable() async {
    return await NetworkUtils.isInternetAvailable();
  }

  /// Get unsynced data from Hive
  Future<Map<String, List<dynamic>>> _getUnsyncedData() async {
    try {
      final unsyncedData = <String, List<dynamic>>{};

      for (String collection in _collections) {
        final items = await _hiveHelper.getItems(collection);
        if (items.isNotEmpty) {
          unsyncedData[collection] = items;
        }
      }

      log('Found unsynced data: ${unsyncedData.length} collections',
          name: 'background_sync');
      return unsyncedData;
    } catch (e) {
      log('Error getting unsynced data: $e', name: 'background_sync');
      return {};
    }
  }

  /// Sync data to Firebase
  Future<bool> _syncDataToFirebase(
    String collection,
    List<dynamic> data,
  ) async {
    try {
      log('Syncing $collection with ${data.length} items',
          name: 'background_sync');

      int successCount = 0;
      int failureCount = 0;

      for (dynamic item in data) {
        try {
          Map<String, dynamic> map = item.toMap();
          String operationType = item.type ?? SyncOperationType.create;

          bool success = false;

          if (collection == Collections.students ||
              collection == Collections.teachers) {
            success = await _handleUserOperation(
                collection, item, map, operationType);
          } else {
            success = await _handleDocumentOperation(
                collection, item, map, operationType);
          }

          if (success) {
            successCount++;
            // Remove from Hive after successful sync
            await _hiveHelper.removeItem(
              collection,
              (element) => element == item,
            );
          } else {
            failureCount++;
            item.syncError = 'Sync failed';
          }
        } catch (e) {
          failureCount++;
          log('Error syncing item to $collection: $e', name: 'background_sync');
        }
      }

      log('Sync completed for $collection: $successCount success, $failureCount failures',
          name: 'background_sync');
      return failureCount == 0;
    } catch (e) {
      log('Error syncing $collection to Firebase: $e', name: 'background_sync');
      return false;
    }
  }

  /// Handle user operations (students/teachers)
  Future<bool> _handleUserOperation(
    String collection,
    dynamic item,
    Map<String, dynamic> map,
    String operationType,
  ) async {
    try {
      switch (operationType) {
        case SyncOperationType.create:
          final createResult = await _firestoreHelper.createUser(map);
          if (createResult['success']) {
            map['idToken'] = createResult['idToken'];
            final addDocResult = await _firestoreHelper.addDocumentInPath(
              Collections.users,
              createResult['localId'],
              map,
            );
            return addDocResult['success'];
          }
          return false;

        case SyncOperationType.update:
          if (item.documentId != null) {
            await _firestoreHelper.updateDocument(
              Collections.users,
              item.documentId!,
              map,
            );
            return true;
          }
          return false;

        case SyncOperationType.delete:
          if (item.documentId != null) {
            await _firestoreHelper.deleteDocument(
              Collections.users,
              item.documentId!,
            );
            if (item.idToken != null) {
              await _firestoreHelper.deleteUser(item.idToken!);
            }
            return true;
          }
          return false;

        default:
          return await _handleUserOperation(
              collection, item, map, SyncOperationType.create);
      }
    } catch (e) {
      log('Error handling user operation $operationType: $e',
          name: 'background_sync');
      return false;
    }
  }

  /// Handle document operations (subjects, classrooms, announcements, attendance)
  Future<bool> _handleDocumentOperation(
    String collection,
    dynamic item,
    Map<String, dynamic> map,
    String operationType,
  ) async {
    try {
      switch (operationType) {
        case SyncOperationType.create:
          return await _firestoreHelper.addDocument(collection, map);

        case SyncOperationType.update:
          if (item.documentId != null) {
            await _firestoreHelper.updateDocument(
              collection,
              item.documentId!,
              map,
            );
            return true;
          }
          return false;

        case SyncOperationType.delete:
          if (item.documentId != null) {
            await _firestoreHelper.deleteDocument(
              collection,
              item.documentId!,
            );
            return true;
          }
          return false;

        default:
          return await _firestoreHelper.addDocument(collection, map);
      }
    } catch (e) {
      log('Error handling document operation $operationType: $e',
          name: 'background_sync');
      return false;
    }
  }

  /// Main sync function
  Future<void> performBackgroundSync() async {
    log('Starting background sync at ${DateTime.now()}...',
        name: 'background_sync');

    try {
      // Check internet connectivity
      if (!await _isInternetAvailable()) {
        log('No internet connection, skipping sync', name: 'background_sync');
        await _updateSyncStatus(SyncStatusType.offline);
        return;
      }

      // Initialize Firebase if not already done
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Firebase might already be initialized
        log('Firebase initialization check: $e', name: 'background_sync');
      }

      // Get unsynced data
      final unsyncedData = await _getUnsyncedData();

      if (unsyncedData.isEmpty) {
        log('No unsynced data found', name: 'background_sync');
        await _updateSyncStatus(SyncStatusType.idle);
        return;
      }

      // Sync each collection
      bool allSynced = true;
      for (String collection in unsyncedData.keys) {
        final data = unsyncedData[collection]!;
        final success = await _syncDataToFirebase(collection, data);

        if (!success) {
          allSynced = false;
        }
      }

      // Update sync status
      if (allSynced) {
        await _updateSyncStatus(SyncStatusType.idle);
        await _updateLastSyncTimestamp();
        log('Background sync completed successfully', name: 'background_sync');
      } else {
        await _updateSyncStatus(SyncStatusType.error);
        log('Background sync completed with some failures',
            name: 'background_sync');
      }
    } catch (e) {
      log('Error during background sync: $e', name: 'background_sync');
      await _updateSyncStatus(SyncStatusType.error);
    }
  }

  /// Update sync status
  Future<void> _updateSyncStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncStatusKey, status);
    } catch (e) {
      log('Error updating sync status: $e', name: 'background_sync');
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log('Error updating last sync timestamp: $e', name: 'background_sync');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      log('Error getting last sync timestamp: $e', name: 'background_sync');
      return null;
    }
  }

  /// Get sync status
  Future<String> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_syncStatusKey) ?? SyncStatusType.idle;
    } catch (e) {
      log('Error getting sync status: $e', name: 'background_sync');
      return SyncStatusType.error;
    }
  }

  /// Get sync queue statistics
  Future<Map<String, int>> getSyncQueueStats() async {
    return await _hiveHelper.getSyncQueueStats(_collections);
  }

  /// Check if sync system is properly initialized
  Future<bool> isSyncSystemInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_syncStatusKey) != null;
    } catch (e) {
      log('Error checking sync system initialization: $e',
          name: 'background_sync');
      return false;
    }
  }

  /// Get detailed sync system status
  Future<Map<String, dynamic>> getDetailedSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = {
        'lastSyncTimestamp': prefs.getInt(_lastSyncKey),
        'syncStatus': prefs.getString(_syncStatusKey),
        'queueStats': await getSyncQueueStats(),
        'currentTime': DateTime.now().millisecondsSinceEpoch,
      };

      log('Detailed sync status: $status', name: 'background_sync');
      return status;
    } catch (e) {
      log('Error getting detailed sync status: $e', name: 'background_sync');
      return {'error': e.toString()};
    }
  }
}
