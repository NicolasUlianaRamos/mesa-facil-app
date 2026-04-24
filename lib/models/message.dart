class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final int? relatedTableNumber;
  final String? relatedOrderId;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.relatedTableNumber,
    this.relatedOrderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'relatedTableNumber': relatedTableNumber,
      'relatedOrderId': relatedOrderId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? '';
    final rawSenderId =
        json['senderId'] ??
        json['senderUserId'] ??
        json['sender_user_id'] ??
        '';
    final rawContent = json['content'] ?? json['text'] ?? '';
    final rawTimestamp = json['timestamp'] ?? json['createdAt'] ?? '';

    return Message(
      id: rawId.toString(),
      senderId: rawSenderId.toString(),
      senderName: (json['senderName'] ?? '').toString(),
      content: rawContent.toString(),
      timestamp: DateTime.tryParse(rawTimestamp.toString()) ?? DateTime.now(),
      relatedTableNumber: json['relatedTableNumber'] as int?,
      relatedOrderId: json['relatedOrderId'] as String?,
    );
  }
}
