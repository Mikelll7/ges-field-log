import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/sighting.dart';

class AddSightingScreen extends StatefulWidget {
  const AddSightingScreen({super.key});

  @override
  State<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends State<AddSightingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _photoPath;
  bool _isGettingLocation = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _speciesController.dispose();
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Get GPS coordinates - like querying a location service
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled. Please enable GPS.');
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permissions permanently denied.');
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });
    } catch (e) {
      _showSnack('Failed to get location: $e');
      setState(() => _isGettingLocation = false);
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (photo != null) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      _showSnack('Failed to take photo: $e');
    }
  }

  // Pick photo from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (photo != null) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      _showSnack('Failed to pick photo: $e');
    }
  }

  // Save sighting to local SQLite database
  Future<void> _saveSighting() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      _showSnack('Please capture GPS coordinates before saving.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sighting = Sighting(
        localId: _uuid.v4(),
        species: _speciesController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        animalCount: int.parse(_countController.text.trim()),
        photoPath: _photoPath,
        notes: _notesController.text.trim(),
        isSynced: false,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insertSighting(sighting);

      if (mounted) {
        _showSnack('Sighting saved locally!');
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to save sighting: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2D4A32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D4A32),
        title: const Text(
          'Log Sighting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Species field
              _buildLabel('Species Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _speciesController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. African Elephant'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Species name is required' : null,
              ),

              const SizedBox(height: 16),

              // Animal count field
              _buildLabel('Animal Count *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _countController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Number of animals observed'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Count is required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Enter a valid count';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // GPS Section
              _buildLabel('GPS Coordinates *'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D4A32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _latitude == null
                          ? const Text(
                              'No coordinates captured yet',
                              style: TextStyle(color: Colors.white54),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${_latitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Lng: ${_longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      onPressed: _isGettingLocation ? null : _getLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.gps_fixed, color: Colors.white),
                      label: Text(
                        _isGettingLocation ? 'Getting...' : 'Capture GPS',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Photo Section
              _buildLabel('Photo (Optional)'),
              const SizedBox(height: 6),
              _photoPath != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_photoPath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _photoPath = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt,
                                color: Color(0xFF4CAF50)),
                            label: const Text('Camera',
                                style: TextStyle(color: Color(0xFF4CAF50))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library,
                                color: Color(0xFF4CAF50)),
                            label: const Text('Gallery',
                                style: TextStyle(color: Color(0xFF4CAF50))),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 16),

              // Notes field
              _buildLabel('Notes / Observations'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDecoration(
                    'Describe behaviour, condition, habitat...'),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveSighting,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Sighting',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2D4A32),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}