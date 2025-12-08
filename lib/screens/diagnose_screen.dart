// lib/screens/diagnose_screen.dart
// Diagnose screen — picks/takes photo, uploads to your model API (/api/predict),
// displays prediction result and history. Uses ApiConfig.baseUrl if available.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:easy_localization/easy_localization.dart';
import '../api_config.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  // pickers
  final ImagePicker _picker = ImagePicker();

  // picked data
  File? _lastPickedFile;
  Uint8List? _lastPickedBytes;
  String? _lastPickedFileName;

  // UI state
  bool _isUploading = false;
  String? _predictionLabel;
  double? _predictionConfidence;
  String? _predictionImageUrl; // server saved image URL (may be null)
  String? _error;

  // history from server (optional)
  List<Map<String, dynamic>> _history = [];

  // API endpoints (use ApiConfig.baseUrl if available)
  late final String API_BASE;
  late final String API_PREDICT;
  late final String API_HISTORY;

  static const double _cardRadius = 18.0;

  @override
  void initState() {
    super.initState();
    final base = (ApiConfig.baseUrl != null && ApiConfig.baseUrl!.isNotEmpty)
        ? ApiConfig.baseUrl!
        : 'http://localhost:5000';
    API_BASE = base;
    API_PREDICT = '$API_BASE/api/predict';
    API_HISTORY = '$API_BASE/api/history';

    _loadHistory();
  }

  // ---------------- IMAGE PICK + PREVIEW ----------------

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;

    setState(() {
      _lastPickedFile = null;
      _lastPickedBytes = null;
      _lastPickedFileName = null;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final picked = result.files.single;
        if (picked.bytes == null) throw Exception('Failed to read picked file bytes.');
        setState(() {
          _lastPickedBytes = picked.bytes;
          _lastPickedFileName = picked.name;
        });
      } else {
        final XFile? xfile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (xfile == null) return;
        setState(() {
          _lastPickedFile = File(xfile.path);
          _lastPickedFileName = xfile.name;
        });
      }

      if (!mounted) return;
      if (_lastPickedFile != null || _lastPickedBytes != null) {
        _showUploadConfirmationDialog();
      }
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = tr('failed_pick_image', args: [e.toString()]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('failed_pick_image', args: [e.toString()])), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  // ---------- Confirmation dialog ----------
  void _showUploadConfirmationDialog() {
    final theme = Theme.of(context);
    final Widget previewWidget;
    if (_lastPickedFile != null) {
      previewWidget = Image.file(_lastPickedFile!, fit: BoxFit.cover, height: 220);
    } else if (_lastPickedBytes != null) {
      previewWidget = Image.memory(_lastPickedBytes!, fit: BoxFit.cover, height: 220);
    } else {
      previewWidget = const SizedBox(height: 220);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(child: Text(tr('confirm_photo'), style: theme.textTheme.titleLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: previewWidget),
            const SizedBox(height: 12),
            Text(tr('confirm_photo_question'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _lastPickedFile = null;
                _lastPickedBytes = null;
                _lastPickedFileName = null;
              });
            },
            child: Text(tr('retake')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startUploadProcess();
            },
            child: Text(tr('diagnose_button')),
          ),
        ],
      ),
    );
  }

  // ---------- Upload to Flask API ----------
  Future<void> _startUploadProcess() async {
    if (_isUploading) return;
    if (_lastPickedFile == null && _lastPickedBytes == null) {
      setState(() => _error = tr('no_image_selected'));
      return;
    }

    setState(() {
      _isUploading = true;
      _predictionLabel = null;
      _predictionConfidence = null;
      _predictionImageUrl = null;
      _error = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('uploading_diagnosis')), duration: const Duration(seconds: 2)),
    );

    try {
      final uri = Uri.parse(API_PREDICT);
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        final bytes = _lastPickedBytes!;
        final filename = _lastPickedFileName ?? 'upload.jpg';
        final mimeType = _getMimeTypeFromFilename(filename) ?? 'image/jpeg';
        final mimeParts = mimeType.split('/');
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
            contentType: MediaType(mimeParts.first, mimeParts.last),
          ),
        );
      } else {
        final file = _lastPickedFile!;
        final filename = _lastPickedFileName ?? file.path.split(Platform.pathSeparator).last;
        request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: filename));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200) {
        String details = resp.body;
        try {
          final j = json.decode(resp.body);
          details = j['error'] ?? j['details'] ?? resp.body;
        } catch (_) {}
        throw Exception('Server responded ${resp.statusCode}: $details');
      }

      final Map<String, dynamic> jsonBody = json.decode(resp.body) as Map<String, dynamic>;
      final result = jsonBody['result'] as String? ?? jsonBody['prediction'] as String?;
      final confidence = (jsonBody['confidence'] is num) ? (jsonBody['confidence'] as num).toDouble() : (jsonBody['confidence'] is String ? double.tryParse(jsonBody['confidence']) : null);
      final imageUrl = jsonBody['image_url'] ?? jsonBody['image'] ?? jsonBody['file_url'] ?? jsonBody['filename'];

      setState(() {
        _predictionLabel = result ?? tr('unknown');
        _predictionConfidence = confidence ?? 0.0;
        if (imageUrl == null) {
          _predictionImageUrl = null;
        } else if (imageUrl.toString().startsWith('http')) {
          _predictionImageUrl = imageUrl.toString();
        } else {
          final s = imageUrl.toString();
          _predictionImageUrl = s.startsWith('/') ? API_BASE + s : API_BASE + '/' + s;
        }
      });

      await _loadHistory();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('diagnosis')}: ${_predictionLabel ?? tr('unknown')} (${(_predictionConfidence ?? 0.0).toStringAsFixed(2)}%)')),
      );
    } catch (e, st) {
      debugPrint('Upload/Prediction error: $e\n$st');
      setState(() => _error = tr('upload_prediction_failed', args: [e.toString()]));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('upload_prediction_failed', args: [e.toString()])), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _lastPickedFile = null;
          _lastPickedBytes = null;
          _lastPickedFileName = null;
        });
      }
    }
  }

  // Helper to guess mime from filename
  String? _getMimeTypeFromFilename(String name) {
    final lower = name.toLowerCase();
    if (!lower.contains('.')) return null;
    final ext = lower.split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  // ---------- Load server-side history (graceful) ----------
  Future<void> _loadHistory() async {
    try {
      final resp = await http.get(Uri.parse(API_HISTORY)).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        setState(() => _history = []);
        return;
      }
      final List<dynamic> raw = json.decode(resp.body) as List<dynamic>;
      final parsed = raw.map((e) {
        if (e is Map<String, dynamic>) return e;
        return Map<String, dynamic>.from(e as Map);
      }).toList();
      setState(() {
        _history = parsed.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('History load error: $e');
      setState(() => _history = []);
    }
  }

  // ---------- UI pieces ----------
  Widget _tipRow({required IconData icon, required String text, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _adviceContainer(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(_cardRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('quick_tips_title'), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _tipRow(icon: Icons.lightbulb_outline, text: tr('tip_daylight'), theme: theme),
        _tipRow(icon: Icons.zoom_in, text: tr('tip_focus_area'), theme: theme),
        _tipRow(icon: Icons.grass_outlined, text: tr('tip_include_leaf'), theme: theme),
      ]),
    );
  }

  Widget _buildMainInteractiveArea(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardColor;

    if (_isUploading) {
      return Card(
        color: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(tr('analyzing_image'), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.secondary)),
            const SizedBox(height: 8),
            Text(tr('please_wait_processing'), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    if (_lastPickedFile != null || _lastPickedBytes != null) {
      final Widget previewWidget;
      if (!kIsWeb && _lastPickedFile != null) {
        previewWidget = Image.file(_lastPickedFile!, fit: BoxFit.cover, width: double.infinity);
      } else if (kIsWeb && _lastPickedBytes != null) {
        previewWidget = Image.memory(_lastPickedBytes!, fit: BoxFit.cover, width: double.infinity);
      } else {
        previewWidget = Container(color: colorScheme.surfaceVariant, child: Center(child: Icon(Icons.broken_image, size: 50, color: colorScheme.error)));
      }

      return Card(
        color: cardBg,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(_cardRadius)), child: AspectRatio(aspectRatio: 4 / 3, child: previewWidget)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showUploadConfirmationDialog,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(tr('confirm_and_diagnose')),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _lastPickedFile = null;
                  _lastPickedBytes = null;
                  _lastPickedFileName = null;
                }),
                icon: const Icon(Icons.close),
                label: Text(tr('discard')),
              ),
            ]),
          ),
        ]),
      );
    }

    // Default initial prompt
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.camera_alt_outlined, size: 80, color: colorScheme.primary),
      const SizedBox(height: 16),
      Text(tr('start_diagnosing'), style: theme.textTheme.headlineSmall),
      const SizedBox(height: 10),
      Text(tr('take_picture_prompt'), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: Text(tr('camera')),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(tr('gallery')),
        ),
      ]),
    ]);
  }

  // ---------- History item widget ----------
  Widget _historyItem(Map<String, dynamic> item) {
    final result = item['result']?.toString() ?? item['prediction']?.toString() ?? tr('unknown');
    final confidence = item['confidence']?.toString() ?? '';
    final filename = item['filename']?.toString();
    final imageUrlRaw = item['image_url'] ?? item['image'] ?? filename;
    final imageUrl = (imageUrlRaw == null)
        ? null
        : imageUrlRaw.toString().startsWith('http')
            ? imageUrlRaw.toString()
            : API_BASE + (imageUrlRaw.toString().startsWith('/') ? '' : '/') + imageUrlRaw.toString();

    final ts = item['timestamp'] ?? item['created_at'];
    final when = ts != null ? DateTime.tryParse(ts.toString()) : null;
    final whenLabel = when != null ? when.toLocal().toString() : '';

    return InkWell(
      onTap: imageUrl != null
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: imageUrl != null ? Image.network(imageUrl) : const SizedBox(),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          if (imageUrl != null)
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover))
          else
            Container(width: 72, height: 72, color: Colors.grey[200], child: const Icon(Icons.image, size: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(result, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${confidence}% • $whenLabel', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
  
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                Text(tr('ai_powered_plant_doctor'), style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26, color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                Text(tr('get_instant_diagnosis'), style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 18),

                // interactive area
                _buildMainInteractiveArea(theme),

                const SizedBox(height: 22),

                // Prediction result (if any)
                if (_predictionLabel != null) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(children: [
                        if (_predictionImageUrl != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_predictionImageUrl!, width: 96, height: 96, fit: BoxFit.cover)) else SizedBox(width: 96, height: 96),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_predictionLabel!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 6),
                            Text('${tr('confidence')}: ${_predictionConfidence?.toStringAsFixed(2) ?? '0.00'}%', style: const TextStyle(fontSize: 14)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // error (if any)
                if (_error != null) ...[
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.error_outline, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text(_error!))])),
                  const SizedBox(height: 12),
                ],

                // tips
                _adviceContainer(theme),

                const SizedBox(height: 28),

                // History list
                Align(alignment: Alignment.centerLeft, child: Text(tr('recent_diagnoses'), style: theme.textTheme.titleMedium)),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Center(child: Text(tr('no_history_yet')))),
                if (_history.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, idx) => _historyItem(_history[idx]),
                  ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
