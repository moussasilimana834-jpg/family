
// moi_page.dart
import 'dart:io';

import  'package:family/sous_fonctionnalités/modifier_profil.dart';
import 'package:family/services/auth/auth_service.dart';
import 'package:family/sous_fonctionnalités/creer_planning.dart';
import 'package:family/sous_fonctionnalités/creer_sondage.dart';
import 'package:family/sous_fonctionnalités/creer_reunion.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import'package:cloud_firestore/cloud_firestore.dart';

class MoiPage extends StatefulWidget {
  const MoiPage({super.key});

  @override
  State<MoiPage> createState() => _MoiPageState();
}

class _MoiPageState extends State<MoiPage> {
  final authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _bioController = TextEditingController();

  bool _isUploading = false;
  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changeProfileImage() async{
    final user = _auth.currentUser;
    if(user==null) return ;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image==null)return ;
    setState(() {
      _isUploading = true;
    });
    try{
      File file = File(image.path);

      final ref = FirebaseStorage.instance
      .ref()
      .child('profil_images')
      .child('${user.uid}.jpg');

      //uploader le fichier
      await ref.putFile(file);

      //récupérer l'Url de telechargement
      final url = await ref.getDownloadURL();

      //Mettre à jour Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl':url,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo de profil mise à jour "),
          backgroundColor: Colors.green,
        ),
      );
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Une erreur s'est produit lors du chargement "),
            backgroundColor: Colors.red,
          )
      );
    }finally{
      if(mounted){
        setState(() {
          _isUploading = false;
        });
      }
    }
  }


  Future<void> _updateBio(String newBio) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'bio': newBio,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Bio mise à jour')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Mon Profil",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ModifierProfilPage()),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,),
            onSelected: (value) {
              if (value == 'planning') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreerPlanningPage()));
              } else if (value == 'sondage') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreerSondagePage()));
              } else if (value == 'reunion') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreerReunionPage()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'planning',
                child: Row(
                  children: [Icon(Icons.calendar_today, color: Colors.blueAccent), SizedBox(width: 10), Text('Planning')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sondage',
                child: Row(
                  children: [Icon(Icons.poll, color: Colors.green), SizedBox(width: 10), Text('Sondage')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reunion',
                child: Row(
                  children: [Icon(Icons.group, color: Colors.orange), SizedBox(width: 10), Text('Réunion')],
                ),
              ),
            ],
          ),

        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? user.displayName ?? 'Utilisateur';
          final photoUrl = data['photoUrl'] ?? user.photoURL;
          _bioController.text = data['bio'] ?? 'Présente-toi ici 🌟';
          final followers = (data['followers'] ?? []).length;
          final following = (data['following'] ?? []).length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // ---------- 🧍 Profil ----------
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploading ? null :_changeProfileImage,
                          child: Stack(
                            children: [
                              _isUploading
                              ?const CircleAvatar(radius: 56,
                                child: CircularProgressIndicator())
                              :CircleAvatar(
                                radius: 56,
                                  backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                   :const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------- 📊 Stats ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream:_firestore
                            .collection("publications")
                            .where('uid', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context , snap){
                          String count= "0";
                          if(snap.hasData){
                            count = snap.data!.docs.length.toString();
                          }
                          return _statBlock('publications', count);
                        }
                      ),
                      _statBlock("Membres", "$followers"),
                      _statBlock("Groupes", "$following"),
                     ]
                  ),

                  const SizedBox(height: 25),

                  // ---------- 📝 Bio ----------
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Présente-toi ici 🌟",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,

                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Colors.blueAccent),
                        onPressed: () => _updateBio(_bioController.text),
                      )
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ---------- 📰 Publications de l’utilisateur ----------
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Mes publications",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('publications')
                        .where('uid', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final posts = snap.data!.docs;

                        //  Retourner un Widget si la liste est vide
                      if (posts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Aucune publication pour le moment 🕊️"),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap:true ,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index].data() as Map<String, dynamic>;
                          //récuperation sécurisé des données

                          final imageUrl = post['imageUrl'] as String?;
                          final textContent = post['text'] as String ? ;
                          final mediaType = post['mediaType'] as  String?;

                          return GestureDetector(
                            onTap: (){
                              //pour ouvrir le post en grand
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context ){
                                    // boîte de dialogue qui affiche le post en grand
                                    return AlertDialog(
                                      contentPadding: EdgeInsets.zero,
                                      // assure que le contenu touche les bords
                                      content:SingleChildScrollView(
                                        // permet au contenu de défiler s'il est trop long
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            if(imageUrl != null && imageUrl.isNotEmpty)
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Image.network(imageUrl,
                                                    fit:BoxFit.cover,
                                                    errorBuilder: (context, error, StackTrace) =>
                                                    const Icon(Icons.broken_image, size: 100),
                                                  ),
                                                  if(mediaType == 'video')
                                                    Icon(Icons.play_circle_fill_outlined,
                                                        color:Colors.white, size: 60,
                                                    )
                                                ],
                                              ),
                                            if(textContent != null && textContent.isNotEmpty)
                                              Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                child: Text(textContent, style: TextStyle(fontSize: 16),
                                                ),
                                              )
                                          ],
                                        ),
                                      )
                                    );
                                  }
                              );
                            },
                            child: Container(
                              color: Colors.grey[300],
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if(imageUrl != null && imageUrl.isNotEmpty)
                                    Image.network(imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error , stackTrace) =>
                                      const Icon(Icons.broken_image, color: Colors.grey),
                                      )
                                      // pas d'image , on affiche le texte
                                      else if( textContent != null && textContent.isNotEmpty)
                                        Padding(
                                            padding:const EdgeInsets.all(4.0),
                                          child: Center(
                                            child: Text(textContent,
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ),
                                        ),

                                  if(mediaType =='video')
                                    const Positioned(
                                      top:4,
                                        right:4,
                                        child: Icon(Icons.videocam)
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
