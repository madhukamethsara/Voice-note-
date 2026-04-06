import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Models/ChatMessage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String moduleCode) {
    return _firestore
        .collection('module_chats')
        .doc(moduleCode)
        .collection('messages');
  }

  DocumentReference<Map<String, dynamic>> _chatRoomRef(String moduleCode) {
    return _firestore.collection('module_chats').doc(moduleCode);
  }

  Future<void> ensureChatRoomExists({
    required String moduleCode,
    required String moduleName,
  }) async {
    final doc = await _chatRoomRef(moduleCode).get();

    if (!doc.exists) {
      await _chatRoomRef(moduleCode).set({
        'moduleCode': moduleCode,
        'moduleName': moduleName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendMessage({
    required String moduleCode,
    required String moduleName,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) return;

    await ensureChatRoomExists(
      moduleCode: moduleCode,
      moduleName: moduleName,
    );

    final docRef = _messagesRef(moduleCode).doc();

    final message = ChatMessage(
      id: docRef.id,
      moduleCode: moduleCode,
      senderId: currentUserId,
      senderName: senderName,
      senderRole: senderRole,
      text: trimmed,
      createdAt: DateTime.now(),
      deleted: false,
    );

    await docRef.set(message.toMap());

    await _chatRoomRef(moduleCode).set({
      'moduleCode': moduleCode,
      'moduleName': moduleName,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': trimmed,
      'lastSenderName': senderName,
    }, SetOptions(merge: true));
  }

  Stream<List<ChatMessage>> streamMessages(String moduleCode) {
    return _messagesRef(moduleCode)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> deleteMessage({
    required String moduleCode,
    required String messageId,
    required String currentUserRole,
    required String messageSenderId,
  }) async {
    final isLecturer = currentUserRole.toLowerCase() == 'lecturer';
    final isOwner = currentUserId == messageSenderId;

    if (!isLecturer && !isOwner) {
      throw Exception('You do not have permission to delete this message');
    }

    await _messagesRef(moduleCode).doc(messageId).update({
      'text': 'This message was deleted',
      'deleted': true,
      'deletedBy': currentUserId,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }
}