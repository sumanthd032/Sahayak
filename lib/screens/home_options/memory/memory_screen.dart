import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryNotesScreen extends StatefulWidget {
  const MemoryNotesScreen({super.key});

  @override
  State<MemoryNotesScreen> createState() => _MemoryNotesScreenState();
}

class _MemoryNotesScreenState extends State<MemoryNotesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late CollectionReference userNotesRef;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    if (user != null) {
      userNotesRef = FirebaseFirestore.instance
          .collection('notes')
          .doc(user!.uid)
          .collection('user_notes');
      _listenToNotes();
    }
  }

  void _listenToNotes() {
    userNotesRef.orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      final List<Map<String, dynamic>> loadedNotes = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['text'] != null && data['title'] != null) {
          loadedNotes.add({
            'id': doc.id,
            'title': data['title'],
            'text': data['text'],
            'isSensitive': data['isSensitive'] ?? false,
          });
        }
      }
      setState(() {
        _notes = loadedNotes;
      });
    });
  }

  void _addOrEditNote({String? id, String? existingTitle, String? existingText, bool isSensitive = false}) {
    final TextEditingController titleController = TextEditingController(text: existingTitle ?? "");
    final TextEditingController textController = TextEditingController(text: existingText ?? "");
    bool _isSensitive = isSensitive;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            id == null ? "✨ Add Memory Note" : "🛠️ Edit Memory Note",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Write your memory...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _isSensitive,
                      onChanged: (value) {
                        setStateDialog(() {
                          _isSensitive = value ?? false;
                        });
                      },
                    ),
                    const Text("Mark as Sensitive"),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final String title = titleController.text.trim();
                final String text = textController.text.trim();
                if (title.isNotEmpty && text.isNotEmpty) {
                  if (id == null) {
                    await userNotesRef.add({
                      'title': title,
                      'text': text,
                      'timestamp': FieldValue.serverTimestamp(),
                      'isSensitive': _isSensitive,
                    });
                  } else {
                    await userNotesRef.doc(id).update({
                      'title': title,
                      'text': text,
                      'isSensitive': _isSensitive,
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: Text("Save", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  void _openNoteDetail(String title, String text, bool isSensitive) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(title: title, text: text, isSensitive: isSensitive),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Memory Notes",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Container(
        
        color: Colors.pink.shade50,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIntroCard(),
            const SizedBox(height: 24),
            Expanded(
              child: _notes.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 70, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "No memory notes yet.",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final bool isSensitive = note['isSensitive'] ?? false;

                        return GestureDetector(
                          onTap: () => _openNoteDetail(
                            note['title'],
                            note['text'],
                            isSensitive,
                          ),
                          onLongPress: () {
                            _addOrEditNote(
                              id: note['id'],
                              existingTitle: note['title'],
                              existingText: note['text'],
                              isSensitive: isSensitive,
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note['title'],
                                      style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (isSensitive)
                                    const Icon(Icons.lock, color: Colors.redAccent),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 174, 154, 211),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🧠 What are Memory Notes?",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Store your thoughts and reflections. Tap below to begin your memory journey.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text("Add Note", style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 110, 228, 202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _addOrEditNote(),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteDetailScreen extends StatelessWidget {
  final String title;
  final String text;
  final bool isSensitive;

  const NoteDetailScreen({
    Key? key,
    required this.title,
    required this.text,
    required this.isSensitive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Note Detail", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sticky_note_2_rounded, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isSensitive) const Icon(Icons.lock, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: GoogleFonts.roboto(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
