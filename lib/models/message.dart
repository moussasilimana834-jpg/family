import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family/services/auth/chat/chat_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

class MessagesPages extends StatefulWidget {
  final String? receiverEmail;  // null if group
  final String? receiverID;     // null if group
  final bool isGroupChat;
  final String? groupID;        // required if group

  MessagesPages({
    super.key,
    this.receiverEmail,
    this.receiverID,
    this.groupID,
    this.isGroupChat = false,
  }) : assert(isGroupChat ? groupID != null : (receiverEmail != null && receiverID != null));

  @override
  State<MessagesPages> createState() => _MessagesPagesState();
}

class _MessagesPagesState extends State<MessagesPages> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      if (widget.isGroupChat) {
        await _chatService.sendGroupMessage(widget.groupID!, _messageController.text);
      } else {
        await _chatService.sendMessage(widget.receiverID!, _messageController.text);
      }
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupChat ? "Group Chat" : widget.receiverEmail!),
         backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String? currentUserID = _auth.currentUser?.uid;
    if (!widget.isGroupChat && currentUserID == null) {
        return Center(child: Text("Not logged in"));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: widget.isGroupChat
          ? _chatService.getGroupMessages(widget.groupID!)
          : _chatService.getMessages(widget.receiverID!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No messages yet."));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
         crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
            Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: EdgeInsets.all(12),
                 decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    data["message"],
                    style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                )
            ),
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                data['senderEmail'],
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message",
                 border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: sendMessage,
            icon: Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          )
        ],
      ),
    );
  }
}
