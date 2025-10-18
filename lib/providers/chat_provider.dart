import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  int _unreadCount = 0;

  ChatProvider() {
    _loadMessages();
  }

  List<Message> get messages => _messages;
  int get unreadCount => _unreadCount;

  void _loadMessages() {
    _messages = StorageService.getMessages();
    _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> sendMessage(Message message) async {
    await StorageService.saveMessage(message);
    _loadMessages();
    _unreadCount++;
    notifyListeners();
  }

  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  List<Message> getMessagesByTable(int tableNumber) {
    return _messages
        .where((msg) => msg.relatedTableNumber == tableNumber)
        .toList();
  }
}
