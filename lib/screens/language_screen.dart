// lib/screens/language_screen.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'role_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  List<dynamic> languages = [];
  String? selectedCode;
  Locale? deviceLocale;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _loading = true;
  bool _loadFailed = false;
  String? _playingAsset;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      // detect device locale
      deviceLocale = WidgetsBinding.instance.window.locale;

      await _loadLanguages();
      await _loadSavedLocale();

      // ensure at least one selectedCode
      selectedCode ??= 'en';
    } catch (e, st) {
      debugPrint('LanguageScreen._initAll error: $e\n$st');
      // fallback minimal data so UI still works
      languages = [
        {"code": "phone", "native": "Phone's language — en", "audio": null},
        {"code": "en", "native": "English", "audio": null},
      ];
      selectedCode ??= 'en';
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tries common locations for the JSON asset and parses it.
  Future<void> _loadLanguages() async {
    const candidates = [
      'assets/langs/languages.json', // alternative
    ];

    String? raw;
    Object? lastError;

    for (final path in candidates) {
      try {
        raw = await rootBundle.loadString(path);
        if (raw.trim().isNotEmpty) {
          debugPrint('Loaded languages.json from: $path');
          break;
        } else {
          debugPrint('Asset found but empty: $path');
        }
      } catch (e) {
        debugPrint('Failed to load $path: $e');
        lastError = e;
      }
    }

    if (raw == null) {
      throw Exception('Could not load languages.json. Last error: $lastError');
    }

    final jsonData = jsonDecode(raw);

    final list = jsonData['languages'];
    if (list == null || list is! List) {
      throw Exception('languages.json missing "languages" array');
    }

    languages = [
      {"code": "phone", "native": "Phone's language", "audio": null},
      ...list,
    ];

    // show device language on top item if matched
    if (deviceLocale != null) {
      final idx = languages.indexWhere((l) => l["code"] == deviceLocale!.languageCode);
      if (idx != -1) {
        languages[0]["native"] = "Phone's language — ${languages[idx]['native']}";
      } else {
        languages[0]["native"] = "Phone's language — ${deviceLocale!.languageCode}";
      }
    }

    // done
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('locale_code');
    if (saved != null && saved.isNotEmpty) {
      selectedCode = saved;
    } else {
      selectedCode = 'en';
    }
  }

  Future<void> _saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', code);
  }

  Future<void> _playAudio(String? assetPath) async {
    if (assetPath == null) return;

    try {
      // toggle behavior: stop if same asset is playing
      if (_playingAsset == assetPath) {
        await _audioPlayer.stop();
        setState(() => _playingAsset = null);
        return;
      }

      await _audioPlayer.stop();
      // assetPath in JSON usually like "audio/en.mp3" (relative to assets/)
      await _audioPlayer.play(AssetSource(assetPath));
      setState(() => _playingAsset = assetPath);

      // clear when done
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _playingAsset = null);
      });
    } catch (e, st) {
      debugPrint('Audio play error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio')),
        );
      }
    }
  }

  void _onSelectLanguage(Map lang, {bool play = false}) {
    final code = lang['code'] as String?;
    final audio = lang['audio'] as String?;
    setState(() {
      selectedCode = code;
    });

    if (play && audio != null) {
      _playAudio(audio);
    }
  }

  void _onNext() async {
    if (selectedCode == null) return;

    if (selectedCode == "phone") {
      if (deviceLocale != null) {
        try {
          context.setLocale(deviceLocale!);
        } catch (e) {
          // ignore if deviceLocale not supported by easy_localization
          context.setLocale(const Locale('en'));
        }
      } else {
        context.setLocale(const Locale('en'));
      }
    } else {
      try {
        context.setLocale(Locale(selectedCode!));
      } catch (_) {
        context.setLocale(const Locale('en'));
      }
    }

    await _saveLocale(selectedCode!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language saved')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
    );
  }

  Widget _buildLanguageTile(Map lang) {
    final code = lang['code'] as String?;
    final native = lang['native'] as String? ?? '';
    final audio = lang['audio'] as String?;
    final isSelected = selectedCode == code;
    final avatarText = (code ?? '').toUpperCase();
    final avatarLabel = avatarText.isNotEmpty && avatarText != 'PHONE' ? avatarText : 'A';
    final isPlaying = (_playingAsset != null && audio != null && _playingAsset == audio);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onSelectLanguage(lang, play: true),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF64DD17) : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade800,
                child: Text(
                  avatarLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      native,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      code ?? '',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (audio != null)
                IconButton(
                  onPressed: () => _playAudio(audio),
                  tooltip: 'Play language name',
                  icon: isPlaying
                      ? const Icon(Icons.stop, color: Color(0xFF64DD17))
                      : const Icon(Icons.volume_up, color: Colors.white),
                ),
              Radio<String>(
                value: code ?? '',
                groupValue: selectedCode ?? '',
                onChanged: (value) {
                  setState(() {
                    selectedCode = value;
                  });
                },
                activeColor: const Color(0xFF64DD17),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      // show helpful retry UI
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load languages.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initAll,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64DD17), foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "What's your language?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You can change this later from Settings",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index] as Map;
                  return _buildLanguageTile(lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: Color(0xFF64DD17), size: 22),
            SizedBox(width: 6),
            Text(
              "CropCareAI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            )
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onNext,
        backgroundColor: const Color(0xFF64DD17),
        child: const Icon(Icons.arrow_forward, color: Colors.black),
      ),
    );
  }
}
