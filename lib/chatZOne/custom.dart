import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CustomModeScreen extends StatefulWidget {
  const CustomModeScreen({super.key});

  @override
  State<CustomModeScreen> createState() => _CustomModeScreenState();
}

class _CustomModeScreenState extends State<CustomModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> chatHistory = [];
  String preferredLanguage = 'en-US';
  String customPrompt = '';
  bool _isListening = false;
  bool _isLoadingResponse = false;
  bool _speechAvailable = false;
  bool _customModeSet = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _fetchPreferredLanguage();
    await _fetchChatHistory();
    _speechAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );

    await _flutterTts.setLanguage(preferredLanguage);
  }

  Future<void> _fetchPreferredLanguage() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['preferred_language'] != null) {
        setState(() {
          preferredLanguage = userDoc.data()!['preferred_language'];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchChatHistory() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('custom_chats')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp')
          .get();

      setState(() {
        chatHistory = snapshot.docs.map((doc) => doc.data()).toList();
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoadingResponse || !_customModeSet) return;

    FocusScope.of(context).unfocus();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userMsg = {
      'uid': uid,
      'sender': 'user',
      'message': message,
      'timestamp': Timestamp.now(),
    };

    setState(() {
      chatHistory.add(userMsg);
      _controller.clear();
      _isLoadingResponse = true;
    });
    _scrollToBottom();

    try {
      await _firestore.collection('custom_chats').add(userMsg);

      final responseText = await _generateResponse(message);

      final botMsg = {
        'uid': uid,
        'sender': 'bot',
        'message': responseText,
        'timestamp': Timestamp.now(),
      };

      setState(() {
        chatHistory.add(botMsg);
        _isLoadingResponse = false;
      });
      _scrollToBottom();

      await _firestore.collection('custom_chats').add(botMsg);

      await _flutterTts.setLanguage(preferredLanguage);
      await _flutterTts.speak(responseText);
    } catch (_) {
      setState(() => _isLoadingResponse = false);
    }
  }

  Future<String> _generateResponse(String input) async {
    const apiKey = 'AIzaSyBGiFS4pSgTgJNrkg0WlraNcRzItNNGD3U';
    const apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

    final systemPrompt =
        "You are in \"$customPrompt\" mode only.\nOnly respond according to that mode. Do not entertain unrelated queries.\nAlways answer in $preferredLanguage without translating or switching to any other language.\nIf the user asks anything outside the \"$customPrompt\" mode, respond with: \"This request is outside the current mode. Please stick to '$customPrompt' mode\".";

    final messages = [
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ],
      },
      {
        'role': 'user',
        'parts': [
          {'text': input}
        ],
      },
    ];

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': messages}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Sorry, I could not understand the response.';
      } else {
        return 'Sorry, something went wrong while getting a response.';
      }
    } catch (_) {
      return 'An error occurred while generating a response.';
    }
  }

  void _startListening() async {
    if (!_speechAvailable || !_customModeSet) return;
    await _flutterTts.stop();

    if (!_isListening) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        localeId: preferredLanguage,
        onResult: (result) {
          if (result.finalResult) {
            _sendMessage(result.recognizedWords);
          }
        },
      );
    } else {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _askForCustomMode() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a Custom Mode',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Enter mode (e.g., Motivation, Health Tips)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    customPrompt = controller.text.trim();
                    _customModeSet = customPrompt.isNotEmpty;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done),
                label: const Text('Set Mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: Text('Custom Mode', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _askForCustomMode,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_customModeSet)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Please set a custom mode to begin chatting.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          if (_customModeSet)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = chatHistory[index];
                  final isUser = chat['sender'] == 'user';
                  final timestamp = chat['timestamp'] as Timestamp;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.indigo : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat['message'],
                            style: GoogleFonts.poppins(
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_isLoadingResponse)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          if (_customModeSet)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoadingResponse,
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isLoadingResponse
                        ? null
                        : () => _sendMessage(_controller.text),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          if (_customModeSet)
            GestureDetector(
              onTap: _startListening,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Icon(
                  Icons.mic,
                  size: 48,
                  color: _isListening ? Colors.red : Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
