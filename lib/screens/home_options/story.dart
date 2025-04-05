import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryZoneScreen extends StatefulWidget {
  const StoryZoneScreen({super.key});

  @override
  State<StoryZoneScreen> createState() => _StoryZoneScreenState();
}

class _StoryZoneScreenState extends State<StoryZoneScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedStory = '';
  bool _isLoading = false;
  bool _isSpeaking = false;

  final String _apiKey =
      'AIzaSyBGiFS4pSgTgJNrkg0WlraNcRzItNNGD3U'; // Replace with your key
  final FlutterTts _flutterTts = FlutterTts();

  String _preferredLangCode = 'en'; // default

  @override
  void initState() {
    super.initState();
    _fetchPreferredLanguage();
  }

  Future<void> _fetchPreferredLanguage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final lang = doc['preferredLanguage'] ?? 'English';

        // Example mapping, you can expand this
        final langMap = {
          'English': 'en',
          'Hindi': 'hi',
          'Kannada': 'kn',
          'Telugu': 'te',
          'Tamil': 'ta',
        };

        setState(() {
          _preferredLangCode = langMap[lang] ?? 'en';
        });
      }
    } catch (e) {
      debugPrint('Language fetch error: $e');
    }
  }

  Future<String> _translateStory(String text, String targetLangCode) async {
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLangCode&dt=t&q=${Uri.encodeFull(text)}',
    );

    try {
      final response = await http.get(url);
      final List<dynamic> data = json.decode(response.body);
      return data[0][0][0]; // First sentence
    } catch (e) {
      debugPrint('Translation error: $e');
      return text; // Fallback to original
    }
  }

  Future<void> _generateStory() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedStory = '';
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Write a creative short story based on: "$prompt"'},
          ],
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['candidates'] != null) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _generatedStory = text;
          _isLoading = false;
        });
      } else {
        setState(() {
          _generatedStory =
              'Failed to generate story: ${data['error']?['message'] ?? "Unknown error"}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _generatedStory = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _speakStory() async {
    if (_generatedStory.isEmpty) return;

    setState(() {
      _isSpeaking = true;
    });

    final translated = await _translateStory(
      _generatedStory,
      _preferredLangCode,
    );

    await _flutterTts.setLanguage(_preferredLangCode);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    await _flutterTts.speak(translated);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          'Story Zone',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade100,
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'Enter your story idea...',
                      hintStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateStory,
                    icon: const Icon(Icons.auto_stories),
                    label: Text('Generate Story', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                      : _generatedStory.isEmpty
                      ? Center(
                        child: Text(
                          'Your story will appear here...',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                      : SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.shade100,
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSpeaking ? null : _speakStory,
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text('Narrate'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _stopSpeaking,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _generatedStory,
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
