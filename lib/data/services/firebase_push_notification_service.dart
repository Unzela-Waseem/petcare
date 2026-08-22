import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_environment.dart';
import '../../domain/repositories/push_notification_service.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _uid;
  String? _deviceId;

  @override
  Future<void> startForUser(String uid) async {
    if (_uid == uid) return;
    try {
      await stop();
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _uid = uid;
      final token = await _messaging.getToken(
        vapidKey: AppEnvironment.fcmWebVapidKey.isEmpty
            ? null
            : AppEnvironment.fcmWebVapidKey,
      );
      if (token != null) await _saveToken(uid, token);
      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (token) => _saveToken(uid, token),
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen((_) {});
    } on Object {
      // Notification setup must never weaken or break the authenticated session.
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    final newDeviceId = sha256.convert(utf8.encode(token)).toString();
    final oldDeviceId = _deviceId;
    _deviceId = newDeviceId;
    if (oldDeviceId != null && oldDeviceId != newDeviceId) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(oldDeviceId)
          .delete();
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(newDeviceId)
        .set({
          'userId': uid,
          'token': token,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> stop() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    final uid = _uid;
    final deviceId = _deviceId;
    _uid = null;
    _deviceId = null;
    if (uid != null && deviceId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(deviceId)
            .delete();
      } on Object {
        // Best-effort token cleanup; server token expiry handling remains active.
      }
    }
  }
}
