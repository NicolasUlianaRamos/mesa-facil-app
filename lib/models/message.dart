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
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      relatedTableNumber: json['relatedTableNumber'] as int?,
      relatedOrderId: json['relatedOrderId'] as String?,
    );
  }
}
