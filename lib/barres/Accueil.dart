// accueil_page.dart
import 'dart:async'; // Import for StreamSubscription
import 'dart:io'; // Import for File

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family/sous_fonctionnalites/publication_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for storage
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image_picker
import 'package:family/barres/Profile.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({Key? key}) : super(key: key);

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance; // Storage instance


  StreamSubscription? _userSubscription;
  Map<String, dynamic>? _currentUserData; // Local state for current user data

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _userSubscription = _firestore.collection('users').doc(currentUserId).snapshots().listen((snap) {
      if (mounted && snap.exists) {
        final data = snap.data()!;
        setState(() {
          _currentUserData = data; // Store current user data
        });
      }
    });
  }

  // 🔹 Pick and upload a story
  Future<void> _pickAndUploadStory() async {
    final user = _auth.currentUser;
    if (user == null || _currentUserData == null) return;

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final ref = _storage.ref().child('stories').child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publication de votre story...')),
    );

    try {
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('stories').add({
        'uid': user.uid,
        'userName': _currentUserData!['name'] ?? 'Utilisateur',
        'photoUrl': imageUrl, // The story image itself
        'userPhotoUrl': _currentUserData!['photoUrl'], // The user's profile pic for the circle
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Story publiée !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }


  // 🔹 Like système
  void _toggleLike(String postId, List likes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final postRef = _firestore.collection('publications').doc(postId);
    if (likes.contains(uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  // 🔹 Récupération des infos user
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final userSnap = await _firestore.collection('users').doc(uid).get();
    return userSnap.data();
  }

  // 🔹 add a comment
  Future<void> _addComment(String postId, String text) async {
    final uid = _auth.currentUser!.uid;
    final user = await _getUserData(uid);
    await _firestore.collection('publications').doc(postId).collection('comments').add({
      'uid': uid,
      'name': user?['name'] ?? 'Utilisateur',
      'text': text,
      'timestamp': Timestamp.now(),
    });
    await _firestore
        .collection('publications')
        .doc(postId)
        .update({'commentsCount': FieldValue.increment(1)});

  }

  // 🔹 S’abonner


  // 🔹 Affiche les commentaires dans un modal
  void _showComments(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final commentCtrl = TextEditingController();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Commentaires 💬",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('publications')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),

                    builder: (context, snap) {
                      if(snap.connectionState == ConnectionState.waiting){
                        return const Center(child: CircularProgressIndicator(),
                        );
                      }
                      if (snap.hasError) {
                        print("Erreur StreamBuilder:${snap.error}");

                        return const Center(child: Text("Erreur lors du chargement des commentaires"));
                      }
                      if(!snap.hasData || snap.data!.docs.isEmpty){
                        return const Center(child: Text("Soyez le premier à commenter cette publication"));
                      }
                      final comments = snap.data!.docs;
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, i) {
                          final c = comments[i].data() as Map<String, dynamic>;
                          final username = c.containsKey('name') ? c['name'] : 'utilisateur anonyme';
                          final commentType = c.containsKey('text') ? c['text'] : '';
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundImage:
                              AssetImage('assets/default_avatar.png'),
                            ),
                            title: Text(username),
                            subtitle: Text(commentType),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: InputDecoration(
                            hintText: "Écrire un commentaire...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async{
                          final text = commentCtrl.text.trim();
                          if (text.isNotEmpty ){

                           FocusScope.of(context).unfocus();

                            try{
                              await _addComment(postId, text);
                              commentCtrl.clear();
                            }catch(e){
                              if(mounted){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erreur lors de l'ajout du commentaire"))
                                );

                              }
                            }
                          }
                        },
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
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
              onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context)=> const PublicationPage(),
                    ),

                );
              },
              icon: Icon(
                  Icons.add,
                color: Colors.orange,
                size: 30,

              )
          ),
          // 🔹 Section Statuts
          SizedBox(
            height: 110,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('stories')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stories = snapshot.data!.docs;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: stories.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final userPhotoUrl = _currentUserData?['photoUrl'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: _pickAndUploadStory,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundImage: userPhotoUrl != null
                                        ? NetworkImage(userPhotoUrl)
                                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                  ),
                                  IconButton(onPressed: _pickAndUploadStory, icon: Icon(Icons.add))
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Ajouter",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = stories[i-1].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(data['photoUrl']),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['userName'] ?? '',

                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Flux de publications
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('publications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Erreur: ${snapshot.error}"),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Aucune publication pour le moment."));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    final data = post.data() as Map<String, dynamic>;

                   // recuperation de l'Id de l'auteur
                    final postAuthorId = data['uid'] as String ;

                    final currentUserId = _auth.currentUser!.uid;
                    final List likes = List.from(data['likes'] ?? []);
                    final isLiked = likes.contains(currentUserId);
                    final commentsCount = data['commentsCount'] ?? 0;


                    // si l'Id est manquant , on affiche une tuile vide pour éviter une erreur
                    if(postAuthorId == false || postAuthorId.toString().trim().isEmpty) {
                      return const SizedBox.shrink();
                    }


                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('users').doc(postAuthorId).snapshots(),
                      builder: (context, userSnapshot) {
                        if(userSnapshot.connectionState == ConnectionState.waiting){
                          return const ListTile (
                        title: Text("Chargement..."),
                            leading: CircleAvatar(),
                          );
                        }
                        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                          // Gère le cas où l'utilisateur a été supprimé
                          return const SizedBox.shrink();
                        }

                        final user = userSnapshot.data!.data() as Map<String, dynamic>;
                        final userName = user['name'] ?? 'Utilisateur';
                        final userPhoto = user['photoUrl'];

                        void navigationToProfile(){
                          Navigator.push(context,
                              MaterialPageRoute(
                                builder: (context) =>
                                // on passe l'id de lauteur à la profilePage
                                    ProfilePage(userId: postAuthorId),
                              )
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Post Header
                              ListTile(
                                onTap: navigationToProfile,
                                leading: CircleAvatar(
                                  backgroundImage: userPhoto != null
                                      ? NetworkImage(userPhoto)
                                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                ),
                                title: Text(
                                  userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),

                              ),
                                   // Description (Text du post)
                              if(data['text'] != null && data['text'].toString().isNotEmpty)
                             Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               child: Text(data['text'], style: const TextStyle(fontSize: 16)),
                             ),
                              //Média (Image or video)
                              if(data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                                Container(
                                  height:250,
                                  width:double.infinity,
                                  decoration: BoxDecoration(
                                    color:Colors.black12,
                                    // on verify le type pour savoir si on affiche image ou la video
                                    image: data["imageUrl"] == 'image'
                                      ? DecorationImage(image: NetworkImage(data['imageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                      : null
                                  ),
                                  // si c'est une video , on met icon
                                  child: data['mediaType'] == 'video'
                                    ? const Center(child: Icon(Icons.play_circle_fill,
                                     size: 60, color:Colors.white))
                                     :null,
                                ),

                              // Action Buttons
                              Padding(
                                padding:
                                const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    // bouton like
                                    IconButton(
                                      icon: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? Colors.redAccent
                                            : Colors.black,
                                      ),
                                      onPressed: () =>
                                          _toggleLike(post.id, likes),
                                    ),
                                    Text("${likes.length}"),

                                    const SizedBox(width: 10),
                                    // bouton de comments
                                    IconButton(
                                      icon:
                                      const Icon(Icons.comment_outlined),
                                      onPressed: () =>
                                          _showComments(context, post.id),
                                    ),
                                    Text("${commentsCount}"),
                                  ],
                                ),
                              ),
                            ],
                        )
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}