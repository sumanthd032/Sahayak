import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class StoryZoneScreen extends StatefulWidget {
  const StoryZoneScreen({Key? key}) : super(key: key);

  @override
  State<StoryZoneScreen> createState() => _StoryZoneScreenState();
}

class _StoryZoneScreenState extends State<StoryZoneScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedStory = '';
  bool _isLoading = false;

  final String _apiKey = 'AIzaSyBGiFS4pSgTgJNrkg0WlraNcRzItNNGD3U'; // Replace this

  Future<void> _generateStory() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedStory = '';
    });

    final url =
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Write a creative short story based on: "$prompt"'}
          ]
        }
      ]
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
          _generatedStory = 'Failed to generate story: ${data['error']?['message'] ?? "Unknown error"}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text('Story Zone', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _generatedStory.isEmpty
                      ? Center(child: Text('Your story will appear here...', style: GoogleFonts.poppins(color: Colors.grey)))
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
                            child: Text(
                              _generatedStory,
                              style: GoogleFonts.poppins(fontSize: 16),
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
