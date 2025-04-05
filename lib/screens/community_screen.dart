import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahayak/screens/community/chat_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;
  late String userName;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      _fetchUserName();
    }
  }

  Future<void> _fetchUserName() async {
    final doc = await _firestore.collection('users').doc(userId).get();
    setState(() {
      userName = doc['full_name'] ?? 'User';
    });
  }

  Future<bool> _isMember(String communityId) async {
    final memberDoc = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(userId)
        .get();
    return memberDoc.exists;
  }

  Future<void> _joinCommunity(String communityId) async {
    final memberRef = _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(userId);

    final doc = await memberRef.get();
    if (!doc.exists) {
      await memberRef.set({
        'userName': userName,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Successfully joined the community!")),
      );
      setState(() {});
    }
  }

  void _openChat(String communityId) async {
    final joined = await _isMember(communityId);
    if (joined) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            communityId: communityId,
            userId: userId,
            userName: userName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ Please join the community first.")),
      );
    }
  }

  Future<void> _showCreateCommunityDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("✨ Create New Community"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Community Name",
                    prefixIcon: Icon(Icons.group_add),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.create),
              label: Text("Create"),
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isNotEmpty) {
                  final docRef = await _firestore.collection('communities').add({
                    'name': name,
                    'description': desc,
                    'createdBy': userId,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await _joinCommunity(docRef.id);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Communities"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Create Community",
            onPressed: _showCreateCommunityDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('communities').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            final communities = snapshot.data!.docs;

            if (communities.isEmpty) {
              return Center(child: Text("🚫 No communities available."));
            }

            return ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final doc = communities[index];
                final communityId = doc.id;
                final communityName = doc['name'] ?? 'Unnamed';
                final communityDesc = doc['description'] ?? '';

                return FutureBuilder<bool>(
                  future: _isMember(communityId),
                  builder: (context, memberSnapshot) {
                    final isMember = memberSnapshot.data ?? false;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.group, color: Colors.indigo),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      communityName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                communityDesc,
                                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                              ),
                              SizedBox(height: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('communities')
                                    .doc(communityId)
                                    .collection('members')
                                    .snapshots(),
                                builder: (context, snap) {
                                  if (!snap.hasData) return Text("Loading...");
                                  return Text(
                                    '${snap.data!.docs.length} member(s)',
                                    style: TextStyle(color: Colors.grey[700]),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: Icon(isMember ? Icons.chat : Icons.login),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isMember ? Colors.green : Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => isMember
                                      ? _openChat(communityId)
                                      : _joinCommunity(communityId),
                                  label: Text(isMember ? "Chat" : "Join"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
