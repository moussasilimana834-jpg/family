import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:family/barres/live_stream_page.dart';

class LivePage extends StatelessWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""
            "🎥 Lives en Direct",
          style: TextStyle(color: Colors.orange),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔴 Bouton "Démarrer un Live"
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                elevation: 3,
              ),
              onPressed: () => _showStartLiveDialog(context),
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text(
                "Démarrer un Live",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const Divider(),

          // 🔴 Liste des lives en cours
          Expanded(child: _buildLiveList(context)),
        ],
      ),
    );
  }

  // 🔴 Liste verticale des lives en cours
  Widget _buildLiveList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lives')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Une erreur s'est produite."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun live pour le moment."));
        }

        final lives = snapshot.data!.docs;

        return ListView.builder(
          // scrollDirection: Axis.horizontal, // Supprimé pour défilement vertical
          itemCount: lives.length,
          padding: const EdgeInsets.all(16), // Padding uniforme pour la liste verticale
          itemBuilder: (context, index) {
            final live = lives[index].data() as Map<String, dynamic>;
            final title = live['title'] ?? "Live sans titre";
            final host = live['hostEmail'] ?? "Utilisateur inconnu";
            final channelName = live['channelName'];

            if (channelName == null) return const SizedBox.shrink(); // Ne rien afficher si channelName est nul

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveStreamPage(
                    channelName: channelName,
                    isBroadcaster: false,
                  ),
                ),
              ),
              child: Container(
                // width: 250, // Supprimé pour que l'élément prenne toute la largeur
                margin: const EdgeInsets.only(bottom: 16), // Marge en bas entre les éléments
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder du live
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: const DecorationImage(
                          image: AssetImage("assets/live_placeholder.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "LIVE 🔴",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                    // Infos du live
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "par $host",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _LikeButton(channelName: channelName),
                              _CommentButton(channelName: channelName),
                            ],
                          ),
                        ],
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
  }

  // 🔴 Pop-up pour démarrer un nouveau live
  void _showStartLiveDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎬 Nouveau Live"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: "Titre du live",
            hintText: "Ex: Live cuisine avec moi",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context);
                _startLive(context, title);
              }
            },
            child: const Text("Démarrer"),
          ),
        ],
      ),
    );
  }

  // 🔴 Démarrage du live
  void _startLive(BuildContext context, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour démarrer un live.")),
      );
      return;
    }

    final channelName = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance.collection('lives').doc(channelName).set({
      'title': title,
      'hostUid': user.uid,
      'hostEmail': user.email,
      'channelName': channelName,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': [],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveStreamPage(channelName: channelName, isBroadcaster: true),
      ),
    );
  }
}

// ❤️ Bouton Like avec compteur dynamique
class _LikeButton extends StatefulWidget {
  final String channelName;
  const _LikeButton({required this.channelName});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('lives').doc(widget.channelName).snapshots(),
      builder: (context, snapshot) {
        int likes = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          likes = data?['likes'] ?? 0; // Accès sécurisé
        }

        return Row(
          children: [
            IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                setState(() => liked = !liked);
                FirebaseFirestore.instance
                    .collection('lives')
                    .doc(widget.channelName)
                    .update({'likes': FieldValue.increment(liked ? 1 : -1)});
              },
            ),
            Text('$likes'),
          ],
        );
      },
    );
  }
}

// 💬 Bouton Commentaire
class _CommentButton extends StatelessWidget {
  final String channelName;
  const _CommentButton({required this.channelName});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.comment, color: Colors.blueGrey),
      onPressed: () => _showCommentsSheet(context),
    );
  }

  void _addComment(String text) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final comment = {
      'text': text,
      'user': user.email ?? 'Anonyme',
      'timestamp': FieldValue.serverTimestamp(),
    };

    FirebaseFirestore.instance
        .collection('lives')
        .doc(channelName)
        .update({'comments': FieldValue.arrayUnion([comment])});
  }

  void _showCommentsSheet(BuildContext context) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("💬 Commentaires", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('lives').doc(channelName).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("Impossible de charger les commentaires."));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final comments = (data['comments'] as List<dynamic>?)?.map((c) => c as Map<String, dynamic>).toList() ?? [];

                  if (comments.isEmpty) {
                    return const Center(child: Text("Aucun commentaire pour l'instant."));
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final text = comment['text'] ?? '';
                      final user = comment['user'] ?? 'Anonyme';
                      final timestamp = comment['timestamp'] as Timestamp?;

                      return ListTile(
                        title: Text(text, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          "par $user",
                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: timestamp != null
                          ? Text(
                              '${timestamp.toDate().hour}:${timestamp.toDate().minute}',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            )
                          : null,
                      );
                    },
                  );
                },
              ),
            ),
             const SizedBox(height: 8),
            // Champ de saisie pour nouveau commentaire
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Écrire un commentaire...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = commentController.text.trim();
                    if (text.isNotEmpty) {
                      _addComment(text);
                      commentController.clear();
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: (text) {
                 if (text.trim().isNotEmpty) {
                    _addComment(text.trim());
                    commentController.clear();
                  }
              },
            ),
          ],
        ),
      ),
    );
  }
}
