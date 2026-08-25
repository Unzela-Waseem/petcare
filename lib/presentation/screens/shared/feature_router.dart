import 'package:flutter/material.dart';

import '../../../core/config/app_services.dart';
import '../../../domain/models/app_user.dart';
import '../adoption/adoption_screen.dart';
import '../adoption/shelter_operations_screen.dart';
import '../appointments/appointments_screen.dart';
import '../content/catalog_screens.dart';
import '../health/health_records_screen.dart';
import '../health/patient_history_screen.dart';
import '../pets/pets_screen.dart';
import 'contact_feedback_screen.dart';
import 'feature_catalog.dart';
import 'notifications_screen.dart';

abstract final class FeatureRouter {
  static void open(
    BuildContext context, {
    required FeatureAction feature,
    required AppUser user,
    required AppServices services,
    String initialQuery = '',
  }) {
    final page = switch (feature.title) {
      'My Pets' || 'Assigned Pets' => PetsScreen(
        user: user,
        services: services,
        initialQuery: initialQuery,
      ),
      'Health Records' || 'Medical Records' => HealthRecordsScreen(
        user: user,
        services: services,
        initialQuery: initialQuery,
      ),
      'Patient History' => PatientHistoryScreen(user: user, services: services),
      'Appointments' || "Today's Appointments" => AppointmentsScreen(
        user: user,
        services: services,
      ),
      'Calendar' => AvailabilityScreen(user: user, services: services),
      'Pet Store' => StoreScreen(
        user: user,
        services: services,
        initialQuery: initialQuery,
      ),
      'Care Tips' => CareTipsScreen(
        user: user,
        services: services,
        initialQuery: initialQuery,
      ),
      'Adoption' || 'Pet Listings' => AdoptionListingsScreen(
        user: user,
        services: services,
        initialQuery: initialQuery,
      ),
      'Adoption Requests' => AdoptionRequestsScreen(
        user: user,
        services: services,
      ),
      'Success Stories' => SuccessStoriesScreen(user: user, services: services),
      'Volunteer Requests' => CommunityRequestsScreen(
        user: user,
        services: services,
        module: CommunityModule.volunteer,
      ),
      'Contact Messages' => CommunityRequestsScreen(
        user: user,
        services: services,
        module: CommunityModule.contact,
      ),
      'Notifications' => NotificationsScreen(user: user, services: services),
      'Contact & Feedback' => ContactFeedbackScreen(
        user: user,
        services: services,
      ),
      _ => NotificationsScreen(user: user, services: services),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
