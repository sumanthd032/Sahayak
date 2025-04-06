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
      'AIzaSyBGiFS4pSgTgJNrkg0WlraNcRzItNNGD3U'; // Replace with your actual API key
  final FlutterTts _flutterTts = FlutterTts();
  String _preferredLangCode = 'en'; // Default to English

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
        final lang = doc['preferred_language'] ?? 'en';
        setState(() {
          _preferredLangCode = lang;
        });
      }
    } catch (e) {
      debugPrint('Language fetch error: $e');
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
            {
              'text':
                  'Write a creative, fun, simple, and engaging short story for senior citizens in the language "$_preferredLangCode", give only in this language and dont need any other translation give only story. The story idea is: "$prompt"',
            },
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

    await _flutterTts.setLanguage(_preferredLangCode);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    await _flutterTts.speak(_generatedStory);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Story Zone',
          style: GoogleFonts.balooBhai2(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.deepPurple,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lightbulb_outline),
                        hintText: 'Enter a fun story idea...',
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
                      label: Text(
                        'Generate Story',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                      : _generatedStory.isEmpty
                      ? Center(
                        child: Text(
                          'Your magical story will appear here!',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                      : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.shade100,
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSpeaking ? null : _speakStory,
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text('Narrate'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _stopSpeaking,
                                    icon: const Icon(Icons.stop),
                                    label: const Text('Stop'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
