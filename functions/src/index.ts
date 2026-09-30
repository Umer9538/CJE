import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: Send push notification when a new notification document is created
 * Triggers on: /notifications/{notificationId}
 */
export const sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId;

    if (!notificationData) {
      console.log("No notification data found");
      return null;
    }

    const userId = notificationData.userId;
    const title = notificationData.title || "CJE";
    const body = notificationData.body || "";
    const type = notificationData.type || "general";
    const data = notificationData.data || {};

    console.log(`Processing notification ${notificationId} for user ${userId}`);

    try {
      // Get the user's FCM token
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        console.log(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return null;
      }

      // Prepare the FCM message
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          notificationId: notificationId,
          type: type,
          itemId: data.itemId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            channelId: "cje_notifications",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      // Send the push notification
      const response = await messaging.send(message);
      console.log(`Push notification sent successfully: ${response}`);

      return response;
    } catch (error: unknown) {
      // Handle invalid token errors
      if (error instanceof Error && "code" in error) {
        const fcmError = error as { code: string };
        if (
          fcmError.code === "messaging/invalid-registration-token" ||
          fcmError.code === "messaging/registration-token-not-registered"
        ) {
          console.log(`Invalid FCM token for user ${userId}, removing token`);
          // Remove the invalid token from the user document
          await db.collection("users").doc(userId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        }
      }
      console.error("Error sending push notification:", error);
      return null;
    }
  });

/**
 * Cloud Function: Send push notification to multiple users (batch)
 * This is called via HTTPS when sending county-wide notifications
 */
export const sendBatchPushNotifications = functions.https.onCall(
  async (data, context) => {
    // Verify the caller is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to send notifications"
      );
    }

    const {userIds, title, body, type, itemId} = data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userIds must be a non-empty array"
      );
    }

    if (!title || !body) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "title and body are required"
      );
    }

    console.log(`Sending batch push to ${userIds.length} users`);

    // Get all user FCM tokens
    const userDocs = await Promise.all(
      userIds.map((userId: string) =>
        db.collection("users").doc(userId).get()
      )
    );

    const tokens: string[] = [];
    userDocs.forEach((doc) => {
      if (doc.exists) {
        const fcmToken = doc.data()?.fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        }
      }
    });

    if (tokens.length === 0) {
      console.log("No valid FCM tokens found");
      return {success: true, sent: 0};
    }

    // Send to all tokens using multicast
    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type || "general",
        itemId: itemId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          channelId: "cje_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    try {
      const response = await messaging.sendEachForMulticast(message);
      console.log(
        `Batch push sent: ${response.successCount} success, ` +
        `${response.failureCount} failures`
      );

      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const error = resp.error;
            if (
              error?.code === "messaging/invalid-registration-token" ||
              error?.code === "messaging/registration-token-not-registered"
            ) {
              failedTokens.push(tokens[idx]);
            }
          }
        });

        // Remove invalid tokens (in background)
        if (failedTokens.length > 0) {
          const batch = db.batch();
          const usersSnapshot = await db
            .collection("users")
            .where("fcmToken", "in", failedTokens)
            .get();

          usersSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, {
              fcmToken: admin.firestore.FieldValue.delete(),
            });
          });

          await batch.commit();
          console.log(`Removed ${failedTokens.length} invalid tokens`);
        }
      }

      return {
        success: true,
        sent: response.successCount,
        failed: response.failureCount,
      };
    } catch (error) {
      console.error("Error sending batch push:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notifications"
      );
    }
  }
);

/**
 * Cloud Function: Clean up old notifications (scheduled)
 * Runs daily to delete notifications older than 30 days
 */
