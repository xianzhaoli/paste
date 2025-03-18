class ClipboardItem {
  final String type;
  final String content;
  final String? htmlContent;
  DateTime timestamp;
  final String hash;
  String? size;

  ClipboardItem({
    required this.type,
    required this.content,
    this.htmlContent,
    required this.timestamp,
    required this.hash,
    this.size,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'html_content': htmlContent,
      'timestamp': timestamp.toIso8601String(),
      'hash': hash,
      'size': size,
    };
  }

  static ClipboardItem fromMap(Map<String, dynamic> map) {
    return ClipboardItem(
      type: map['type'],
      content: map['content'],
      htmlContent: map['html_content'],
      timestamp: DateTime.parse(map['timestamp']),
      hash: map['hash'],
      size: map['size'],
    );
  }
}
