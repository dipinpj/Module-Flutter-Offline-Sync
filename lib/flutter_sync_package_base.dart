/// Base class for sync operations
abstract class SyncOperation {
  final String type; // 'create', 'update', 'delete'
  final String collection;
  final Map<String, dynamic> data;
  final String? documentId;
  final DateTime timestamp;

  SyncOperation({
    required this.type,
    required this.collection,
    required this.data,
    this.documentId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'collection': collection,
      'data': data,
      'documentId': documentId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperationImpl(
      type: map['type'] as String,
      collection: map['collection'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      documentId: map['documentId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// Implementation of SyncOperation
class SyncOperationImpl extends SyncOperation {
  SyncOperationImpl({
    required super.type,
    required super.collection,
    required super.data,
    super.documentId,
    super.timestamp,
  });
}

/// Base class for sync managers
abstract class SyncManager {
  /// Initialize the sync system
  Future<void> initialize();

  /// Add an operation to the sync queue
  Future<void> addOperation(SyncOperation operation);

  /// Process all pending operations
  Future<void> processPendingOperations();

  /// Get sync status
  Future<SyncStatus> getSyncStatus();
}

/// Sync status information
class SyncStatus {
  final bool isOnline;
  final int pendingOperations;
  final DateTime? lastSyncTime;
  final String status; // 'idle', 'syncing', 'error'

  SyncStatus({
    required this.isOnline,
    required this.pendingOperations,
    this.lastSyncTime,
    required this.status,
  });
}

/// Configuration for the sync package
class SyncConfig {
  final String firebaseProjectId;
  final String firebaseApiKey;
  final Duration syncInterval;
  final bool enableBackgroundSync;
  final List<String> collections;

  const SyncConfig({
    required this.firebaseProjectId,
    required this.firebaseApiKey,
    this.syncInterval = const Duration(minutes: 15),
    this.enableBackgroundSync = true,
    this.collections = const [],
  });
}

/// Main sync package class
class FlutterSyncPackage {
  static SyncManager? _instance;
  static SyncConfig? _config;

  /// Initialize the sync package
  static Future<void> initialize(SyncConfig config) async {
    _config = config;
    // Implementation will be added when we create the actual manager
  }

  /// Get the sync manager instance
  static SyncManager get instance {
    if (_instance == null) {
      throw StateError(
          'FlutterSyncPackage not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Get the current configuration
  static SyncConfig get config {
    if (_config == null) {
      throw StateError(
          'FlutterSyncPackage not initialized. Call initialize() first.');
    }
    return _config!;
  }
}
