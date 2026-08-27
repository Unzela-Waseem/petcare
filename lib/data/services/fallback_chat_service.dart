import 'package:flutter/foundation.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_service.dart';
import 'demo_chat_service.dart';

/// Wraps a "real" AI-backed [ChatService] (e.g. [GeminiChatService]) and
/// silently falls back to [DemoChatService] if the backend isn't
/// configured yet or a request fails, so the chatbot always replies.
class FallbackChatService implements ChatService {
  FallbackChatService({required this.primary, DemoChatService? fallback})
    : _fallback = fallback ?? DemoChatService();

  final ChatService primary;
  final DemoChatService _fallback;

  @override
  Future<String> ask(String question, {List<ChatMessage> history = const []}) async {
    try {
      return await primary.ask(question, history: history);
    } catch (error) {
      debugPrint('Primary chat service failed, using offline fallback: $error');
      return _fallback.ask(question, history: history);
    }
  }
}
