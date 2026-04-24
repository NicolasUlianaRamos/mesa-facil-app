import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/message.dart';
import '../services/api_config.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final Set<String> _messageIds = {};
  int _unreadCount = 0;

  io.Socket? _socket;
  String? _roomId;

  bool _chatOpen = false;
  bool _loadingHistory = false;
  int _page = 0;
  int _pages = 1;

  ChatProvider() {
    _connect();
  }

  List<Message> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;
  bool get isLoadingHistory => _loadingHistory;

  void setChatOpen(bool open) {
    _chatOpen = open;
    if (open) {
      markAsRead();
      if (_roomId == null) {
        unawaited(_ensureInternalRoomAndJoin());
      }
    }
  }

  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> sendTextMessage({
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return;
    }

    if (_roomId == null) {
      await _ensureInternalRoomAndJoin();
      if (_roomId == null) return;
    }

    final payload = <String, dynamic>{
      if (_roomId != null) 'roomId': _roomId else 'roomKey': 'internal',
      'text': text,
      'senderName': senderName,
      'senderUserId': senderId,
    };

    // Backend will broadcast `chat:message:new` back to us.
    socket.emit('chat:message', payload);
  }

  Future<void> loadOlderMessages() async {
    if (_loadingHistory) return;
    if (_roomId == null) return;
    if (_page >= _pages) return;

    await _loadHistoryPage(_page + 1);
  }

  void _connect() {
    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(500)
          .build(),
    );

    _socket = socket;

    socket.onConnect((_) {
      unawaited(_ensureInternalRoomAndJoin());
      notifyListeners();
    });

    socket.onDisconnect((_) {
      notifyListeners();
    });

    socket.on('chat:message:new', (dynamic data) {
      if (data is Map) {
        final msg = Message.fromJson(Map<String, dynamic>.from(data));
        _upsertMessage(msg);
      }
    });

    socket.connect();
  }

  Future<void> _ensureInternalRoomAndJoin() async {
    final socket = _socket;
    if (socket == null || !socket.connected) return;

    final roomId = await _ensureInternalRoom();
    if (roomId == null || roomId.isEmpty) return;

    final roomChanged = _roomId != roomId;
    _roomId = roomId;

    if (roomChanged) {
      _messages.clear();
      _messageIds.clear();
      _page = 0;
      _pages = 1;
    }

    // Join without ack (socket_io_client emit() here doesn't support an ack callback).
    socket.emit('chat:join', {'roomId': _roomId});

    unawaited(_loadHistoryPage(1));
  }

  Future<String?> _ensureInternalRoom() async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBase}/chat/rooms');
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(const {'key': 'internal', 'title': 'internal'}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      final room = map['room'];
      if (room is! Map) return null;

      final roomMap = Map<String, dynamic>.from(room);
      final rawId = roomMap['_id'] ?? roomMap['id'];
      final roomId = rawId?.toString();
      if (roomId == null || roomId.isEmpty) return null;

      return roomId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadHistoryPage(int page) async {
    if (_roomId == null) return;
    if (_loadingHistory) return;

    _loadingHistory = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBase}/chat/rooms/${_roomId!}/messages?page=$page&limit=50',
      );

      final res = await http.get(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) return;

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return;

      final map = Map<String, dynamic>.from(decoded);
      final items = map['items'];
      final pages = map['pages'];

      if (pages != null) {
        _pages = int.tryParse(pages.toString()) ?? _pages;
      }

      if (items is List) {
        final incoming = items
            .whereType<Map>()
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .toList();

        // Page 1 may overlap with messages already received via realtime.
        // Merge+sort so newest stays first without counting history as unread.
        if (page == 1) {
          final merged = <Message>[];
          final ids = <String>{};

          for (final msg in _messages) {
            if (ids.add(msg.id)) merged.add(msg);
          }
          for (final msg in incoming) {
            if (ids.add(msg.id)) merged.add(msg);
          }

          merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          _messages
            ..clear()
            ..addAll(merged);

          _messageIds
            ..clear()
            ..addAll(ids);
        } else {
          // Older pages should be appended to the end (newest-first inside the page).
          for (final msg in incoming) {
            _appendIfMissing(msg);
          }
        }
      }

      _page = page;
    } catch (_) {
      // ignore transient network/parse errors
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  void _appendIfMissing(Message msg) {
    if (_messageIds.contains(msg.id)) return;
    _messageIds.add(msg.id);
    _messages.add(msg);
  }

  void _upsertMessage(Message msg, {bool notify = true}) {
    final already = _messageIds.contains(msg.id);
    if (!already) {
      _messageIds.add(msg.id);
      _messages.insert(0, msg);

      if (!_chatOpen) {
        _unreadCount++;
      }
    }

    if (notify) {
      notifyListeners();
    }
  }
}
