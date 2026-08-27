import '../models/chat_message.dart';

/// A conversational assistant that answers whatever the user asks it.
///
/// Implementations may be a real AI model (see [GeminiChatService]) or a
/// fully offline fallback (see [DemoChatService]) so the feature always
/// works even without any API key configured.
abstract interface class ChatService {
  Future<String> ask(String question, {List<ChatMessage> history});
}
