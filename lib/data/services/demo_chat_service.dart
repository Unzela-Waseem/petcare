import 'dart:math';

import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_service.dart';

/// Offline fallback assistant.
///
/// Used when no AI backend is configured (see [GeminiChatService]), or if
/// that backend fails, so the chatbot always has something useful to say
/// instead of leaving the user without a reply.
class DemoChatService implements ChatService {
  DemoChatService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static final List<_Rule> _rules = [
    _Rule(
      keywords: ['vaccine', 'vaccination', 'shot', 'injection'],
      replies: [
        'Puppies and kittens usually need their core vaccination series '
            'every 3-4 weeks until about 16 weeks old, then a booster '
            'every year. Open your pet\'s profile and check the Health tab '
            'to see or add a vaccination record, and PawfectCare will '
            'remind you 24 hours before it\'s due.',
      ],
    ),
    _Rule(
      keywords: ['appointment', 'vet visit', 'book', 'schedule', 'checkup'],
      replies: [
        'You can book a vet visit from the Explore tab: pick a '
            'veterinarian, choose a time, and add the reason for the '
            'visit. You\'ll get a notification once it\'s confirmed, and '
            'another reminder the day before.',
      ],
    ),
    _Rule(
      keywords: ['adopt', 'adoption', 'shelter', 'rescue'],
      replies: [
        'Adoptable pets are listed under Explore. Tap a pet you like and '
            'send an adoption request — the shelter admin will review it '
            'and you\'ll be notified as soon as it\'s approved or updated.',
      ],
    ),
    _Rule(
      keywords: ['food', 'feed', 'eat', 'diet', 'nutrition'],
      replies: [
        'Most adult dogs and cats do well on two measured meals a day; '
            'puppies and kittens usually need three to four smaller meals. '
            'Stick to a food formulated for their life stage, keep fresh '
            'water available, and avoid feeding table scraps, chocolate, '
            'onions, or grapes, which are toxic to pets.',
      ],
    ),
    _Rule(
      keywords: ['emergency', 'poison', 'bleeding', 'accident', 'urgent'],
      replies: [
        'If this is a real emergency, please call your nearest vet '
            'clinic or animal hospital right away — don\'t wait on a chat '
            'reply. Keep your pet calm and warm on the way there, and '
            'bring along any packaging if you suspect they ate something '
            'toxic.',
      ],
    ),
    _Rule(
      keywords: ['groom', 'bath', 'nail', 'fur', 'shed'],
      replies: [
        'Most dogs and cats do fine with a bath every 4-6 weeks, brushing '
            'a few times a week to control shedding, and a nail trim '
            'every 3-4 weeks. Long-haired breeds usually need more '
            'frequent brushing to prevent matting.',
      ],
    ),
    _Rule(
      keywords: [
        'how does this app',
        'how to use',
        'use this app',
        'use the app',
        'using this app',
        'using the app',
        'use this application',
        'using this application',
        'what is this app',
        'what does this app do',
        'purpose of this app',
        'yeh app kaise',
        'ye app kaise',
        'app kaise chal',
        'app kaise kaam',
        'app kaise use',
        'app kese chal',
        'app kese kaam',
        'app kese use',
        'app run kaise',
        'app run kese',
        'is app ke bare',
        'is app k bare',
        'about this app',
        'about the app',
      ],
      replies: [
        'PawfectCare ek pet-care app hai jo teen role handle karta hai: '
            'Pet Owner, Veterinarian, aur Shelter Admin. Sign up karte '
            'waqt apna role choose karo, uske baad tumhe waise hi home '
            'screen milegi. Neeche bottom bar mein 5 tabs hain: Home '
            '(dashboard aur quick actions), Explore (vets/adoptable pets '
            'dhoondo), Saved, Messages, aur Profile. Home screen pe '
            'role ke hisaab se cards milte hain — jaise Pet Owner ko My '
            'Pets, Health Records, Appointments, Pet Store, Adoption; Vet '
            'ko Today\'s Appointments, Patient History, Medical Records; '
            'Shelter Admin ko Pet Listings, Adoption Requests, Volunteer '
            'Requests. Aur ye orange chat button (jahan tum abhi mujh se '
            'baat kar rahe ho) kisi bhi screen se hamesha available '
            'rehta hai.',
      ],
    ),
    _Rule(
      keywords: [
        'signup',
        'sign up',
        'register kaise',
        'account kaise banau',
        'account kese banau',
      ],
      replies: [
        'Sign up screen pe naam, email, password aur apna role (Pet '
            'Owner, Veterinarian, ya Shelter Admin) select karo. Account '
            'banne ke baad seedha usi role ki home screen pe le jaya '
            'jayega. Role baad mein change nahi hota, isliye sahi select '
            'karna.',
      ],
    ),
    _Rule(
      keywords: ['login kaise', 'login kese', 'sign in kaise', 'sign in kese'],
      replies: [
        'App khulte hi login screen aati hai — jo email/password se sign '
            'up kiya tha wahi daal kar Login dabao. Password bhool gaye '
            'ho to "Forgot password" option se reset kar sakte ho.',
      ],
    ),
    _Rule(
      keywords: ['hello', 'hi', 'hey', 'salam', 'assalam'],
      replies: [
        'Hey! I\'m your PawfectCare assistant. Ask me about vaccinations, '
            'appointments, adoption, feeding, or anything else you\'re '
            'wondering about.',
      ],
    ),
    _Rule(
      keywords: ['thank', 'shukriya', 'thanks'],
      replies: ['Anytime! Let me know if anything else comes up.'],
    ),
  ];

  static const _fallbackReplies = [
    'I don\'t have a connected AI model right now, so I can\'t research '
        'that in depth, but I\'m happy to help with anything about your '
        'pets, appointments, vaccinations, or adoptions here in '
        'PawfectCare — what would you like to know?',
    'That\'s outside what I can look up offline at the moment. If it\'s '
        'about caring for your pet, tracking health records, or booking a '
        'vet visit, ask away and I\'ll do my best to help.',
  ];

  @override
  Future<String> ask(
    String question, {
    List<ChatMessage> history = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalized = question.toLowerCase();
    for (final rule in _rules) {
      if (rule.keywords.any((keyword) => _containsWord(normalized, keyword))) {
        return rule.replies[_random.nextInt(rule.replies.length)];
      }
    }
    return _fallbackReplies[_random.nextInt(_fallbackReplies.length)];
  }

  /// Matches [keyword] as a whole word/phrase inside [text], so short
  /// keywords like "hi" don't accidentally match inside words like "this".
  static bool _containsWord(String text, String keyword) {
    final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
    return pattern.hasMatch(text);
  }
}

class _Rule {
  const _Rule({required this.keywords, required this.replies});

  final List<String> keywords;
  final List<String> replies;
}
