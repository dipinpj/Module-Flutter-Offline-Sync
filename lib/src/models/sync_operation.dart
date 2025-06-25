import 'package:hive/hive.dart';

part 'sync_operation.g.dart';

@HiveType(typeId: 100)
class SyncOperationModel extends HiveObject {
  @HiveField(0)
  final String type; // 'create', 'update', 'delete'

  @HiveField(1)
  final String collection;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final String? documentId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  String? syncError;

  @HiveField(6)
  final String? uniqueId;

  SyncOperationModel({
    required this.type,
    required this.collection,
    required this.data,
    this.documentId,
    DateTime? timestamp,
    this.syncError,
    this.uniqueId,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncOperationModel.fromMap(Map<String, dynamic> map) {
    return SyncOperationModel(
      type: map['type'] as String,
      collection: map['collection'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      documentId: map['documentId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      syncError: map['syncError'] as String?,
      uniqueId: map['uniqueId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'collection': collection,
      'data': data,
      'documentId': documentId,
      'timestamp': timestamp.toIso8601String(),
      'syncError': syncError,
      'uniqueId': uniqueId,
    };
  }

  /// Create a unique identifier for this operation
  String get operationId {
    return uniqueId ??
        '${collection}_${type}_${timestamp.millisecondsSinceEpoch}';
  }

  /// Check if this operation is for user management (students/teachers)
  bool get isUserOperation {
    return collection == 'students' || collection == 'teachers';
  }

  /// Check if this operation is a create operation
  bool get isCreate => type == 'create';

  /// Check if this operation is an update operation
  bool get isUpdate => type == 'update';

  /// Check if this operation is a delete operation
  bool get isDelete => type == 'delete';
}
