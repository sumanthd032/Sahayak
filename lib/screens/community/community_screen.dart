import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahayak/screens/community/chat_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;
  String? userName;

  final List<List<Color>> gradientColors = [
    [Colors.purple, Colors.deepPurpleAccent],
    [Colors.teal, Colors.tealAccent],
    [Colors.orange, Colors.deepOrange],
    [Colors.indigo, Colors.blueAccent],
    [Colors.pinkAccent, Colors.redAccent],
    [Colors.cyan, Colors.lightBlueAccent],
    [Colors.green, Colors.lightGreen],
    [Colors.deepPurple, Colors.purpleAccent],
  ];

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
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      setState(() {
        userName = doc['full_name'] ?? 'User';
      });
    } catch (e) {
      debugPrint("Error fetching username: $e");
      setState(() {
        userName = 'User';
      });
    }
  }

  Future<bool> _isMember(String communityId) async {
    final memberDoc =
        await _firestore
            .collection('communities')
            .doc(communityId)
            .collection('members')
            .doc(userId)
            .get();
    return memberDoc.exists;
  }

  Future<void> _joinCommunity(String communityId) async {
    if (userId == null || userName == null) return;

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
          builder:
              (_) => ChatScreen(
                communityId: communityId,
                userId: userId!,
                userName: userName ?? 'User',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "✨ Create New Community",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
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
              child: Text("Cancel", style: GoogleFonts.poppins()),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.create),
              label: Text("Create", style: GoogleFonts.poppins()),
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isNotEmpty && userId != null) {
                  try {
                    final docRef = await _firestore
                        .collection('communities')
                        .add({
                          'name': name,
                          'description': desc,
                          'createdBy': userId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                    await _joinCommunity(docRef.id);
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Error creating community: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Failed to create community.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("⚠️ Please enter a name.")),
                  );
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
        elevation: 1,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black87,
        title: Text(
          "Communities",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Create Community",
            onPressed: _showCreateCommunityDialog,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('communities').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final communities = snapshot.data!.docs;

            if (communities.isEmpty) {
              return Center(
                child: Text(
                  "🚫 No communities available.",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              );
            }

            return GridView.builder(
              itemCount: communities.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final doc = communities[index];
                final communityId = doc.id;
                final communityName = doc['name'] ?? 'Unnamed';
                final communityDesc = doc['description'] ?? '';
                final gradient = gradientColors[index % gradientColors.length];

                return FutureBuilder<bool>(
                  future: _isMember(communityId),
                  builder: (context, memberSnapshot) {
                    final isMember = memberSnapshot.data ?? false;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.85,
                                  ),
                                  child: Icon(Icons.group, color: gradient[0]),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    communityName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              communityDesc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            SizedBox(height: 6),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  _firestore
                                      .collection('communities')
                                      .doc(communityId)
                                      .collection('members')
                                      .snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) return SizedBox();
                                return Text(
                                  '${snap.data!.docs.length} member(s)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.white70,
                                  ),
                                );
                              },
                            ),
                            Spacer(),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  isMember ? Icons.chat : Icons.group_add,
                                  size: 18,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: gradient[0],
                                  minimumSize: Size(110, 36),
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed:
                                    () =>
                                        isMember
                                            ? _openChat(communityId)
                                            : _joinCommunity(communityId),
                                label: Text(
                                  isMember ? "Open Chat" : "Join",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
