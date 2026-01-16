import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family/components/chat_bubble.dart';
import 'package:family/components/my_textfield.dart';
import 'package:family/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:family/services/auth/chat/chat_services.dart';
import 'package:flutter/scheduler.dart'; // Import for SchedulerBinding

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FocusNode _myFocusNode = FocusNode();

  String? _senderID; // Store the sender ID to avoid repeated calls and null errors.

  @override
  void initState() {
    super.initState();
    // Get the current user's ID once and store it.
    // This is safer than calling it repeatedly in the build method.
    _senderID = _authService.getCurrentUser()?.uid;

    // Add a listener to scroll down when the keyboard appears.
    _myFocusNode.addListener(() {
      if (_myFocusNode.hasFocus) {
        // Use a short delay to allow the keyboard to animate in.
        Future.delayed(const Duration(milliseconds: 300), () => _scrollDown());
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _myFocusNode.dispose();
    super.dispose();
  }

  // A private method for scrolling.
  void _scrollDown() {
    // We use SchedulerBinding to ensure scrolling happens after the UI has been built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final messageText = _messageController.text;
      _messageController.clear(); // Clear the controller immediately for better UX.

      await _chatService.sendMessage(widget.receiverID, messageText);
      // After sending, scroll to the bottom to see the new message.
      _scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
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
    // If we couldn't get a sender ID, it means the user is not logged in.
    if (_senderID == null) {
      return const Center(
        child: Text("Utilisateur non connecté. Impossible de charger les messages."),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Une erreur est survenue."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Envoyez un message pour commencer !"));
        }

        // We have messages, let's scroll to the bottom.
        _scrollDown();

        // Use ListView.builder for better performance with long lists.
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMessageItem(doc);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Check if the current user is the sender. Use the stored _senderID.
    final bool isCurrentUser = data['senderID'] == _senderID;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ChatBubble(
        message: data["message"] ?? "", // Safety check for null message.
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Écrire un message...",
              obscureText: false,
              focusNode: _myFocusNode,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.green,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(Icons.arrow_upward, color: Colors.white),
            onPressed: _sendMessage,
            tooltip: "Envoyer",
          ),
        ],
      ),
    );
  }
}
