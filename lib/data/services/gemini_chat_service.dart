import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_service.dart';

const _systemPrompt =
    'You are the in-app assistant for PawfectCare, a pet-care Flutter app. '
    'Answer the user\'s question directly and concisely, in the same '
    'language they wrote in (English, Urdu, or Roman Urdu). You are not '
    'limited to pet topics and may help with anything the user asks.\n\n'
    'Here is how PawfectCare itself works, in case the user asks about the '
    'app: after sign up, the user picks one of three roles - Pet Owner, '
    'Veterinarian, or Shelter Admin - which decides what their home screen '
    'shows. The bottom navigation always has 5 tabs: Home (role-specific '
    'dashboard and quick actions), Explore (find vets or adoptable pets), '
    'Saved, Messages, and Profile. A floating chat button (this assistant) '
    'is available from any screen. Pet Owners see: My Pets, Health '
    'Records, Appointments, Pet Store, Care Tips, Adoption, Adoption '
    'Requests, Success Stories, Notifications, and Contact & Feedback. '
    'Veterinarians see: Today\'s Appointments, Assigned Pets, Patient '
    'History, Calendar, Medical Records, Care Tips, Success Stories, and '
    'Notifications. Shelter Admins see: Pet Listings, Adoption Requests, '
    'Success Stories, Volunteer Requests, Contact Messages, Care Tips, and '
    'Notifications. Use this context when the user asks how to run or use '
    'the app, but do not repeat all of it unless it is actually relevant '
    'to what they asked.';

/// Talks directly to the Gemini API.
///
/// The API key ships inside the app for this project, which is fine for a
/// demo/assignment build but not recommended for a production app (a
/// determined user could extract the key from the compiled app). For a
/// production app, proxy this through a backend instead, the way
/// `functions/chatWithAssistant` was set up to do.
class GeminiChatService implements ChatService {
  GeminiChatService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.0-flash:generateContent';

  @override
  Future<String> ask(
    String question, {
    List<ChatMessage> history = const [],
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('No Gemini API key configured.');
    }

    final contents = [
      for (final message in history.where((m) => m.text.trim().isNotEmpty))
        {
          'role': message.isUser ? 'user' : 'model',
          'parts': [
            {'text': message.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    final response = await _client
        .post(
          Uri.parse('$_endpoint?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': _systemPrompt},
              ],
            },
            'contents': contents,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final error =
          (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw StateError(error ?? 'Assistant is unavailable right now.');
    }

    final candidates = body['candidates'] as List<dynamic>?;
    List<dynamic>? parts;
    if (candidates != null && candidates.isNotEmpty) {
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
      parts = content?['parts'] as List<dynamic>?;
    }
    final reply = parts
        ?.map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
        .join()
        .trim();

    if (reply == null || reply.isEmpty) {
      throw StateError('Assistant sent back an empty reply.');
    }
    return reply;
  }
}
