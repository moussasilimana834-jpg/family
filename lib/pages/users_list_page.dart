import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:family/barres/messages.dart'; // To navigate to the chat page

class UsersListPage extends StatelessWidget {
  UsersListPage({super.key});

  // Get instance of auth service
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          // error
          if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue."));
          }

          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun utilisateur trouvé."));
          }

          // return list view
          return ListView(
            children: snapshot.data!
                .map<Widget>((userData) => _buildUserListItem(userData, context))
                .toList(),
          );
        },
      ),
    );
  }

  // build individual user list item
  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    // display all users except current user
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null && userData["email"] != currentUser.email) {
      return ListTile(
        title: Text(userData["email"]),
        onTap: () {
          // tapped on a user -> go to chat page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagesPage(
                title: userData["email"],
                id: userData["uid"],
                isGroup: false,
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }

  // Method to get the stream of users from Firestore
  Stream<List<Map<String, dynamic>>> _getUsersStream() {
    return FirebaseFirestore.instance.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }
}
