class Sighting {
  final int? id;
  final String localId;
  final String species;
  final double latitude;
  final double longitude;
  final int animalCount;
  final String? photoPath;
  final String notes;
  final bool isSynced;
  final DateTime createdAt;

  Sighting({
    this.id,
    required this.localId,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.animalCount,
    this.photoPath,
    required this.notes,
    this.isSynced = false,
    required this.createdAt,
  });

  // Convert to Map for SQLite storage (like INSERT into a SQL table)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localId': localId,
      'species': species,
      'latitude': latitude,
      'longitude': longitude,
      'animalCount': animalCount,
      'photoPath': photoPath,
      'notes': notes,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert to JSON for API sync (POST to MockAPI)
  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'species': species,
      'latitude': latitude,
      'longitude': longitude,
      'animalCount': animalCount,
      'photoPath': photoPath ?? '',
      'notes': notes,
      'syncedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create Sighting from SQLite row (like reading a SELECT result)
  factory Sighting.fromMap(Map<String, dynamic> map) {
    return Sighting(
      id: map['id'],
      localId: map['localId'],
      species: map['species'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      animalCount: map['animalCount'],
      photoPath: map['photoPath'],
      notes: map['notes'],
      isSynced: map['isSynced'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Copy with updated fields (immutable update pattern)
  Sighting copyWith({bool? isSynced}) {
    return Sighting(
      id: id,
      localId: localId,
      species: species,
      latitude: latitude,
      longitude: longitude,
      animalCount: animalCount,
      photoPath: photoPath,
      notes: notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
    );
  }
}