import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_glove_app/widgets/bluetooth_status_widget.dart';
import 'package:smart_glove_app/widgets/input_text_field_widget.dart';
import 'package:smart_glove_app/widgets/language_selector_widget.dart';
import 'package:smart_glove_app/widgets/translation_list_widget.dart';

class TranslateService {
  Future<String> translate(String text, String targetLang) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': 'autodetect|$targetLang',
      'de': 'madonnas797@email.com',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["responseData"]["translatedText"] ?? "Translation Error";
      }
      return "Translation Error";
    } catch (e) {
      return "Network Error";
    }
  }
}

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController _controller = TextEditingController();
  final TranslateService _translator = TranslateService();
  final User? user = FirebaseAuth.instance.currentUser;
  final FlutterTts flutterTts = FlutterTts();

  bool isMuted = false;
  String lastWord = "";
  String selectedTtsLang = "auto";

  List<String> selectedLanguages = [];
  Map<String, String> translatedResults = {};

  final Map<String, String> languageCodes = {
    'English': 'en',
    'German': 'de',
    'French': 'fr',
    'Italian': 'it',
    'Arabic': 'ar',
  };

  BluetoothConnection? connection;
  StreamSubscription<Uint8List>? _btSubscription;
  bool isConnected = false;
  bool isConnecting = false;
  Timer? _reconnectTimer;
  final List<int> _chunks = [];

  @override
  void initState() {
    super.initState();
    connectToBluetooth();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _btSubscription?.cancel();
    connection?.dispose();
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  String detectLanguage(String text) {
    final arabic = RegExp(r'[\u0600-\u06FF]');
    if (arabic.hasMatch(text)) return "ar-SA";
    return "en-US";
  }

  Future<void> connectToBluetooth() async {
    if (isConnected || isConnecting) return;

    if (mounted) {
      setState(() {
        isConnecting = true;
      });
    }

    try {
      await _btSubscription?.cancel();
      _btSubscription = null;
      await connection?.finish();
      connection = null;
    } catch (_) {}

    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        if (mounted) {
          setState(() {
            isConnecting = false;
            isConnected = false;
          });
        }
        _triggerAutoReconnect();
        return;
      }

      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      BluetoothDevice? hc05;

      for (var device in devices) {
        if (device.name == "HC-05") {
          hc05 = device;
          break;
        }
      }

      if (hc05 == null) {
        if (mounted) {
          setState(() {
            isConnecting = false;
            isConnected = false;
          });
        }
        _triggerAutoReconnect();
        return;
      }

      connection = await BluetoothConnection.toAddress(
        hc05.address,
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          isConnected = true;
          isConnecting = false;
        });
      }

      _reconnectTimer?.cancel();

      if (connection?.input == null) return;

      _btSubscription = connection!.input!.listen(
        (Uint8List data) {
          _chunks.addAll(data);

          try {
            String currentBuffer = utf8.decode(_chunks);

            if (currentBuffer.contains('\n')) {
              List<String> lines = currentBuffer.split('\n');

              _chunks.clear();
              _chunks.addAll(utf8.encode(lines.last));

              for (int i = 0; i < lines.length - 1; i++) {
                String text = lines[i].trim();
                if (text.isEmpty) continue;

                if (text.contains("AI Prediction")) {
                  _processPredictionJson(text);
                }
              }
            }
          } catch (e) {
            debugPrint("Buffer parsing error: $e");
          }
        },
        onDone: _handleDisconnect,
        onError: (error) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("Bluetooth Connection Error: $e");

      if (mounted) {
        setState(() {
          isConnected = false;
          isConnecting = false;
        });
      }
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _chunks.clear();
    _btSubscription?.cancel();
    _btSubscription = null;

    if (mounted) {
      setState(() {
        isConnected = false;
        isConnecting = false;
      });
      _triggerAutoReconnect();
    }
  }

  void _triggerAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!isConnected && mounted) {
        debugPrint("Attempting to auto-reconnect to HC-05...");
        connectToBluetooth();
      }
    });
  }

  void _processPredictionJson(String text) {
    try {
      int start = text.indexOf('{');
      int end = text.lastIndexOf('}');

      if (start != -1 && end != -1) {
        String jsonPart = text.substring(start, end + 1);
        var decoded = jsonDecode(jsonPart);
        String word = decoded["prediction"];

        if (word != _controller.text && mounted) {
          setState(() {
            _controller.text = word;
          });
          speak(word);

          if (selectedLanguages.isNotEmpty) {
            translateText();
          }
        }
      }
    } catch (e) {
      debugPrint("JSON Parsing Error: $e");
    }
  }

  void translateText() async {
    if (_controller.text.isEmpty || selectedLanguages.isEmpty) return;

    if (mounted) {
      setState(() {
        translatedResults.clear();
      });
    }

    for (var lang in List<String>.from(selectedLanguages)) {
      final code = languageCodes[lang] ?? 'en';
      String result = await _translator.translate(_controller.text, code);

      if (mounted) {
        setState(() {
          translatedResults[lang] = result;
        });
      }
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await flutterTts.stop();
    final lang = detectLanguage(text);

    await flutterTts.setLanguage(lang);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Future<void> speakTranslated(String text, String langCode) async {
    if (text.trim().isEmpty) return;

    await flutterTts.stop();
    await flutterTts.setLanguage(langCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  Future<void> saveMessage(String translation, String lang) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("messages")
          .add({
        "text": _controller.text,
        "translation": translation,
        "language": lang,
        "time": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved successfully"),
            backgroundColor: Color(0xFF660643),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  if (user == null) {
    return const Scaffold(body: Center(child: Text("Please log in")));
  }

  final entries = translatedResults.entries.toList();

  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF660643),
      elevation: 0,
      title: const Text(
        'Smart Glove Translator',
        style: TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. WIDGET 1: محدد اللغات
                SliverToBoxAdapter(
                  child: LanguageSelectorWidget(
                    languageCodes: languageCodes,
                    selectedLanguages: selectedLanguages,
                    onLanguageSelected: (lang, selected) {
                      setState(() {
                        selected
                            ? selectedLanguages.add(lang)
                            : selectedLanguages.remove(lang);
                      });
                      if (selectedLanguages.isNotEmpty &&
                          _controller.text.isNotEmpty) {
                        translateText();
                      }
                    },
                  ),
                ),

                // مسافة رأسية
                const SliverToBoxAdapter(
                  child: SizedBox(height: 25),
                ),

                // 2. WIDGET 2: حقل الإدخال
                SliverToBoxAdapter(
                  child: InputTextFieldWidget(
                    controller: _controller,
                    onClear: () {
                      _controller.clear();
                      setState(() {
                        translatedResults.clear();
                      });
                    },
                  ),
                ),

                // مسافة رأسية
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),

                // 3. WIDGET 3: حالة اتصال البلوتوث
                SliverToBoxAdapter(
                  child: BluetoothStatusWidget(
                    isConnected: isConnected,
                    isConnecting: isConnecting,
                    onRetry: connectToBluetooth,
                  ),
                ),

                // مسافة رأسية
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // 4. WIDGET 4: قائمة الترجمات (بدون SliverToBoxAdapter لأنها ترجع SliverList)
                TranslationListWidget(
                  entries: entries,
                  languageCodes: languageCodes,
                  onSpeak: speakTranslated,
                  onSave: saveMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // زر الترجمة الثابت في الأسفل
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: translateText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF660643),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Translate Now',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}}