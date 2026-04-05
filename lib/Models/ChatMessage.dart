import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String moduleCode;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime? createdAt;
  final bool deleted;
  final String? deletedBy;
  final DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.moduleCode,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    required this.deleted,
    this.deletedBy,
    this.editedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moduleCode': moduleCode,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'deleted': deleted,
      'deletedBy': deletedBy,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      moduleCode: map['moduleCode'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderRole: map['senderRole'] ?? 'student',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      deleted: map['deleted'] ?? false,
      deletedBy: map['deletedBy'],
      editedAt: map['editedAt'] is Timestamp
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
    );
  }
}