import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class PublicationPage extends StatefulWidget{
  const PublicationPage({super.key});
  @override
  State<PublicationPage> createState() => _PublicationPageState();
}
class _PublicationPageState extends State<PublicationPage>{
  TextEditingController _publiController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  File? _selectedMedia;
  bool _isVideo = false;
  bool  _isUploading = false;
  // Function pour select une un file
  Future<void> _pickMedia(bool isVideoSource) async{
    final XFile? media;
    if(isVideoSource){
      media = await _picker.pickVideo(source: ImageSource.gallery);
    }else{
      media = await _picker.pickImage(source: ImageSource.gallery);
    }
    // Vérification stricte si media n'est pas null
    if (media != null) {
      final String path = media.path;
      setState(() {
        _selectedMedia = File(path);
        _isVideo = isVideoSource;
      });
    }
  }
  // function pour publish
  Future<void> _uploadPost() async {
    // verification de base
    if(_publiController.text.isEmpty && _selectedMedia == null ){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text("Veuillez ajouter une publication")),
      );
      return ;
    }
    setState(() {
      _isUploading = true;
    });
    print("début de 'envoi...");
    try{
      final user = _auth.currentUser;
      if(user == null) return ;
      String ? mediaUrl;
      String mediaType = "text";
      // Astuce : on copy la variable globale dans une variable locale pour eviter l'ereur de null
      final File ? fileToUpload = _selectedMedia;
      // Upload du fichier vers firebase storage si un fichier est selectionné
      if(fileToUpload != null) {
        String fileName = DateTime.now().microsecondsSinceEpoch.toString();
        // Ici on utilise fileToUpload.path qui est sûr
        String extension =  path.extension(fileToUpload.path);
        //crée une reference dans Storage :uploads/userId/timestamp.jpg
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("uploads")
            .child(user.uid)
            .child("$fileName$extension");
        // Upload du fichier
        UploadTask uploadTask = storageRef.putFile(fileToUpload);
        TaskSnapshot snapshot = await uploadTask;
        //récuperation de l'Url
        mediaUrl = await snapshot.ref.getDownloadURL();
        mediaType = _isVideo ? "video" : "image";
      }
      // Enregister  des données dans firestore
      await _firestore.collection('publications').add({
        'uid':user.uid,
        'userEmail':user.email,
        'text':_publiController.text,
        'imageUrl':mediaUrl,
        'mediaType':mediaType,
        'timestamp':FieldValue.serverTimestamp(),
        'likes':[],
        'comments':0,
        'authorId':user.uid,
      });
      print("Fin de l'envoi");
      if(mounted){
     _publiController.clear();
     setState(() {
       _isUploading = false;
     });
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content:
       Text("Publication réussie"),
         backgroundColor: Colors.green,
         duration: Duration(seconds: 2),
       )
     );
     Navigator.of(context).pop();
      }
    }catch(e){
      print("Erreur d'upload : $e");
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Une erreur s'est produite.Veuillez réessayer plus tard"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build (BuildContext context ){
    return Scaffold(
        appBar: AppBar(title: Text("Page de publication",
            style: TextStyle(color:Colors.orange)),
          actions: [
             IconButton(onPressed: _uploadPost,
                 icon: Icon(Icons.send, color: Colors.orange)
             ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _publiController,
                decoration: InputDecoration(
                  labelText: "faites vos  publication",
                  border: OutlineInputBorder(
                    borderRadius:BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height:20),
              //prévisualisation du media selectionné
              if(_selectedMedia != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                        height:200,
                        width:double.infinity,
                        decoration: BoxDecoration(
                          color:Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          image: _isVideo
                              ? null
                              :DecorationImage(image: FileImage(_selectedMedia!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: _isVideo
                            ? const Center(
                            child: Icon(Icons.videocam,
                                size: 50, color: Colors.black54)
                        )
                            :  null
                    ),
                    //boutton pour supprimer le media choisi
                    IconButton(
                      icon:Icon(Icons.close, color:Colors.red),
                      onPressed: (){
                        setState(() {
                          _selectedMedia = null;
                        });
                      },
                    )
                  ],
                ),
              const SizedBox(height: 20),
              // boutons de sélection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null: () => _pickMedia(false),
                    icon: Icon(Icons.photo),
                    label: const Text("Photo"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  ),
                  ElevatedButton.icon(
                      onPressed: _isUploading ? null :()  => _pickMedia(true),
                      icon:  const Icon(Icons.videocam),
                      label: const Text("Vidéo"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange)
                  ),
                ],
              ),
            ],
          ),
        )
    );
  }
}