export const cleanupOldNotifications = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );

    const oldNotifications = await db
      .collection("notifications")
      .where("createdAt", "<", thirtyDaysAgo)
      .limit(500)
      .get();

    if (oldNotifications.empty) {
      console.log("No old notifications to delete");
      return null;
    }

    const batch = db.batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${oldNotifications.size} old notifications`);

    return null;
  });

/**
 * Cloud Function: Quarterly content cleanup (scheduled)
 * Runs at midnight on the 1st of Jan, Apr, Jul, Oct
 * Deletes all announcements, meetings, polls, and initiatives older than 3 months
 * along with their related subcollection documents
 */
export const quarterlyContentCleanup = functions.pubsub
  .schedule("0 0 1 1,4,7,10 *")
  .timeZone("Europe/Bucharest")
  .onRun(async () => {
    const threeMonthsAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
    );

    const BATCH_SIZE = 500;
    const deletionCounts: Record<string, number> = {
      announcements: 0,
      meetings: 0,
      meeting_attendance: 0,
      polls: 0,
      poll_votes: 0,
      initiatives: 0,
      initiative_comments: 0,
      initiative_votes: 0,
    };

    /**
     * Delete documents in batches from a collection with a date filter
     * @param {string} collectionName - Firestore collection name
     * @param {string} dateField - Date field to filter on
     * @return {Promise<string[]>} IDs of deleted documents
     */
    async function deleteOldDocuments(
      collectionName: string,
      dateField: string
    ): Promise<string[]> {
      const deletedIds: string[] = [];
      let hasMore = true;

      while (hasMore) {
        const snapshot = await db
          .collection(collectionName)
          .where(dateField, "<", threeMonthsAgo)
          .limit(BATCH_SIZE)
          .get();

        if (snapshot.empty) {
          hasMore = false;
          break;
        }

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          deletedIds.push(doc.id);
          batch.delete(doc.ref);
        });

        await batch.commit();
        deletionCounts[collectionName] += snapshot.size;

        if (snapshot.size < BATCH_SIZE) {
          hasMore = false;
        }
      }

      return deletedIds;
    }

    /**
     * Delete related documents by a foreign key field
     * @param {string} collectionName - Firestore collection name
     * @param {string} foreignKeyField - Field referencing the parent document
     * @param {string[]} parentIds - IDs of parent documents to cascade from
     */
    async function deleteRelatedDocuments(
      collectionName: string,
      foreignKeyField: string,
      parentIds: string[]
    ): Promise<void> {
      for (const parentId of parentIds) {
        let hasMore = true;
        while (hasMore) {
          const snapshot = await db
            .collection(collectionName)
            .where(foreignKeyField, "==", parentId)
            .limit(BATCH_SIZE)
            .get();

          if (snapshot.empty) {
            hasMore = false;
            break;
          }

          const batch = db.batch();
          snapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          await batch.commit();
          deletionCounts[collectionName] += snapshot.size;

          if (snapshot.size < BATCH_SIZE) {
            hasMore = false;
          }
        }
      }
    }

    try {
      // 1. Delete old announcements (no subcollections)
      console.log("Cleaning up old announcements...");
      await deleteOldDocuments("announcements", "createdAt");

      // 2. Delete old meetings + cascade meeting_attendance
      console.log("Cleaning up old meetings...");
      const deletedMeetingIds = await deleteOldDocuments(
        "meetings",
        "createdAt"
      );
      if (deletedMeetingIds.length > 0) {
        await deleteRelatedDocuments(
          "meeting_attendance",
          "meetingId",
          deletedMeetingIds
        );
      }

      // 3. Delete old polls + cascade poll_votes
      console.log("Cleaning up old polls...");
      const deletedPollIds = await deleteOldDocuments("polls", "createdAt");
      if (deletedPollIds.length > 0) {
        await deleteRelatedDocuments(
          "poll_votes",
          "pollId",
          deletedPollIds
        );
      }

      // 4. Delete old initiatives + cascade comments and votes
      console.log("Cleaning up old initiatives...");
      const deletedInitiativeIds = await deleteOldDocuments(
        "initiatives",
        "createdAt"
      );
      if (deletedInitiativeIds.length > 0) {
        await deleteRelatedDocuments(
          "initiative_comments",
          "initiativeId",
          deletedInitiativeIds
        );
        await deleteRelatedDocuments(
          "initiative_votes",
          "initiativeId",
          deletedInitiativeIds
        );
      }

      console.log("Quarterly cleanup complete. Deletion counts:", deletionCounts);
      return null;
    } catch (error) {
      console.error("Error during quarterly cleanup:", error);
      return null;
    }
  });
