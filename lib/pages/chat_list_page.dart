
import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family/barres/messages.dart';
import 'package:family/components/users_list_page.dart';
import 'package:family/services/auth/chat/chat_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> _createCombinedStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final privateChatsStream = _chatService.getChatRoomsStream();
    final groupChatsStream = _chatService.getUserGroups();

    return StreamZip([privateChatsStream, groupChatsStream]).map((results) {
      final privateChats = results[0].docs;
      final groupChats = results[1].docs;

      List<Map<String, dynamic>> combinedList = [];

      for (var doc in privateChats) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> participants = data['participants'];
        final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
        if (otherUserId.isNotEmpty) {
          combinedList.add({
            'id': otherUserId,
            'title': 'Chat with User', // You should fetch the actual user's name/email
            'lastMessage': data['lastMessage'] ?? '',
            'updatedAt': data['updatedAt'],
            'isGroup': false,
          });
        }
      }

      for (var doc in groupChats) {
        final data = doc.data() as Map<String, dynamic>;
        combinedList.add({
          'id': doc.id,
          'title': data['name'] ?? 'Group Chat',
          'lastMessage': data['lastMessage'] ?? '',
          'updatedAt': data['updatedAt'],
          'isGroup': true,
        });
      }

      combinedList.sort((a, b) {
        final aTimestamp = a['updatedAt'] as Timestamp?;
        final bTimestamp = b['updatedAt'] as Timestamp?;
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        return bTimestamp.compareTo(aTimestamp);
      });

      return combinedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){
        Navigator.push(context,
            MaterialPageRoute(builder: (context)=> UserListPage() )
        );
      },
      child: Icon(Icons.message, color: Colors.blue),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _createCombinedStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            // Check if the error message contains the link to create an index.
            if (errorMessage.contains("FAILED_PRECONDITION") && errorMessage.contains("index")) {
              errorMessage += "\n\n--- INSTRUCTIONS ---\nVous devez créer un index dans Firestore. Cherchez le lien dans la console de débogage (il commence par 'https://console.firebase.google.com/...'), cliquez dessus et créez l'index.";
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Erreur : $errorMessage"),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune conversation trouvée."));
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final title = conversation['title'] as String;
              final lastMessage = conversation['lastMessage'] as String;
              final isGroup = conversation['isGroup'] as bool;
              final id = conversation['id'] as String;

              return ListTile(
                title: Text(title),
                subtitle: Text(lastMessage),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        title: title,
                        id: id,
                        isGroup: isGroup,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
