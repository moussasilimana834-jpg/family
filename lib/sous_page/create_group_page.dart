import 'package:family/barres/messages.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:family/components/my_textfield.dart';
import 'package:family/services/auth/chat/chat_services.dart';


class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);


  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}


class _CreateGroupPageState extends State<CreateGroupPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _nameCtrl = TextEditingController();
  final List<String> _selected = [];
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Créer un groupe')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
              children: [
              MyTextField(controller: _nameCtrl, hintText: 'Nom du groupe'),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('email').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final m = d.data() as Map<String, dynamic>;
                    final uid = m['uid'] ?? d.id;
                    final email = m['email'] ?? 'user';
                    if (uid == currentUid) return const SizedBox.shrink();
                    final selected = _selected.contains(uid);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(email),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) _selected.add(uid);
                          else _selected.remove(uid);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
                ElevatedButton(
                  onPressed: _create,
                  child: const Text('Créer le groupe'),
                )
              ],
          ),
        ),
    );
  }


  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et membres requis')));
      return;
    }
    try {
      final groupId = await _chatService.createGroup(name, _selected);
      Navigator.pop(context);
// open the group chat immediately
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesPage(isGroup: true, id: groupId, title: name)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}