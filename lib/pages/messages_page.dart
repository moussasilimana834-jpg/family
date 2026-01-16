

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:family/components/chat_bubble.dart';
import 'package:family/components/my_textfield.dart';
import 'package:family/sous_page/group_members_page.dart';
import 'package:family/services/auth/chat/chat_services.dart';


class MessagesPage extends StatefulWidget {
  final bool isGroup;
  final String id; // groupId or otherUserId
  final String title;


  const MessagesPage({Key? key, required this.isGroup, required this.id, required this.title}) : super(key: key);


  @override
  State<MessagesPage> createState() => _MessagesPageState();
}


class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;


  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }


  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    if (widget.isGroup) await _chatService.sendGroupMessage(widget.id, text);
    else await _chatService.sendMessage(widget.id, text);
    _scrollToBottom();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(child: Text(widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '?')),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        actions: widget.isGroup
            ? [
          IconButton(onPressed: _onViewMembers, icon: const Icon(Icons.info_outline)),
        ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesStream()),
          SafeArea(child: _buildInput()),
        ],
      ),
    );
  }
  Widget _buildMessagesStream() {
    final stream = widget.isGroup ? _chatService.getGroupMessages(widget.id) : _chatService.getMessages(widget.id);
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erreur'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUser?.uid;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: ChatBubble(
                  message: data['message'] ?? '',
                  isCurrentUser: isMe,
                  senderLabel: widget.isGroup ? data['senderEmail'] : null,
                  timestamp: data['timestamp'],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: Colors.blue)),
          Expanded(child: MyTextField(controller: _msgCtrl, hintText: 'Écrire un message...')),
          const SizedBox(width: 8),
          FloatingActionButton.small(onPressed: _send, child: const Icon(Icons.send), elevation: 2),
        ],
      ),
    );
  }


  void _onViewMembers() {
    if (!widget.isGroup) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupMembersPage(groupId: widget.id)));
  }
}
