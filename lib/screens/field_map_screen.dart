// lib/screens/field_map_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

/// Field model
class Field {
  String id;
  String name;
  List<LatLng> polygon;
  Color color;
  List<String> history;
  Uint8List? droneImageBytes;
  File? droneImageFile;

  Field({
    required this.id,
    required this.name,
    required this.polygon,
    required this.color,
    List<String>? history,
    this.droneImageBytes,
    this.droneImageFile,
  }) : history = history ?? [];
}

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({Key? key}) : super(key: key);

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  final MapController _mapController = MapController();
  final List<Field> _fields = [];
  bool _isAdding = false;
  final List<LatLng> _currentVertices = [];
  Field? _selectedField;

  // map fieldId -> file:// template path
  final Map<String, String> _localTileTemplates = {};

  // Location tracking
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isFollowing = false;

  // Download cancellation
  bool _cancelDownload = false;

  // Satellite / zoom controls
  bool _useSatellite = false;
  double _currentZoomLevel = 15.0;
  // ESRI World Imagery (no API key required for basic use)
  final String _esriSatelliteTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  // Mapbox (uncomment to use and set token)
  // final String _mapboxToken = '<YOUR_MAPBOX_TOKEN>';
  // final String _mapboxSatelliteTemplate =
  //     'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxToken';

  @override
  void initState() {
    super.initState();
    _addDemoField();
    _initLocalTemplatesForExistingFields();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  void _addDemoField() {
    final demo = Field(
      id: 'field_demo_a',
      name: 'Demo Field A',
      polygon: [
        LatLng(19.075983, 72.877655),
        LatLng(19.076983, 72.879655),
        LatLng(19.074983, 72.880655),
      ],
      color: const Color.fromRGBO(34, 197, 94, 0.45),
      history: [
        'Created on ${DateTime.now().subtract(const Duration(days: 3)).toLocal().toString().split('.')[0]}'
      ],
    );
    _fields.add(demo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToField(demo));
  }

  Future<void> _initLocalTemplatesForExistingFields() async {
    if (kIsWeb) return;
    for (final f in _fields) {
      final tpl = await _computeLocalTemplateIfExists(f.id);
      if (tpl != null) {
        if (!mounted) return;
        setState(() => _localTileTemplates[f.id] = tpl);
      }
    }
  }

  void _toggleAddMode() {
    setState(() {
      _isAdding = !_isAdding;
      if (!_isAdding) _currentVertices.clear();
    });
  }

  void _onMapTap(TapPosition tap, LatLng latlng) {
    if (!_isAdding) {
      final tapped = _findFieldAtTap(latlng);
      if (tapped != null) {
        _showFieldDetails(tapped);
      }
      return;
    }
    setState(() => _currentVertices.add(latlng));
  }

  Field? _findFieldAtTap(LatLng tap) {
    for (final field in _fields) {
      if (_pointInPolygon(tap, field.polygon)) return field;
    }
    return null;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> poly) {
    final int n = poly.length;
    if (n < 3) return false;
    var inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final latI = poly[i].latitude;
      final lngI = poly[i].longitude;
      final latJ = poly[j].latitude;
      final lngJ = poly[j].longitude;

      final intersect = ((latI > point.latitude) != (latJ > point.latitude)) &&
          (point.longitude <
              (lngJ - lngI) * (point.latitude - latI) / (latJ - latI) +
                  lngI);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Future<void> _finishPolygon() async {
    if (_currentVertices.length < 3) {
      _showSnack('Draw at least 3 points to make a field.');
      return;
    }

    final nameController = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your field'),
        content: TextField(
            controller: nameController,
            decoration:
                const InputDecoration(hintText: 'e.g. North Wheat Plot')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (name == null || name.isEmpty) {
      _showSnack('Field not saved — name is required.');
      return;
    }

    final newField = Field(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      polygon: List.of(_currentVertices),
      color: _pickColorForNewField(),
      history: ['Created on ${DateTime.now().toLocal().toString().split('.')[0]}'],
    );

    setState(() {
      _fields.add(newField);
      _isAdding = false;
      _currentVertices.clear();
      _selectedField = newField;
    });

    _zoomToField(newField);
    _showSnack('Field "$name" added');
  }

  Color _pickColorForNewField() {
    final colors = [
      const Color.fromRGBO(34, 197, 94, 0.45),
      const Color.fromRGBO(249, 115, 22, 0.45),
      const Color.fromRGBO(59, 130, 246, 0.45),
      const Color.fromRGBO(139, 92, 246, 0.45),
      const Color.fromRGBO(239, 68, 68, 0.45),
    ];
    return colors[_fields.length % colors.length];
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // -----------------------------
  // Upload / attach drone map (improved: compress + store as temp file)
  // -----------------------------
  Future<void> _uploadDroneMap(Field field) async {
    // request storage permission for mobile devices
    if (!kIsWeb) {
      final p = await Permission.storage.request();
      if (!p.isGranted) {
        _showSnack('Storage permission required to attach drone map.');
        return;
      }
    }

    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    try {
      Uint8List? bytes = picked.bytes;
      String? path = picked.path;

      // prefer compressing from file path where possible (more efficient)
      if (!kIsWeb && path != null) {
        // compress and write to temp file
        final tmpDir = await getTemporaryDirectory();
        final outPath =
            '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}_drone.jpg';

        final compressedBytes = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: 1600,
          minHeight: 900,
          quality: 70,
        );

        if (compressedBytes != null) {
          final outFile = File(outPath);
          await outFile.writeAsBytes(compressedBytes, flush: true);
          setState(() {
            field.droneImageFile = outFile;
            field.droneImageBytes = null; // keep file instead of memory bytes
            field.history.add(
                'Drone image attached (compressed) on ${DateTime.now().toLocal().toString().split('.')[0]}');
          });
        } else {
          // fallback: if compress returns null, copy original path to temp
          final outFile = File(outPath);
          await outFile.writeAsBytes(await File(path).readAsBytes(), flush: true);
          setState(() {
            field.droneImageFile = outFile;
            field.droneImageBytes = null;
            field.history.add(
                'Drone image attached (copied) on ${DateTime.now().toLocal().toString().split('.')[0]}');
          });
        }
      } else {
        // Web or no file path: compress from bytes if available
        if (bytes != null) {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1600,
            minHeight: 900,
            quality: 70,
          );
          setState(() {
            field.droneImageBytes = Uint8List.fromList(compressedBytes);
            field.history.add(
                'Drone image attached (compressed) on ${DateTime.now().toLocal().toString().split('.')[0]}');
          });
        } else {
          _showSnack('No image data available to attach');
          return;
        }
      }

      if (mounted) Navigator.pop(context);
      _showSnack('Drone map attached to ${field.name}');
    } catch (e) {
      _showSnack('Failed to attach drone image: $e');
    }
  }

  Future<void> _renameField(Field field) async {
    final controller = TextEditingController(text: field.name);
    final newName = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename field'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        field.name = newName;
        field.history.add('Renamed to "$newName" on ${DateTime.now().toLocal().toString().split('.')[0]}');
      });
      _showSnack('Field renamed');
    }
  }

  void _showFieldDetails(Field field) {
    setState(() => _selectedField = field);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.78,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text(field.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(onPressed: () => _renameField(field), icon: const Icon(Icons.edit), label: const Text('Rename')),
              ElevatedButton.icon(onPressed: () => _uploadDroneMap(field), icon: const Icon(Icons.cloud_upload), label: const Text('Upload Drone Map')),
              ElevatedButton.icon(onPressed: () => _showHistory(field), icon: const Icon(Icons.history), label: const Text('History')),
              ElevatedButton.icon(
                onPressed: kIsWeb ? () => _showSnack('Tile download not supported on Web') : () => _pickZipAndExtract(field),
                icon: const Icon(Icons.download),
                label: const Text('Load Tiles (from device)'),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('Quick info', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Vertices: ${field.polygon.length}'),
            const SizedBox(height: 8),
            Expanded(
  child: ListView(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    children: [
      if (field.droneImageBytes != null || (field.droneImageFile != null && !kIsWeb)) ...[
        const Text('Drone Map', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildImagePreview(field),
        const SizedBox(height: 12),
      ],

      const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      // Spread the iterable directly (no .toList())
      ...field.history.reversed.map(
        (h) => ListTile(
          title: Text(h, style: const TextStyle(fontSize: 14)),
        ),
      ),

      const SizedBox(height: 10),

      if (!kIsWeb)
        FutureBuilder<String?>(
          future: _computeLocalTemplateIfExists(field.id),
          builder: (context, snap) {
            final exists = snap.connectionState == ConnectionState.done && snap.data != null;

            // update local cache once after build if needed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final hasLocal = _localTileTemplates.containsKey(field.id);
              if (exists && !hasLocal) {
                setState(() => _localTileTemplates[field.id] = snap.data!);
              } else if (!exists && hasLocal) {
                setState(() => _localTileTemplates.remove(field.id));
              }
            });

            return ListTile(
              leading: Icon(exists ? Icons.check_circle : Icons.cloud_download),
              title: Text(exists ? 'Offline tiles ready' : 'Offline tiles not downloaded'),
              subtitle: exists ? const Text('Tap map to view offline overlay') : const Text('Load tiles from device storage'),
              trailing: exists
                  ? TextButton(onPressed: () => _deleteLocalTiles(field.id), child: const Text('Delete'))
                  : null,
            );
          },
        ),

      if (kIsWeb)
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Offline Tiles'),
          subtitle: Text('Not supported on web platform.'),
        ),
    ],
  ),
), 

          ]),
        ),
      ),
    ).whenComplete(() => setState(() => _selectedField = null));
  }

  Widget _buildImagePreview(Field field) {
    if (field.droneImageBytes != null) return Image.memory(field.droneImageBytes!, fit: BoxFit.contain, height: 200);
    if (!kIsWeb && field.droneImageFile != null && field.droneImageFile!.existsSync()) return Image.file(field.droneImageFile!, fit: BoxFit.contain, height: 200);
    return const Text('No drone map available');
  }

 void _showHistory(Field field) {
  Navigator.pop(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Field History'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          children: field.history.reversed
              .map((h) => ListTile(
                    title: Text(h, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}


  // -----------------------------
  // Offline tile helpers
  // -----------------------------
  Future<Directory> _getTilesFolderForField(String fieldId) async {
    if (kIsWeb) throw UnsupportedError('File system operations are not supported on web.');
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/tiles/$fieldId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _computeLocalTemplateIfExists(String fieldId) async {
    if (kIsWeb) return null;
    try {
      final folder = await _getTilesFolderForField(fieldId);
      bool hasTile = false;

      await for (final e in folder.list(recursive: true)) {
        if (e is File && e.path.endsWith('.png')) {
          final rel = e.path.replaceFirst('${folder.path}/', '');
          if (RegExp(r'^\d+/\d+/\d+\.png$').hasMatch(rel)) {
            hasTile = true;
            break;
          }
        }
      }

      if (!hasTile) return null;

      final prefix = Uri.file('${folder.path}/').toString();
      return '$prefix{z}/{x}/{y}.png';
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteLocalTiles(String fieldId) async {
    if (kIsWeb) return;
    try {
      final folder = await _getTilesFolderForField(fieldId);
      if (await folder.exists()) await folder.delete(recursive: true);
      if (!mounted) return;
      setState(() => _localTileTemplates.remove(fieldId));
      _showSnack('Deleted offline tiles for $fieldId');
    } catch (e) {
      _showSnack('Failed to delete tiles: $e');
    }
  }

  Future<void> _pickZipAndExtract(Field field) async {
    if (kIsWeb) {
      _showSnack('Pick from device not supported on Web in this demo.');
      return;
    }

    // request storage permission
    final p = await Permission.storage.request();
    if (!p.isGranted) {
      _showSnack('Storage permission required to load tiles.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip'], withData: false);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final path = picked.path;
    if (path == null) {
      _showSnack('Unable to get file path for selected ZIP.');
      return;
    }

    try {
      await _extractZipFromPath(path, field.id);
      final tpl = await _computeLocalTemplateIfExists(field.id);
      if (tpl != null && mounted) setState(() => _localTileTemplates[field.id] = tpl);
      _showSnack('Tiles loaded for ${field.name}');
    } catch (e) {
      _showSnack('Failed to extract tiles: $e');
    }
  }

  Future<void> _extractZipFromPath(String zipPath, String fieldId) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) throw 'Zip file not found';
    final fileSize = await zipFile.length();
    const maxAllowed = 200 * 1024 * 1024; // 200MB
    if (fileSize > maxAllowed) {
      throw 'Zip file too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). Use a smaller tile package.';
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final targetDir = await _getTilesFolderForField(fieldId);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final out = File('${targetDir.path}/$filename');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content as Uint8List);
      } else {
        final dir = Directory('${targetDir.path}/$filename');
        if (!await dir.exists()) await dir.create(recursive: true);
      }
    }
  }

  // -----------------------------
  // Download-from-URL helper (cancelable)
  // -----------------------------
  Future<void> _downloadAndExtractTiles(String url, String fieldId, {void Function(double)? onProgress}) async {
    if (kIsWeb) throw UnsupportedError('Not supported on web.');
    _cancelDownload = false;
    final tmpDir = await getTemporaryDirectory();
    final tmpZip = File('${tmpDir.path}/tiles_$fieldId.zip');

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final streamed = await client.send(req);
      final contentLength = streamed.contentLength ?? 0;
      final sink = tmpZip.openWrite();
      int received = 0;
      await for (final chunk in streamed.stream) {
        if (_cancelDownload) {
          await sink.close();
          if (await tmpZip.exists()) await tmpZip.delete();
          client.close();
          _showSnack('Download cancelled');
          return;
        }
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0 && onProgress != null) onProgress(received / contentLength);
      }
      await sink.close();
      client.close();

      final bytes = await tmpZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final targetDir = await _getTilesFolderForField(fieldId);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final out = File('${targetDir.path}/$filename');
          await out.parent.create(recursive: true);
          await out.writeAsBytes(file.content as Uint8List);
        } else {
          final dir = Directory('${targetDir.path}/$filename');
          if (!await dir.exists()) await dir.create(recursive: true);
        }
      }
      if (await tmpZip.exists()) await tmpZip.delete();
      final tpl = await _computeLocalTemplateIfExists(fieldId);
      if (tpl != null && mounted) setState(() => _localTileTemplates[fieldId] = tpl);
    } finally {
      client.close();
    }
  }

  void cancelDownload() {
    _cancelDownload = true;
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location permission required'),
          content: const Text('Please enable location permission in app settings to use this feature.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      return false;
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<void> _centerOnUserOnce({double zoom = 17}) async {
    final ok = await _ensureLocationPermission();
    if (!ok) return;
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _currentPosition = pos;
      if (!mounted) return;
      setState(() {});
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentZoomLevel = zoom;
      _mapController.move(latLng, zoom);
      _showSnack('Centered to your location');
    } catch (e) {
      _showSnack('Failed to get location: $e');
    }
  }

  void _startFollowing() async {
    final ok = await _ensureLocationPermission();
    if (!ok) return;
    if (_isFollowing) return;
    final locationSettings = const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
      _currentPosition = pos;
      if (!mounted) return;
      setState(() {});
      if (_isFollowing) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        _mapController.move(latLng, _mapController.zoom);
      }
    });
    setState(() => _isFollowing = true);
    _showSnack('Follow mode enabled');
  }

  void _stopFollowing() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    setState(() => _isFollowing = false);
    _showSnack('Follow mode disabled');
  }

  // -----------------------------
  // Zoom to field helper (uses fitCamera if available)
  // -----------------------------
  void _zoomToField(Field field) {
    if (field.polygon.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(field.polygon);
    try {
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60), maxZoom: 20));
    } catch (_) {
      // fallback
      final center = bounds.center;
      _mapController.move(center, _currentZoomLevel);
    }
  }

  Future<String?> _getAnyLocalTemplateForMap() async {
    if (kIsWeb) return null;
    for (final f in _fields) {
      if (_localTileTemplates.containsKey(f.id)) return _localTileTemplates[f.id];
      final tpl = await _computeLocalTemplateIfExists(f.id);
      if (tpl != null) {
        if (!mounted) return null;
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _localTileTemplates[f.id] = tpl));
        return tpl;
      }
    }
    return null;
  }

  // -----------------------------
  // Build UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FutureBuilder<String?>(
          future: _getAnyLocalTemplateForMap(),
          builder: (context, snapshot) {
            final anyTemplate = snapshot.data;

            // choose base tile template: if satellite is toggled use satellite provider
            final baseTemplate = _useSatellite ? _esriSatelliteTemplate : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
            final baseSubdomains = _useSatellite ? <String>[] : ['a', 'b', 'c'];

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(19.075983, 72.877655),
                initialZoom: _currentZoomLevel,
                minZoom: 1,
                // increase maxZoom to allow deeper zooming (subject to provider limit)
                maxZoom: 22,
                onTap: _onMapTap,
              ),
              children: [
                // Base tile layer (OSM or Satellite)
                TileLayer(
                  urlTemplate: baseTemplate,
                  subdomains: baseSubdomains,
                  userAgentPackageName: 'com.example.field_map_app',
                  // Set provider native zoom if you know it. ESRI often provides up to ~19.
                  maxNativeZoom: 19,
                  maxZoom: 22,
                ),

                // Local offline overlay: prefer selected field template, otherwise any available template
                if (_selectedField != null && _localTileTemplates.containsKey(_selectedField!.id))
                  TileLayer(urlTemplate: _localTileTemplates[_selectedField!.id]!)
                else if (anyTemplate != null)
                  Opacity(opacity: 0.95, child: TileLayer(urlTemplate: anyTemplate)),

                // Field polygons
                PolygonLayer(
                  polygons: [
                    ..._fields.map((f) => Polygon(
                          points: f.polygon,
                          color: f.color,
                          borderColor: const Color.fromRGBO(0, 0, 0, 0.35),
                          borderStrokeWidth: 2,
                          isFilled: true,
                        )),
                    if (_isAdding && _currentVertices.isNotEmpty)
                      Polygon(
                        points: _currentVertices,
                        color: const Color.fromRGBO(250, 204, 21, 0.35),
                        borderColor: const Color.fromRGBO(250, 204, 21, 0.9),
                        borderStrokeWidth: 2,
                        isFilled: true,
                      ),
                  ],
                  polygonCulling: true,
                ),

                // Vertex markers shown during drawing (MarkerLayer expects a List<Marker>)
               // Vertex markers while drawing a field
if (_isAdding)
  MarkerLayer(
    markers: _currentVertices
        .map(
          (pt) => Marker(
            point: pt,
            width: 30,
            height: 30,
            child: const Icon(
              Icons.location_on,
              size: 30,
              color: Colors.orange,
            ),
          ),
        )
        .toList(),
  ),

// User location marker
if (_currentPosition != null)
  MarkerLayer(
    markers: [
      Marker(
        point: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        width: 40,
        height: 40,
        child: Icon(
          _isFollowing ? Icons.my_location : Icons.location_on,
          size: 36,
          color: _isFollowing ? Colors.lightBlueAccent : Colors.blueAccent,
        ),
      ),
    ],
  ),

              ],
            );
          },
        ),

        // Top helper
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color.fromARGB(230, 70, 69, 69), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isAdding ? 'Add Field: Tap on map to place corners' : 'Tap a field to view details', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Use the big buttons at the bottom to add fields or manage them.', style: TextStyle(color: Colors.white70)),
            ]),
          ),
        ),

        // Satellite toggle + zoom slider (top-right)
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.satellite, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text('Satellite', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: _useSatellite,
                        onChanged: (v) {
                          setState(() => _useSatellite = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.black87,
                child: SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      Slider(
                        value: _currentZoomLevel,
                        min: 1,
                        max: 22,
                        divisions: 21,
                        label: _currentZoomLevel.toStringAsFixed(1),
                        onChanged: (v) {
                          setState(() {
                            _currentZoomLevel = v;
                            try {
                              _mapController.move(_mapController.center, _currentZoomLevel);
                            } catch (_) {}
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text('Zoom ${_currentZoomLevel.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right-side location FABs (center + follow)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              FloatingActionButton(heroTag: 'center_btn', mini: true, onPressed: () => _centerOnUserOnce(), child: const Icon(Icons.my_location)),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'follow_btn',
                mini: true,
                backgroundColor: _isFollowing ? Colors.lightBlueAccent : null,
                onPressed: () => _isFollowing ? _stopFollowing() : _startFollowing(),
                child: Icon(_isFollowing ? Icons.location_disabled : Icons.location_searching),
              ),
            ],
          ),
        ),

        // Bottom action bar
        Positioned(
          left: 12,
          right: 12,
          bottom: 18,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _toggleAddMode,
              icon: Icon(_isAdding ? Icons.clear : Icons.add_location_alt, size: 22),
              label: Text(_isAdding ? 'Cancel' : 'Add Field', style: const TextStyle(fontSize: 16)),
            ),
            if (_isAdding)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _finishPolygon,
                icon: const Icon(Icons.check, size: 22),
                label: const Text('Finish Field', style: TextStyle(fontSize: 16)),
              ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _showFieldList,
              icon: const Icon(Icons.my_location, size: 22),
              label: const Text('My Fields', style: TextStyle(fontSize: 16)),
            ),
          ]),
        ),

        // Attribution footer (provider info)
        Positioned(
          left: 12,
          right: 12,
          bottom: 84,
          child: SafeArea(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _useSatellite ? 'Imagery: ESRI World Imagery' : 'Tiles: OpenStreetMap',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showFieldList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), alignment: Alignment.centerLeft, child: const Text('My Fields', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _fields.length,
            itemBuilder: (context, index) {
              final f = _fields[index];
              final initial = (f.name.isNotEmpty) ? f.name[0] : '?';
              return ListTile(
                leading: CircleAvatar(backgroundColor: f.color.withAlpha(255), child: Text(initial)),
                title: Text(f.name),
                subtitle: Text('${f.polygon.length} corners'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _zoomToField(f);
                  },
                  child: const Text('View'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showFieldDetails(f);
                },
              );
            },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
