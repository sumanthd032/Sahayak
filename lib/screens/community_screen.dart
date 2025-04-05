import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MaterialApp(
    home: CommunityScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _communityNameController = TextEditingController();
  final TextEditingController _communityDescriptionController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _communityNameController.dispose();
    _communityDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (_communityNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community name cannot be empty.')),
      );
      return;
    }

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final String communityId = _firestore.collection('communities').doc().id;
        final Color randomColor = Color.fromARGB(
          255,
          150 + (DateTime.now().millisecond % 106),
          150 + ((DateTime.now().millisecond + 30) % 106),
          150 + ((DateTime.now().millisecond + 60) % 106),
        );

        await _firestore.collection('communities').doc(communityId).set({
          'id': communityId,
          'name': _communityNameController.text.trim(),
          'description': _communityDescriptionController.text.trim(),
          'creatorId': user.uid,
          'members': [user.uid],
          'createdAt': Timestamp.now(),
          'colorHex': randomColor.value.toRadixString(16),
        });

        _communityNameController.clear();
        _communityDescriptionController.clear();
        setState(() {});
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating community: $e')),
      );
    }
  }

  Future<void> _joinCommunity(String communityId) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentReference communityRef =
          _firestore.collection('communities').doc(communityId);

      _firestore.runTransaction((transaction) async {
        final DocumentSnapshot snapshot = await transaction.get(communityRef);
        if (!snapshot.exists) throw Exception("Community does not exist!");

        final List<String> members =
            (snapshot.data() as Map<String, dynamic>)['members']?.cast<String>() ?? [];

        if (!members.contains(user.uid)) {
          transaction.update(communityRef, {
            'members': [...members, user.uid],
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined community successfully!')),
          );
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already a member of this community.')),
          );
        }
      });
    }
  }

  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Community'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _communityNameController,
                decoration: const InputDecoration(labelText: 'Community Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _communityDescriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: _createCommunity,
            ),
          ],
        );
      },
    );
  }

  void _navigateToChatScreen(String communityId, String communityName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          communityId: communityId,
          communityName: communityName,
        ),
      ),
    );
  }

  Widget _buildCommunityGridItem(DocumentSnapshot community) {
    final Map<String, dynamic> data = community.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Community Name';
    final String description = data['description'] ?? '';
    final String colorHex = data['colorHex'] ?? 'ff9e9e9e';

    final int colorValue = int.tryParse(colorHex, radix: 16) ?? 0xFF9E9E9E;
    final Color communityColor = Color(colorValue | 0xFF000000); // Ensure full opacity

    return GestureDetector(
      onTap: () {
        final User? user = _auth.currentUser;
        final List<String> members = (data['members'] as List<dynamic>?)?.cast<String>() ?? [];
        if (user != null && members.contains(user.uid)) {
          _navigateToChatScreen(community.id, name);
        } else if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Join the community to start chatting.')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: communityColor,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color.fromARGB(255, 17, 16, 16)),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 73, 62, 62).withOpacity(0.8)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _joinCommunity(community.id),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCommunityDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('communities').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No communities available.'));
            }
            return GridView.builder(
              itemCount: snapshot.data!.docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return _buildCommunityGridItem(snapshot.data!.docs[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const ChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    final User? user = _auth.currentUser;
    if (user != null && _messageController.text.trim().isNotEmpty) {
      await _firestore
          .collection('communities')
          .doc(widget.communityId)
          .collection('messages')
          .add({
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Anonymous',
        'timestamp': Timestamp.now(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('communities')
                  .doc(widget.communityId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading messages.'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['senderName'] ?? 'User'),
                      subtitle: Text(data['text']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
