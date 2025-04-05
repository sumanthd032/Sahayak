import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'noteDetail_screen.dart';

class MemoryNotesScreen extends StatefulWidget {
  const MemoryNotesScreen({Key? key}) : super(key: key);

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
    userNotesRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> loadedNotes = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['text'] != null) {
          loadedNotes.add({
            'id': doc.id,
            'text': data['text'],
          });
        }
      }

      setState(() {
        _notes = loadedNotes;
      });
    });
  }

  void _addOrEditNote({String? id, String? existingText}) {
    final TextEditingController controller =
        TextEditingController(text: existingText ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(id == null ? "Add Memory Note" : "Edit Memory Note"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Write your memory...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final String text = controller.text.trim();
              if (text.isNotEmpty) {
                if (id == null) {
                  // Add new note
                  await userNotesRef.add({
                    'text': text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                } else {
                  // Update existing note
                  await userNotesRef.doc(id).update({'text': text});
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteNote(String id) {
    userNotesRef.doc(id).delete();
  }

  void _showNoteDetail(String note, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          note: note,
          noteId: id,
          onDelete: _deleteNote,
          onEdit: ({String? id, String? existingText}) {
            _addOrEditNote(id: id, existingText: existingText);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Memory Notes"),
        backgroundColor: const Color.fromARGB(255, 151, 126, 196),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIntroCard(),
            const SizedBox(height: 24),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(
                      child: Text(
                        "📝 No notes saved yet.",
                        style: TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return GestureDetector(
                          onTap: () =>
                              _showNoteDetail(note['text'], note['id']),
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                note['text'].length > 120
                                    ? "${note['text'].substring(0, 120)}..."
                                    : note['text'],
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
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
        color: Colors.deepPurple[50],
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
          const Text(
            "🧠 What are Memory Notes?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Store your thoughts and important reflections. Tap below to begin.",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Note"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 110, 228, 202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _addOrEditNote(),
            ),
          ),
        ],
      ),
    );
  }
}
