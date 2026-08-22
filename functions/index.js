const {initializeApp} = require("firebase-admin/app");
const {FieldValue, Timestamp, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {setGlobalOptions} = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

initializeApp();
setGlobalOptions({region: "asia-south1", maxInstances: 10});

const db = getFirestore();

async function preferencesAllow(uid, preference) {
  const user = await db.doc(`users/${uid}`).get();
  if (!user.exists || user.get("accountStatus") !== "active") return false;
  const preferences = user.get("notificationPreferences");
  return !preferences || preferences[preference] !== false;
}

async function saveNotification(uid, notification, notificationId) {
  const reference = notificationId ?
    db.doc(`notifications/${uid}/items/${notificationId}`) :
    db.collection(`notifications/${uid}/items`).doc();
  const data = {
    title: notification.title,
    body: notification.body,
    type: notification.type,
    resourceId: notification.resourceId || null,
    readAt: null,
    createdAt: FieldValue.serverTimestamp(),
  };
  if (!notificationId) {
    await reference.set(data);
    return reference.id;
  }
  try {
    await reference.create(data);
    return reference.id;
  } catch (error) {
    if (error.code === 6 || error.code === "already-exists") return null;
    throw error;
  }
}

async function sendPush(uid, notification) {
  const snapshot = await db.collection(`users/${uid}/devices`).get();
  if (snapshot.empty) return;
  const documents = snapshot.docs.filter((document) => document.get("token"));
  for (let start = 0; start < documents.length; start += 500) {
    const chunk = documents.slice(start, start + 500);
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk.map((document) => document.get("token")),
      notification: {title: notification.title, body: notification.body},
      data: {
        type: notification.type,
        resourceId: notification.resourceId || "",
      },
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
    const invalid = [];
    response.responses.forEach((result, index) => {
      if (!result.success && [
        "messaging/invalid-registration-token",
        "messaging/registration-token-not-registered",
      ].includes(result.error?.code)) {
        invalid.push(chunk[index].ref.delete());
      }
    });
    await Promise.all(invalid);
  }
}

async function notify(uid, preference, notification, notificationId) {
  if (!uid || !(await preferencesAllow(uid, preference))) return;
  const savedId = await saveNotification(uid, notification, notificationId);
  if (savedId === null) return;
  try {
    await sendPush(uid, notification);
  } catch (error) {
    logger.error("FCM delivery failed", {uid, type: notification.type, error});
  }
}

exports.onAppointmentCreated = onDocumentCreated(
    "appointments/{appointmentId}",
    async (event) => {
      const appointment = event.data.data();
      const resourceId = event.params.appointmentId;
      await Promise.all([
        notify(appointment.ownerId, "appointments", {
          title: "Appointment requested",
          body: `${appointment.petName}'s visit with ${appointment.veterinarianName} is pending.`,
          type: "appointment",
          resourceId,
        }),
        notify(appointment.veterinarianId, "appointments", {
          title: "New appointment request",
          body: `${appointment.petName}: ${appointment.reason}`,
          type: "appointment",
          resourceId,
        }),
      ]);
    },
);

exports.onAppointmentUpdated = onDocumentUpdated(
    "appointments/{appointmentId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (before.status === after.status) return;
      await notify(after.ownerId, "appointments", {
        title: "Appointment updated",
        body: `${after.petName}'s appointment is now ${after.status}.`,
        type: "appointment",
        resourceId: event.params.appointmentId,
      });
    },
);

exports.onAdoptionRequestCreated = onDocumentCreated(
    "adoptionRequests/{requestId}",
    async (event) => {
      const request = event.data.data();
      await notify(request.shelterAdminId, "adoption", {
        title: "New adoption request",
        body: `${request.ownerName} wants to adopt ${request.petName}.`,
        type: "adoption",
        resourceId: event.params.requestId,
      });
    },
);

exports.onAdoptionRequestUpdated = onDocumentUpdated(
    "adoptionRequests/{requestId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (before.status === after.status) return;
      await notify(after.ownerId, "adoption", {
        title: "Adoption request updated",
        body: `Your request for ${after.petName} is now ${after.status}.`,
        type: "adoption",
        resourceId: event.params.requestId,
      });
    },
);

async function notifyBlogSubscribers(article, blogId, eventId) {
  const users = await db.collection("users")
      .where("accountStatus", "==", "active")
      .get();
  await Promise.all(users.docs.map((user) => notify(user.id, "blogs", {
    title: "New pet care tip",
    body: article.title,
    type: "blog",
    resourceId: blogId,
  }, `blog-${blogId}-${eventId}`)));
}

exports.onBlogPublished = onDocumentCreated("blogs/{blogId}", async (event) => {
  const article = event.data.data();
  if (article.published !== true) return;
  await notifyBlogSubscribers(article, event.params.blogId, event.id);
});

exports.onBlogUpdated = onDocumentUpdated("blogs/{blogId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const becamePublished = before.published !== true && after.published === true;
  const publishedContentChanged = after.published === true && (
    before.title !== after.title || before.content !== after.content
  );
  if (!becamePublished && !publishedContentChanged) return;
  await notifyBlogSubscribers(after, event.params.blogId, event.id);
});

exports.sendDueReminders = onSchedule(
    {schedule: "every 1 hours", timeZone: "Asia/Karachi"},
    async () => {
      const now = Timestamp.now();
      const tomorrow = Timestamp.fromMillis(now.toMillis() + 24 * 60 * 60 * 1000);
      const appointments = await db.collection("appointments")
          .where("status", "in", ["pending", "confirmed"])
          .where("dateTime", ">", now)
          .where("dateTime", "<=", tomorrow)
          .get();
      const appointmentJobs = appointments.docs.flatMap((document) => {
        const appointment = document.data();
        const notification = {
          title: "Appointment reminder",
          body: `${appointment.petName}'s visit is within the next 24 hours.`,
          type: "appointment",
          resourceId: document.id,
        };
        return [
          notify(
              appointment.ownerId,
              "appointments",
              notification,
              `appointment-${document.id}-24h`,
          ),
          notify(
              appointment.veterinarianId,
              "appointments",
              notification,
              `appointment-${document.id}-24h`,
          ),
        ];
      });

      const vaccinations = await db.collection("petHealthRecords")
          .where("type", "==", "vaccination")
          .where("dueDate", ">", now)
          .where("dueDate", "<=", tomorrow)
          .get();
      const vaccineJobs = vaccinations.docs.map(async (record) => {
        const petId = record.get("petId");
        const pet = await db.doc(`pets/${petId}`).get();
        if (!pet.exists) return;
        await notify(pet.get("ownerId"), "vaccinations", {
          title: "Vaccination reminder",
          body: `${pet.get("name")}'s ${record.get("title")} is due within 24 hours.`,
          type: "vaccination",
          resourceId: record.id,
        }, `vaccination-${record.id}-24h`);
      });
      await Promise.all([...appointmentJobs, ...vaccineJobs]);
    },
);
