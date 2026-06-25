import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';
import '../models/sighting.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _syncService = SyncService();
  List<Sighting> _unsyncedSightings = [];
  bool _isSyncing = false;
  bool _isLoading = true;
  String? _resultMessage;
  bool? _syncSuccess;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedSightings();
  }

  Future<void> _loadUnsyncedSightings() async {
    setState(() => _isLoading = true);
    final sightings = await DatabaseHelper.instance.getUnsyncedSightings();
    setState(() {
      _unsyncedSightings = sightings;
      _isLoading = false;
    });
  }

  Future<void> _runSync() async {
    setState(() {
      _isSyncing = true;
      _resultMessage = null;
      _syncSuccess = null;
    });

    final result = await _syncService.syncPendingSightings();

    setState(() {
      _isSyncing = false;
      _resultMessage = result.message;
      _syncSuccess = result.success;
    });

    // Reload the unsynced list after sync
    await _loadUnsyncedSightings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D4A32),
        title: const Text(
          'Sync Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _buildStatusCard(),

                  const SizedBox(height: 20),

                  // Result message
                  if (_resultMessage != null) _buildResultBanner(),

                  const SizedBox(height: 20),

                  // Pending records list
                  if (_unsyncedSightings.isNotEmpty) ...[
                    const Text(
                      'Pending Records',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _unsyncedSightings.length,
                        itemBuilder: (context, index) {
                          final s = _unsyncedSightings[index];
                          return Card(
                            color: const Color(0xFF2D4A32),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.pets,
                                  color: Color(0xFF4CAF50)),
                              title: Text(
                                s.species,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Count: ${s.animalCount} • ${_formatDate(s.createdAt)}',
                                style:
                                    const TextStyle(color: Colors.white54),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade800,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done,
                                size: 80, color: Colors.green.shade700),
                            const SizedBox(height: 16),
                            const Text(
                              'All records synced!',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Sync button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSyncing || _unsyncedSightings.isEmpty
                          ? null
                          : _runSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload, color: Colors.white),
                      label: Text(
                        _isSyncing
                            ? 'Syncing...'
                            : 'Sync ${_unsyncedSightings.length} Record(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D4A32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2B1F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _unsyncedSightings.isEmpty
                  ? Icons.cloud_done
                  : Icons.cloud_upload,
              color: _unsyncedSightings.isEmpty
                  ? Colors.green
                  : Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_unsyncedSightings.length} record(s) pending',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Connect to WiFi or mobile data to sync',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _syncSuccess! ? Colors.green.shade900 : Colors.red.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _syncSuccess! ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _syncSuccess! ? Icons.check_circle : Icons.error,
            color: _syncSuccess! ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _resultMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}