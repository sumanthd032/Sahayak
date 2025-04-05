import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String communityId;
  final String userId;
  final String userName;

  const ChatScreen({
    Key? key,
    required this.communityId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Cache to avoid fetching the same user's name repeatedly
  final Map<String, String> _userNameCache = {};

  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .add({
      'text': message,
      'senderId': widget.userId,
      'senderName': widget.userName, // still useful as fallback
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _getUserFullName(String senderId, String fallbackName) async {
    if (_userNameCache.containsKey(senderId)) {
      return _userNameCache[senderId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(senderId).get();
      final data = doc.data();
      final fullName = data?['full_name'] ?? fallbackName;
      _userNameCache[senderId] = fullName;
      return fullName;
    } catch (e) {
      return fallbackName;
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> data, bool isMe) {
    return FutureBuilder<String>(
      future: _getUserFullName(data['senderId'], data['senderName'] ?? 'Unknown'),
      builder: (context, snapshot) {
        String displayName = isMe ? 'You' : (snapshot.data ?? 'Unknown');

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[200] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    displayName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                SizedBox(height: 4),
                Text(
                  data['text'] ?? '',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  data['timestamp'] != null
                      ? _formatTimestamp(data['timestamp'])
                      : '',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(
        title: Text('Community Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.userId;
                    return _buildMessageItem(data, isMe);
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
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
