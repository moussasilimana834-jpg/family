

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;




// Users stream (for listing and searching)
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').orderBy('email').snapshots();
  }
  // NEW: Stream for user's private chat rooms
  Stream<QuerySnapshot> getChatRoomsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

// User's groups
  Stream<QuerySnapshot> getUserGroups() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('group_chats')
        .where('members', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

// Private chat room id
  String getChatRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join("_");
  }


// Get messages for private chat
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final roomId = getChatRoomId(user.uid, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  // Send private message
  Future<void> sendMessage(String otherUserId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final roomId = getChatRoomId(user.uid, otherUserId);
    final docRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    final payload = {
      'id': docRef.id,
      'senderId': user.uid,
      'senderEmail': user.email,
      'receiverId': otherUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload);
// update room meta
    await _firestore.collection('chat_rooms').doc(roomId).set({
      'lastMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': [user.uid, otherUserId],
    }, SetOptions(merge: true));
  }




// Get group messages
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('group_chats')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }


// Send group message
  Future<void> sendGroupMessage(String groupId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final messagesRef = _firestore
        .collection('group_chats')
        .doc(groupId)
        .collection('messages')
        .doc();
    await messagesRef.set({
      'id': messagesRef.id,
      'senderId': user.uid,
      'senderEmail': user.email,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
// update group meta
    await _firestore.collection('group_chats').doc(groupId).update({
      'lastMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


// Create group (creator becomes admin)
  Future<String> createGroup(String name, List<String> memberIds) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    final docRef = _firestore.collection('group_chats').doc();
    final members = List<String>.from(memberIds)..add(user.uid);
    final payload = {
      'id': docRef.id,
      'name': name,
      'admin': user.uid,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload);
    return docRef.id;
  }
  // Add member (admin only)
  Future<void> addMemberToGroup(String groupId, String memberUid) async {
    final groupRef = _firestore.collection('group_chats').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayUnion([memberUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


// Remove member (admin only)
  Future<void> removeMemberFromGroup(String groupId, String memberUid) async {
    final groupRef = _firestore.collection('group_chats').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([memberUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


// Rename group (admin only)
  Future<void> renameGroup(String groupId, String newName) async {
    await _firestore
        .collection('group_chats')
        .doc(groupId)
        .update({'name': newName, 'updatedAt': FieldValue.serverTimestamp()});
  }


// Leave group (member)
  Future<void> leaveGroup(String groupId, String memberUid) async {
    await
    _firestore
        .collection('group_chats').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // récuperer le flux de tous les utilisateurs
  Stream<List<Map<String , dynamic>>>getUsersListStream (){
    return _firestore.collection('users').snapshots().map((snapshot){
      return snapshot.docs.map((doc){
        final user = doc.data();
        return user;
      }).toList();
    });
  }
}

