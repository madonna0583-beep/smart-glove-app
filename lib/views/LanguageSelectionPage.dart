import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TranslateService {
  Future<String> translate(String text, String targetLang) async {
    final url =
        "https://api.mymemory.translated.net/get?q=$text&langpair=autodetect|$targetLang&de=madonnas797@email.com";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      return data["responseData"]["translatedText"];
    } catch (e) {
      return "Error";
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
  final user = FirebaseAuth.instance.currentUser;

  final FlutterTts flutterTts = FlutterTts();

  String detectLanguage(String text) {
  final arabic = RegExp(r'[\u0600-\u06FF]');
  if (arabic.hasMatch(text)) return "ar-SA";
  return "en-US";
}

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
  bool isConnected = false;

  String buffer = "";

  Future<void> connectToBluetooth() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance
          .getBondedDevices();

      BluetoothDevice? hc05;

      for (var device in devices) {
        if (device.name == "HC-05") {
          hc05 = device;
          break;
        }
      }

      if (hc05 == null) return;

      connection = await BluetoothConnection.toAddress(hc05.address);

      setState(() {
        isConnected = true;
      });

      if (connection?.input == null) return;

      connection!.input!
          .listen((data) {
            buffer += utf8.decode(data);

            if (!buffer.contains('\n')) return;

            List<String> lines = buffer.split('\n');
            buffer = lines.last;

            for (var line in lines) {
              String text = line.trim();

              if (text.isEmpty) continue;

              if (text.contains("AI Prediction")) {
                try {
                  int start = text.indexOf('{');
                  int end = text.lastIndexOf('}');

                  if (start != -1 && end != -1) {
                    String jsonPart = text.substring(start, end + 1);

                    var decoded = jsonDecode(jsonPart);

                    String word = decoded["prediction"];

                    setState(() {
                      _controller.text = word;
                    });

                     speak(word);
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              }
            }
          })
          .onDone(() {
            setState(() {
              isConnected = false;
            });
          });
    } catch (e) {
      debugPrint("Bluetooth Error: $e");
    }
  }

  void translateText() async {
    if (_controller.text.isEmpty || selectedLanguages.isEmpty) return;

    setState(() {
      translatedResults.clear();
    });

    for (var lang in selectedLanguages) {
      final code = languageCodes[lang] ?? 'en';
      String result = await _translator.translate(_controller.text, code);

      setState(() {
        translatedResults[lang] = result;
      });

      
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
            "time": Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved successfully"),
          backgroundColor: Color(0xFF660643),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    connectToBluetooth();
  }

  @override
  void dispose() {
    connection?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

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
              child: ListView(
                children: [
                  const Text(
                    'Translate to:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: languageCodes.keys.map((lang) {
                      return FilterChip(
                        label: Text(lang),
                        selected: selectedLanguages.contains(lang),
                        selectedColor: const Color(0xFF660643).withOpacity(0.3),
                        onSelected: (bool selected) {
                          setState(() {
                            selected
                                ? selectedLanguages.add(lang)
                                : selectedLanguages.remove(lang);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Detected Text / Input',
                      hintText: 'Type here or wait for Glove data...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            translatedResults.clear();
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(isConnected ? "Connected to HC-05" : "Disconnected"),
                      const Spacer(),
                      TextButton(
                        onPressed: connectToBluetooth,
                        child: const Text("Reconnect"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ...translatedResults.entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Builder(
                        builder: (context) => ListTile(
                          title: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF660643),
                            ),
                          ),
                          subtitle: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 18),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Color(0xFF660643),
                                ),
                                onPressed: () {
                                  final langCode =
                                      languageCodes[entry.key] ?? 'en';
                                  speakTranslated(entry.value, langCode);
                                },
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.bookmark_add,
                                  color: Color(0xFF660643),
                                ),
                                onPressed: () =>
                                    saveMessage(entry.value, entry.key),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF660643),
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
  }
}
