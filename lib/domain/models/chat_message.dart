enum ChatSender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.text,
    required this.sentAt,
  });

  final ChatSender sender;
  final String text;
  final DateTime sentAt;

  bool get isUser => sender == ChatSender.user;
}
