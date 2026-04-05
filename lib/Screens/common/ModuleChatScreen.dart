import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../Models/ChatMessage.dart';
import '../../Services/chat/ChatService.dart';
import '../../Theme/theme_helper.dart';

class ModuleChatScreen extends StatefulWidget {
  final String moduleCode;
  final String moduleName;
  final String senderName;
  final String senderRole;

  const ModuleChatScreen({
    super.key,
    required this.moduleCode,
    required this.moduleName,
    required this.senderName,
    required this.senderRole,
  });

  @override
  State<ModuleChatScreen> createState() => _ModuleChatScreenState();
}

class _ModuleChatScreenState extends State<ModuleChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        moduleCode: widget.moduleCode,
        moduleName: widget.moduleName,
        senderName: widget.senderName,
        senderRole: widget.senderRole,
        text: text,
      );

      _messageCtrl.clear();

      await Future.delayed(const Duration(milliseconds: 120));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.colors;

        return AlertDialog(
          backgroundColor: colors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete message',
            style: GoogleFonts.syne(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Do you want to delete this message?',
            style: GoogleFonts.dmSans(
              color: colors.text2,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: colors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.dmSans(
                  color: colors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _chatService.deleteMessage(
        moduleCode: widget.moduleCode,
        messageId: message.id,
        currentUserRole: widget.senderRole,
        messageSenderId: message.senderId,
      );

      if (!mounted) return;
      _showSnack('Message deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed: $e');
    }
  }

  bool _canDelete(ChatMessage message) {
    final bool isLecturer = widget.senderRole.toLowerCase() == 'lecturer';
    final bool isOwner = _chatService.currentUserId == message.senderId;
    return isLecturer || isOwner;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left_rounded, color: colors.text),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.moduleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.moduleCode,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.text2,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(widget.moduleCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.teal),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load chat',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: colors.text,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_rounded,
                            size: 52,
                            color: colors.text3,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start the module discussion here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: colors.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe =
                        message.senderId == _chatService.currentUserId;
                    final bool isLecturerMessage =
                        message.senderRole.toLowerCase() == 'lecturer';

                    return GestureDetector(
                      onLongPress: _canDelete(message)
                          ? () => _confirmDelete(message)
                          : null,
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? colors.teal
                                : isLecturerMessage
                                    ? colors.bg3
                                    : colors.bg2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            border: isMe
                                ? null
                                : Border.all(
                                    color: isLecturerMessage
                                        ? colors.teal.withOpacity(0.25)
                                        : colors.bg4,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        message.senderName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isLecturerMessage
                                              ? colors.teal
                                              : colors.text,
                                        ),
                                      ),
                                    ),
                                    if (isLecturerMessage) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.teal.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Lecturer',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                message.text,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: isMe
                                      ? colors.white
                                      : message.deleted
                                          ? colors.text2
                                          : colors.text,
                                  fontStyle: message.deleted
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatTime(message.createdAt),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: isMe
                                        ? colors.white.withOpacity(0.85)
                                        : colors.text2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: colors.bg,
                border: Border(
                  top: BorderSide(color: colors.bg4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.bg2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.bg4),
                      ),
                      child: TextField(
                        controller: _messageCtrl,
                        minLines: 1,
                        maxLines: 4,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: colors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: colors.text2,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? colors.teal.withOpacity(0.6)
                            : colors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.teal.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: colors.white,
                              size: 22,
                            ),
                    ),
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