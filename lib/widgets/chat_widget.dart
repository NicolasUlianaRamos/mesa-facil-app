import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/constants.dart';

class ChatWidget extends StatefulWidget {
  final VoidCallback onClose;

  const ChatWidget({super.key, required this.onClose});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final message = Message(
      id: const Uuid().v4(),
      senderId: auth.currentUser!.id,
      senderName: auth.currentUser!.name,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    chatProvider.sendMessage(message);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Positioned(
      right: 16,
      bottom: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          height: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chat Interno',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          final isMe = message.senderId == auth.currentUser?.id;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 240),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      message.senderName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isMe
                                            ? Colors.white.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppColors.primary,
                                      ),
                                    ),
                                  if (!isMe) const SizedBox(height: 4),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
