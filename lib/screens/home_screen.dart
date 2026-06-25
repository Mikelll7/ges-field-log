import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sighting.dart';
import 'add_sighting_screen.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Sighting> _sightings = [];
  int _unsyncedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSightings();
  }

  // Load sightings from SQLite - like running SELECT * FROM sightings
  Future<void> _loadSightings() async {
    setState(() => _isLoading = true);
    final sightings = await DatabaseHelper.instance.getAllSightings();
    final unsyncedCount = await DatabaseHelper.instance.getUnsyncedCount();
    setState(() {
      _sightings = sightings;
      _unsyncedCount = unsyncedCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D4A32),
        title: const Text(
          'GES Field Log',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Sync badge button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SyncScreen()),
                  );
                  _loadSightings();
                },
              ),
              if (_unsyncedCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unsyncedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _sightings.isEmpty
              ? _buildEmptyState()
              : _buildSightingsList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSightingScreen()),
          );
          _loadSightings();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Log Sighting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.green.shade700),
          const SizedBox(height: 16),
          const Text(
            'No sightings logged yet',
            style: TextStyle(
                color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Log Sighting" to record your first observation',
            style: TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSightingsList() {
    return RefreshIndicator(
      onRefresh: _loadSightings,
      color: const Color(0xFF4CAF50),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sightings.length,
        itemBuilder: (context, index) {
          final sighting = _sightings[index];
          return _buildSightingCard(sighting);
        },
      ),
    );
  }

  Widget _buildSightingCard(Sighting sighting) {
    return Card(
      color: const Color(0xFF2D4A32),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Species icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2B1F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pets, color: Color(0xFF4CAF50), size: 28),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sighting.species,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Sync status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sighting.isSynced
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sighting.isSynced ? 'Synced' : 'Pending',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Count: ${sighting.animalCount}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📍 ${sighting.latitude.toStringAsFixed(4)}, ${sighting.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (sighting.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      sighting.notes,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(sighting.createdAt),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}