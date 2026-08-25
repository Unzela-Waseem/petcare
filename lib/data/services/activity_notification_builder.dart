import '../../domain/models/app_user.dart';
import '../../domain/models/care_models.dart';
import '../../domain/models/pet.dart';
import '../../domain/models/user_role.dart';

const activityNotificationPrefix = 'activity:';

List<UserNotification> buildActivityNotifications({
  required AppUser user,
  required List<CareAppointment> appointments,
  required List<AdoptionRequest> adoptionRequests,
  required List<BlogArticle> blogs,
  required List<Pet> pets,
  required Map<String, List<HealthRecord>> healthRecords,
  required Set<String> readIds,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final petNames = {for (final pet in pets) pet.id: pet.name};
  final notifications = <UserNotification>[];

  for (final appointment in appointments.take(10)) {
    final id =
        '${activityNotificationPrefix}appointment:${appointment.id}:${appointment.status.value}';
    final isUpcoming =
        appointment.dateTime.isAfter(current) &&
        appointment.status != AppointmentStatus.cancelled &&
        appointment.status != AppointmentStatus.completed;
    final title = isUpcoming
        ? 'Upcoming appointment'
        : 'Appointment ${appointment.status.label.toLowerCase()}';
    final otherParty = user.role == UserRole.veterinarian
        ? appointment.petName
        : appointment.veterinarianName;
    notifications.add(
      _notification(
        id: id,
        title: title,
        body:
            '${appointment.petName} · $otherParty · ${_dateTime(appointment.dateTime)}',
        type: 'appointment',
        createdAt: appointment.dateTime,
        resourceId: appointment.id,
        readIds: readIds,
      ),
    );
  }

  for (final request in adoptionRequests.take(8)) {
    final id =
        '${activityNotificationPrefix}adoption:${request.id}:${request.status.value}';
    final title = user.role == UserRole.shelterAdmin
        ? request.status == RequestStatus.pending
              ? 'New adoption request'
              : 'Adoption request ${request.status.label.toLowerCase()}'
        : 'Adoption ${request.status.label.toLowerCase()}';
    final body = user.role == UserRole.shelterAdmin
        ? '${request.ownerName} applied to adopt ${request.petName}.'
        : '${request.petName}: your request is ${request.status.label.toLowerCase()}.';
    notifications.add(
      _notification(
        id: id,
        title: title,
        body: body,
        type: 'adoption',
        createdAt: request.createdAt,
        resourceId: request.id,
        readIds: readIds,
      ),
    );
  }

  final publishedBlogs = [...blogs]
    ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  for (final article in publishedBlogs.take(4)) {
    final id = '${activityNotificationPrefix}blog:${article.id}';
    notifications.add(
      _notification(
        id: id,
        title: 'New care guide',
        body: '${article.category} · ${article.title}',
        type: 'blog',
        createdAt: article.publishedAt,
        resourceId: article.id,
        readIds: readIds,
      ),
    );
  }

  final reminderLimit = current.add(const Duration(days: 90));
  for (final entry in healthRecords.entries) {
    final petName = petNames[entry.key];
    if (petName == null) continue;
    for (final record in entry.value) {
      final dueDate = record.dueDate;
      if (dueDate != null &&
          !dueDate.isBefore(current) &&
          !dueDate.isAfter(reminderLimit)) {
        final id =
            '${activityNotificationPrefix}health:${record.id}:due:${dueDate.millisecondsSinceEpoch}';
        notifications.add(
          _notification(
            id: id,
            title: '${record.type.label} due soon',
            body: '$petName · ${record.title} · ${_date(dueDate)}',
            type: record.type == HealthRecordType.vaccination
                ? 'vaccination'
                : 'health',
            createdAt: dueDate,
            resourceId: record.id,
            readIds: readIds,
          ),
        );
      }
      final followUp = record.followUpDate;
      if (followUp != null &&
          !followUp.isBefore(current) &&
          !followUp.isAfter(reminderLimit)) {
        final id =
            '${activityNotificationPrefix}health:${record.id}:follow-up:${followUp.millisecondsSinceEpoch}';
        notifications.add(
          _notification(
            id: id,
            title: 'Clinical follow-up due',
            body: '$petName · ${record.title} · ${_date(followUp)}',
            type: 'health',
            createdAt: followUp,
            resourceId: record.id,
            readIds: readIds,
          ),
        );
      }
    }
  }

  notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return notifications.take(30).toList(growable: false);
}

UserNotification _notification({
  required String id,
  required String title,
  required String body,
  required String type,
  required DateTime createdAt,
  required String resourceId,
  required Set<String> readIds,
}) => UserNotification(
  id: id,
  title: title,
  body: body,
  type: type,
  createdAt: createdAt,
  readAt: readIds.contains(id) ? createdAt : null,
  resourceId: resourceId,
);

String _dateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_date(value)} · $hour:$minute $period';
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
