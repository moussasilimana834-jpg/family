import 'package:family/pages/messages_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:family/services/auth/chat/chat_services.dart';

class UserListPage extends StatelessWidget {
  UserListPage({super.key});

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Utilisateurs"),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersListStream(),
      builder: (context, snapshot) {
        // Gestion des errors
        if (snapshot.hasError) {
          return const Center(
            child: Text("Une erreur est survenue"),
          );
        }
        //Affichage des données
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucun utilisateur trouvé"));
        }

        //On filtre pour ne pas s'afficher soi même dans la liste
        final allUsers = snapshot.data!;
        final usersToFilter =allUsers.where((user){
          final hasUid = user['uid'] != null;
          final isCurrentUser = user['uid'] != _auth.currentUser?.uid;
          return hasUid && isCurrentUser;
        }).toList();

        // Construction de la liste
        return ListView.builder(
            itemCount: usersToFilter.length,
            itemBuilder: (context, index) {
              final user = usersToFilter[index];
              return _buildUserListItem(user, context);
            });
      },
    );
  }



// Widget pour un seul utilisateur dans la liste
  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {


    final String userEmail = userData['email'] ?? 'Utilisateur inconnu';
    final String receiverID = userData['uid']; // On suppose que l'UID est toujours présent

    return ListTile(
      leading: CircleAvatar(
        child: Text(userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?'),
      ),
      title: Text(userEmail),
      onTap: () {
        // Naviguer vers la page de conversation en cliquant
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              // On passe le titre et les IDs à la page de conversation
              title: userEmail,
              id: receiverID,
              isGroup: false,
            ),
          ),
        );
      },
    );
    }
  }

