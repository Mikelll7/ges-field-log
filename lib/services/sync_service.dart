import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class SyncService {
  static const String _baseUrl =
      'https://6a3bdc5de4a07f202e161006.mockapi.io/sightings';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Check if device has internet - like PING in networking
  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((c) =>
        c == ConnectivityResult.mobile || c == ConnectivityResult.wifi);
  }

  // Main sync function - push all unsynced local records to API
  Future<SyncResult> syncPendingSightings() async {
    // Check connectivity first
    if (!await isConnected()) {
      return SyncResult(
        success: false,
        message: 'No internet connection. Records saved locally.',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    // Get all unsynced records from SQLite
    final unsyncedSightings = await _db.getUnsyncedSightings();

    if (unsyncedSightings.isEmpty) {
      return SyncResult(
        success: true,
        message: 'All records are already synced.',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    int syncedCount = 0;
    int failedCount = 0;

    // POST each unsynced sighting to the API
    for (final sighting in unsyncedSightings) {
      try {
        final response = await _dio.post(
          _baseUrl,
          data: sighting.toJson(),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          // Mark as synced in local DB - like UPDATE isSynced = 1
          await _db.markAsSynced(sighting.id!);
          syncedCount++;
        } else {
          failedCount++;
        }
      } catch (e) {
        failedCount++;
      }
    }

    return SyncResult(
      success: failedCount == 0,
      message: failedCount == 0
          ? 'Successfully synced $syncedCount record(s).'
          : 'Synced $syncedCount, failed $failedCount record(s).',
      syncedCount: syncedCount,
      failedCount: failedCount,
    );
  }

  // Get count of pending records to show on UI
  Future<int> getPendingCount() async {
    return await _db.getUnsyncedCount();
  }
}

// Simple result object - like a stored procedure return status
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
  });
}