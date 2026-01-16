

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:family/services/auth/chat/chat_services.dart';


class GroupMembersPage extends StatefulWidget {
  final String groupId;
  const GroupMembersPage({Key? key, required this.groupId}) : super(key: key);


  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}


class _GroupMembersPageState extends State<GroupMembersPage> {
  final ChatService _chatService = ChatService();
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  late DocumentReference _groupRef;


  @override
  void initState() {
    super.initState();
    _groupRef = FirebaseFirestore.instance.collection('group_chats').doc(widget.groupId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membres du groupe')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _groupRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erreur'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final members = List<String>.from(data['members'] ?? []);
          final admin = data['admin'] as String?;


          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, i) {
              final uid = members[i];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnap) {
                  final email = userSnap.hasData ? (userSnap.data!.data() as Map<String, dynamic>)['email'] ?? 'user' : 'Chargement...';
                  final isAdmin = uid == admin;
                  return ListTile(
                    leading: CircleAvatar(child: Text(email[0].toUpperCase())),
                    title: Text(email),
                    subtitle: isAdmin ? const Text('Admin') : null,
                    trailing: _buildTrailing(uid, isAdmin, admin == currentUid),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  Widget? _buildTrailing(String memberUid, bool isAdmin, bool currentIsAdmin) {
    if (isAdmin) return const SizedBox.shrink();
    if (!currentIsAdmin) return null; // only admin can remove/ promote
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (val == 'remove') {
          await _chatService.removeMemberFromGroup(widget.groupId, memberUid);
        }
        if (val == 'promote') {
          await _groupRef.update({'admin': memberUid});
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'remove', child: Text('Supprimer')),
        const PopupMenuItem(value: 'promote', child: Text('Promouvoir admin')),
      ],
    );
  }
}