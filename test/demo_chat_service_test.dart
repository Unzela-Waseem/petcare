import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/data/services/demo_chat_service.dart';

void main() {
  late DemoChatService service;

  setUp(() => service = DemoChatService());

  test('prioritizes toxic food as an emergency', () async {
    final reply = await service.ask('My dog ate chocolate');
    expect(reply, contains('emergency'));
    expect(reply, contains('do not induce vomiting'));
  });

  test('explains QR identity and lost-pet privacy', () async {
    final reply = await service.ask('How does QR pet identity work?');
    expect(reply, contains('LOST PET'));
    expect(reply, contains('not exposed publicly'));
  });

  test('explains complete adoption workflow', () async {
    final reply = await service.ask('What happens after an adoption request?');
    expect(reply, contains('approve or reject'));
    expect(reply, contains('handover'));
  });

  test('distinguishes patient history and medical records', () async {
    final reply = await service.ask('What is a medical record?');
    expect(reply, contains('diagnosis'));
    expect(reply, contains('Patient History'));
  });

  test('is honest about mobile push requirements', () async {
    final reply = await service.ask('Will notifications work on mobile?');
    expect(reply, contains('push backend'));
  });

  test('does not hallucinate for unknown questions', () async {
    final reply = await service.ask('Who won a football match yesterday?');
    expect(reply, contains('offline PawfectCare assistant'));
    expect(reply, contains('cannot search the web'));
  });
}
