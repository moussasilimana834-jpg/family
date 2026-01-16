import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveStreamPage extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;

  const LiveStreamPage({
    super.key,
    required this.channelName,
    required this.isBroadcaster,
  });

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showHearts = false;
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _incrementViewers();
  }

  @override
  void dispose() {
    _decrementViewers();
    super.dispose();
  }

  // 🔹 Incrémenter les spectateurs
  Future<void> _incrementViewers() async {
    await FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.channelName)
        .update({'viewers': FieldValue.increment(1)});
  }

  // 🔹 Décrémenter quand on quitte
  Future<void> _decrementViewers() async {
    await FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.channelName)
        .update({'viewers': FieldValue.increment(-1)});
  }

  // 🔹 Envoi d’un message
  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _chatController.text.trim();
    if (text.isEmpty || user == null) return;

    await FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.channelName)
        .collection('messages')
        .add({
      'user': user.displayName ?? user.email ?? 'Anonyme',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _chatController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 70,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // 🔹 Like (cœur volant + compteur)
  void _sendLike() async {
    setState(() => _showHearts = true);
    Future.delayed(const Duration(seconds: 1), () => setState(() => _showHearts = false));

    await FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.channelName)
        .update({'likes': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎥 Placeholder de la vidéo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white70, size: 100),
              ),
            ),
          ),

          // ❤️ Animation des cœurs
          if (_showHearts)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showHearts ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100, right: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return AnimatedPositioned(
                            duration: Duration(milliseconds: 800 + index * 200),
                            bottom: 0 + (index * 40),
                            right: 0,
                            child: const Icon(Icons.favorite, color: Colors.redAccent, size: 30),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 🔝 Barre du haut : profil + spectateurs + quitter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lives')
                        .doc(widget.channelName)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final data = snapshot.data!;
                      final host = data['hostEmail'] ?? 'Inconnu';
                      final views = data['viewers'] ?? 0;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white12,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(host, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('$views spectateurs',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(widget.isBroadcaster ? "Arrêter" : "Quitter"),
                  ),
                ],
              ),
            ),
          ),

          // 💬 Chat en direct
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lives')
                        .doc(widget.channelName)
                        .collection('messages')
                        .orderBy('timestamp')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final messages = snapshot.data!.docs;

                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index].data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.person, size: 18, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${msg['user'] ?? 'Anonyme'} : ${msg['text'] ?? ''}",
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Écrire un message...",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                        onPressed: _sendLike,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
