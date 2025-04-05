import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReligiousModeScreen extends StatefulWidget {
  const ReligiousModeScreen({super.key});

  @override
  State<ReligiousModeScreen> createState() => _ReligiousModeScreenState();
}

class _ReligiousModeScreenState extends State<ReligiousModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> chatHistory = [];
  String preferredLanguage = 'en-US';
  bool _isListening = false;
  bool _isLoadingResponse = false;
  bool _speechAvailable = false;

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
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );

    await _flutterTts.setLanguage(preferredLanguage);
  }

  Future<void> _fetchPreferredLanguage() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data()?['preferredLanguage'] != null) {
        setState(() {
          preferredLanguage = userDoc.data()!['preferredLanguage'];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchChatHistory() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot =
          await _firestore
              .collection('religious_chats')
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
    if (message.trim().isEmpty || _isLoadingResponse) return;

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
      await _firestore.collection('religious_chats').add(userMsg);

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

      await _firestore.collection('religious_chats').add(botMsg);

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

    final disallowedTopics = [
      'programming',
      'flutter',
      'dart',
      'code',
      'math',
      'science',
      'physics',
      'java',
      'algorithm',
    ];

    if (disallowedTopics.any((word) => input.toLowerCase().contains(word))) {
      return "I'm here to help you feel better. Please ask questions related to wellness only.";
    }

    final systemPrompt = '''
You are a compassionate spiritual companion for senior citizens. Only respond to queries about religion, spirituality, peace, faith, prayer, or guidance for the soul. Keep responses kind, simple, short and comforting.when it is needed give lengthy replies also]
Avoid discussing programming, technology, or science. Please respond in user-specified language: $preferredLanguage.
If user asks unrelated questions, say: "I'm here to offer spiritual guidance and peace. Please ask questions related to faith, belief, or inner peace.
''';

    final List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt},
        ],
      },
      {
        'role': 'user',
        'parts': [
          {'text': input},
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
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'Sorry, I could not understand the response.';
      } else {
        print("Response Error: ${response.body}");
        return 'Sorry, something went wrong while getting a response.';
      }
    } catch (e) {
      print("Exception: $e");
      return 'An error occurred while generating a response.';
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;

    // Stop any ongoing TTS when mic is activated
    await _flutterTts.stop();

    if (!_isListening) {
      setState(() {
        _isListening = true;
      });

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

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: Text(
          'Religious Mode',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
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
                        isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoadingResponse,
                    decoration: InputDecoration(
                      hintText: 'Ask something spiritual...',
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
                  onPressed:
                      _isLoadingResponse
                          ? null
                          : () => _sendMessage(_controller.text),
                  color: Colors.green,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _startListening,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Icon(
                Icons.mic,
                size: 48,
                color: _isListening ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
