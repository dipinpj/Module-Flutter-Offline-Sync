import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sync Package Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SyncExamplePage(),
    );
  }
}

class SyncExamplePage extends StatefulWidget {
  @override
  _SyncExamplePageState createState() => _SyncExamplePageState();
}

class _SyncExamplePageState extends State<SyncExamplePage> {
  final FirestoreHelper _firestoreHelper = FirestoreHelper(
    projectId: 'your-project-id',
    apiKey: 'your-api-key',
  );

  final HiveHelper _hiveHelper = HiveHelper();

  String _syncStatus = 'Unknown';
  Map<String, int> _queueStats = {};

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await BackgroundTaskHandler.getSyncStatus();
      final stats = await BackgroundTaskHandler.getSyncQueueStats();

      setState(() {
        _syncStatus = status;
        _queueStats = stats;
      });
    } catch (e) {
      print('Error loading sync status: $e');
    }
  }

  Future<void> _addSampleData() async {
    try {
      // Create a sample student
      final student = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'type': 'create',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _hiveHelper.addItem('students', student);

      showSnackBarMessage(context, 'Sample data added to sync queue');
      _loadSyncStatus();
    } catch (e) {
      showSnackBarMessage(context, 'Error adding sample data: $e');
    }
  }

  Future<void> _triggerManualSync() async {
    try {
      await BackgroundTaskHandler.registerOneTimeSync();
      showSnackBarMessage(context, 'Manual sync triggered');
      _loadSyncStatus();
    } catch (e) {
      showSnackBarMessage(context, 'Error triggering sync: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Sync Package Example'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text('Status: $_syncStatus'),
                    SizedBox(height: 8),
                    Text('Queue Stats:'),
                    ...(_queueStats.entries.map((entry) =>
                        Text('  ${entry.key}: ${entry.value} items'))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addSampleData,
                    child: Text('Add Sample Data'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _triggerManualSync,
                    child: Text('Trigger Manual Sync'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSyncStatus,
              child: Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
