import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_service.dart';

/// Safe, deterministic offline assistant used when the remote AI is unavailable.
/// It focuses on PawfectCare workflows and basic pet-care triage, and never
/// pretends to diagnose an illness.
class DemoChatService implements ChatService {
  DemoChatService();

  static const List<_Rule> _rules = [
    _Rule(
      keywords: [
        'emergency',
        'poison',
        'poisoning',
        'not breathing',
        'cant breathe',
        'cannot breathe',
        'heavy bleeding',
        'seizure',
        'unconscious',
        'collapse',
        'accident',
        'chocolate',
        'grapes',
        'raisins',
        'xylitol',
      ],
      reply:
          'This may be an emergency. Call the nearest veterinarian or animal hospital now—do not wait for a chat reply. Keep your pet calm, do not induce vomiting unless a vet tells you to, and take any food/medicine packaging with you. PawfectCare cannot diagnose an emergency.',
    ),
    _Rule(
      keywords: [
        'vomit',
        'vomiting',
        'diarrhea',
        'loose motion',
        'not eating',
        'lethargic',
        'fever',
        'cough',
        'itching',
        'allergy',
        'sick',
      ],
      reply:
          'Monitor when the symptom started, frequency, food and water intake, and any unusual exposure. Book a vet appointment and add these details as the visit reason. Seek urgent care for breathing trouble, collapse, blood, severe pain, repeated vomiting, or rapidly worsening symptoms. This guidance is not a diagnosis.',
    ),
    _Rule(
      keywords: [
        'qr',
        'scan code',
        'pet identity',
        'lost pet',
        'public profile',
      ],
      reply:
          'Open the pet or shelter listing and choose QR Identity. Generate the code, then scan it with another phone to open the pet\'s public safety profile. Lost-pet mode shows an urgent LOST PET alert and contact details. Medical/private owner data is not exposed publicly; disable or regenerate the QR if it is no longer needed.',
    ),
    _Rule(
      keywords: ['notification', 'notifications', 'reminder', 'alerts', 'bell'],
      reply:
          'The in-app Notifications screen shows role-specific updates: owners get appointment, adoption and care updates; vets get booking changes; shelters get adoption, volunteer and contact requests. Open an item to mark it read. System push alerts on a closed mobile app additionally require notification permission and a configured push backend.',
    ),
    _Rule(
      keywords: [
        'medical record',
        'health record',
        'diagnosis',
        'treatment',
        'prescription',
      ],
      reply:
          'A veterinarian creates the medical record after examining an assigned pet, including visit date, diagnosis, treatment and prescription/follow-up. The linked pet owner can then view that record in the pet\'s Health/Medical Records area. Patient History is the visit timeline; Medical Records holds the clinical details. Only authorized participants can access them.',
    ),
    _Rule(
      keywords: [
        'appointment',
        'vet visit',
        'book vet',
        'schedule',
        'reschedule',
        'cancel booking',
      ],
      reply:
          'For an appointment, choose your pet, veterinarian, an available future time, and the reason, then tap Book Securely. It starts pending until the vet confirms it. Reschedule requests a new slot; Cancel closes the booking. Both participants receive an in-app update. If no times appear, that vet must first publish availability.',
    ),
    _Rule(
      keywords: ['adopt', 'adoption request', 'request adoption', 'adoptable'],
      reply:
          'A pet owner opens an available listing, adds home details and sends an adoption request. It appears for the shelter that owns that listing. The shelter can approve or reject it, and the owner sees the updated status and notification. Approval records the match; the shelter should then complete handover and mark the listing adopted.',
    ),
    _Rule(
      keywords: ['volunteer', 'donate', 'donation'],
      reply:
          'A signed-in user submits the volunteer form with availability and experience; it goes to the selected shelter for review and status updates. Donation information should be confirmed directly with the shelter. PawfectCare must never collect card details in a normal message field.',
    ),
    _Rule(
      keywords: [
        'success story',
        'success stories',
        'gallery',
        'draft',
        'publish story',
      ],
      reply:
          'A Shelter Admin adds a title, adoption story and image. Save as Draft to keep it private for editing; choose Publish when it is complete. Only published stories appear in the public Success Stories gallery. Image upload needs a supported file and a working Cloudinary connection.',
    ),
    _Rule(
      keywords: ['pet listing', 'add pet', 'listing photo', 'shelter pet'],
      reply:
          'Shelter Admin → Pet Listings → Add Listing. Enter pet details, choose a clear photo, and publish it as Available. It then appears in owners\' Adoption results. Draft listings remain private; adopted or unavailable listings should not accept new requests.',
    ),
    _Rule(
      keywords: [
        'assigned pet',
        'assigned pets',
        'patient history',
        'vet dashboard',
      ],
      reply:
          'A pet becomes visible to a veterinarian when that vet has a valid appointment/clinical relationship with it. Assigned Pets is therefore not every pet in the system. The vet can open the pet, review authorized history, and add a record after the visit.',
    ),
    _Rule(
      keywords: ['contact message', 'inbox', 'message shelter', 'chat owner'],
      reply:
          'Contact messages create a private conversation between authenticated participants. The shelter sees owner enquiries in Contact Messages and can reply there. If the inbox is empty, first send a message from another signed-in role to that specific shelter.',
    ),
    _Rule(
      keywords: ['vaccine', 'vaccination', 'booster', 'deworm', 'shot'],
      reply:
          'Vaccination and deworming schedules depend on species, age, health and local veterinary guidance. Record the vaccine name, administered date and next due date in Medical Records, then use reminders. Ask your vet for the correct schedule rather than relying on a generic online timetable.',
    ),
    _Rule(
      keywords: ['food', 'feed', 'diet', 'nutrition', 'safe to eat'],
      reply:
          'Use a complete food made for your pet\'s species and life stage, measure portions, and keep fresh water available. Avoid chocolate, grapes/raisins, onion, garlic and xylitol. Ask a veterinarian before a major diet change, especially for young, elderly or unwell pets.',
    ),
    _Rule(
      keywords: ['groom', 'bath', 'nail', 'fur', 'shed'],
      reply:
          'Brush according to coat type, check skin and ears, and trim nails before they become overgrown. Use pet-safe products only. Pain, strong odor, redness, bald patches or persistent itching should be checked by a vet.',
    ),
    _Rule(
      keywords: [
        'role',
        'permission',
        'pet owner',
        'veterinarian',
        'shelter admin',
        'dashboard',
      ],
      reply:
          'PawfectCare has separate dashboards and permissions for Pet Owner, Veterinarian and Shelter Admin. The signup role is tied to the account to protect medical and shelter data; it cannot be casually switched. Use a different email/account to test each role.',
    ),
    _Rule(
      keywords: [
        'verify email',
        'verification email',
        'inbox verification',
        'not verified',
      ],
      reply:
          'Open the inbox of the email used at signup, click Firebase\'s verification link, return to PawfectCare and press I Have Verified. Check Spam and use Resend if needed. The password can be different, but should be strong and must never be shared.',
    ),
    _Rule(
      keywords: [
        'login',
        'sign in',
        'forgot password',
        'signup',
        'sign up',
        'register',
      ],
      reply:
          'Create an account with your real email, a strong password and the correct role, then verify the email. Sign in with the same credentials. Use Forgot Password for a reset link. One Firebase email represents one account, so separate role testing needs separate email aliases/accounts.',
    ),
    _Rule(
      keywords: [
        'search',
        'find vet',
        'find pet',
        'blog',
        'pet store',
        'filter',
      ],
      reply:
          'Use Explore/Search and enter a name, breed, species, clinic or product. Apply category filters to narrow results. Blogs provide general educational content, while Pet Store items are catalogue data; neither replaces professional veterinary advice.',
    ),
    _Rule(
      keywords: [
        'how to use',
        'how does this app',
        'app kaise',
        'app kese',
        'about this app',
      ],
      reply:
          'PawfectCare connects three roles: owners manage pets, bookings, records and adoption; veterinarians manage availability, appointments and clinical records; shelters manage listings, requests, volunteers and stories. Use Home quick actions or the drawer, Explore for discovery, and the bell for updates. Tell me the feature name and I\'ll give its exact flow.',
    ),
    _Rule(
      keywords: ['hello', 'hi', 'hey', 'salam', 'assalam'],
      reply:
          'Hello! I\'m the PawfectCare assistant. Ask me about pet symptoms, QR identity, appointments, medical records, adoption, shelter workflows or notifications.',
    ),
    _Rule(
      keywords: ['thank', 'shukriya', 'thanks'],
      reply:
          'You\'re welcome! Tell me the next PawfectCare feature or pet-care question you want help with.',
    ),
  ];

  static const String _fallback =
      'I am currently the offline PawfectCare assistant, so I cannot search the web or diagnose a pet. I can still guide you through appointments, QR identity, medical records, adoption, shelter listings, notifications, roles, vaccines and common pet-care safety. Please mention the feature or symptom clearly.';

  @override
  Future<String> ask(
    String question, {
    List<ChatMessage> history = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalized = _normalize(question);
    for (final rule in _rules) {
      if (rule.keywords.any(
        (keyword) => _containsPhrase(normalized, keyword),
      )) {
        return rule.reply;
      }
    }
    return _fallback;
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _containsPhrase(String text, String keyword) {
    final normalizedKeyword = _normalize(keyword);
    final pattern = RegExp(
      r'(^|\s)' + RegExp.escape(normalizedKeyword) + r'($|\s)',
    );
    return pattern.hasMatch(text);
  }
}

class _Rule {
  const _Rule({required this.keywords, required this.reply});

  final List<String> keywords;
  final String reply;
}
