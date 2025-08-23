const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Listen for changes in queue documents
exports.onQueueStatusChange = functions.firestore
  .document('queues/{doctorId}/patients/{patientId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();
    const { doctorId, patientId } = context.params;

    console.log(`🔄 Queue status change detected for patient ${patientId} in doctor ${doctorId}'s queue`);

    // Check if status has changed
    if (newData.status === previousData.status) {
      console.log('ℹ️ Status unchanged, skipping notification');
      return null;
    }

    // Validate required data
    if (!newData.status || !patientId || !doctorId) {
      console.error('❌ Missing required data for notification');
      return null;
    }

    try {
      console.log(`🔄 Processing status change: ${previousData.status} -> ${newData.status}`);

      // Get patient's FCM token
      const patientDoc = await admin.firestore()
        .collection('users')
        .doc(patientId)
        .get();

      if (!patientDoc.exists) {
        console.log(`❌ Patient document not found: ${patientId}`);
        return null;
      }

      const patientData = patientDoc.data();
      const fcmToken = patientData.fcmToken;

      if (!fcmToken) {
        console.log(`⚠️ No FCM token found for patient: ${patientId}`);
        return null;
      }

      // Prepare notification message based on status
      const notification = prepareNotification(newData.status, patientData.name);
      
      console.log(`📱 Preparing notification: ${notification.title} - ${notification.body}`);

      // Send push notification
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          doctorId: doctorId,
          patientId: patientId,
          status: newData.status,
          queueNumber: newData.queueNumber?.toString() || '',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'queue_update',
          timestamp: new Date().toISOString(),
        },
        android: {
          notification: {
            channelId: 'clinic_queue',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_notification',
            color: '#4CAF50',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              category: 'QUEUE_UPDATE',
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Notification sent successfully: ${response}`);
      
      // Log the notification in Firestore
      await admin.firestore()
        .collection('notifications')
        .add({
          patientId: patientId,
          doctorId: doctorId,
          status: newData.status,
          title: notification.title,
          body: notification.body,
          fcmToken: fcmToken,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          success: true,
          messageId: response,
          previousStatus: previousData.status,
          newStatus: newData.status,
        });

      return response;
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      
      // Log the error in Firestore
      try {
        await admin.firestore()
          .collection('notifications')
          .add({
            patientId: patientId,
            doctorId: doctorId,
            status: newData.status,
            error: error.message,
            errorCode: error.code,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            success: false,
            previousStatus: previousData.status,
            newStatus: newData.status,
          });
      } catch (logError) {
        console.error('❌ Failed to log error to Firestore:', logError);
      }
      
      throw error;
    }
  });

// Helper function to prepare notification content
function prepareNotification(status, patientName) {
  const patientNameDisplay = patientName || 'المريض';
  
  switch (status) {
    case 'waiting':
      return {
        title: 'تم إضافتك للطابور',
        body: `مرحباً ${patientNameDisplay}، تم إضافتك للطابور بنجاح`,
      };
    case 'inProgress':
      return {
        title: 'دورك الآن',
        body: `مرحباً ${patientNameDisplay}، يرجى التوجه إلى الدكتور، دورك قد حان`,
      };
    case 'done':
      return {
        title: 'تم إكمال الموعد',
        body: `مرحباً ${patientNameDisplay}، تم إكمال موعدك بنجاح، نتمنى لك الشفاء العاجل`,
      };
    case 'cancelled':
      return {
        title: 'تم إلغاء الموعد',
        body: `مرحباً ${patientNameDisplay}، تم إلغاء موعدك، يرجى التواصل مع العيادة لإعادة الجدولة`,
      };
    default:
      return {
        title: 'تحديث حالة الموعد',
        body: `مرحباً ${patientNameDisplay}، تم تحديث حالة موعدك إلى: ${status}`,
      };
  }
}

// Function to send custom notifications
exports.sendCustomNotification = functions.https.onCall(async (data, context) => {
  // Verify the request is from an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { patientId, title, body, data: customData } = data;

  // Validate input data
  if (!patientId || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: patientId, title, body');
  }

  try {
    console.log(`🔄 Sending custom notification to patient ${patientId}`);

    // Get patient's FCM token
    const patientDoc = await admin.firestore()
      .collection('users')
      .doc(patientId)
      .get();

    if (!patientDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Patient not found');
    }

    const patientData = patientDoc.data();
    const fcmToken = patientData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'No FCM token found for patient');
    }

    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...customData,
        type: 'custom_notification',
        timestamp: new Date().toISOString(),
        sentBy: context.auth.uid,
      },
      android: {
        notification: {
          channelId: 'clinic_queue',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Custom notification sent successfully: ${response}`);

    // Log the custom notification
    await admin.firestore()
      .collection('notifications')
      .add({
        patientId: patientId,
        title: title,
        body: body,
        fcmToken: fcmToken,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        messageId: response,
        type: 'custom',
        sentBy: context.auth.uid,
        customData: customData || {},
      });

    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending custom notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to send bulk notifications to multiple patients
exports.sendBulkNotifications = functions.https.onCall(async (data, context) => {
  // Verify the request is from an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { patientIds, title, body, data: customData } = data;

  // Validate input data
  if (!patientIds || !Array.isArray(patientIds) || patientIds.length === 0 || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: patientIds (array), title, body');
  }

  if (patientIds.length > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Cannot send to more than 100 patients at once');
  }

  try {
    console.log(`🔄 Sending bulk notifications to ${patientIds.length} patients`);

    const results = [];
    const errors = [];

    // Process each patient
    for (const patientId of patientIds) {
      try {
        // Get patient's FCM token
        const patientDoc = await admin.firestore()
          .collection('users')
          .doc(patientId)
          .get();

        if (!patientDoc.exists) {
          errors.push({ patientId, error: 'Patient not found' });
          continue;
        }

        const patientData = patientDoc.data();
        const fcmToken = patientData.fcmToken;

        if (!fcmToken) {
          errors.push({ patientId, error: 'No FCM token found' });
          continue;
        }

        // Send notification
        const message = {
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: {
            ...customData,
            type: 'bulk_notification',
            timestamp: new Date().toISOString(),
            sentBy: context.auth.uid,
          },
        };

        const response = await admin.messaging().send(message);
        results.push({ patientId, success: true, messageId: response });

        // Log the notification
        await admin.firestore()
          .collection('notifications')
          .add({
            patientId: patientId,
            title: title,
            body: body,
            fcmToken: fcmToken,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            success: true,
            messageId: response,
            type: 'bulk',
            sentBy: context.auth.uid,
            customData: customData || {},
          });

      } catch (error) {
        console.error(`❌ Error sending notification to patient ${patientId}:`, error);
        errors.push({ patientId, error: error.message });
      }
    }

    console.log(`✅ Bulk notifications completed. Success: ${results.length}, Errors: ${errors.length}`);

    return {
      success: true,
      totalPatients: patientIds.length,
      successful: results.length,
      failed: errors.length,
      results: results,
      errors: errors,
    };
  } catch (error) {
    console.error('❌ Error in bulk notifications:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to clean up old notifications
exports.cleanupOldNotifications = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    console.log('🧹 Starting cleanup of old notifications');

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('sentAt', '<', thirtyDaysAgo)
      .limit(500) // Process in batches
      .get();

    if (snapshot.empty) {
      console.log('ℹ️ No old notifications to clean up');
      return null;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ Cleaned up ${snapshot.docs.length} old notifications`);

    return null;
  } catch (error) {
    console.error('❌ Error during notification cleanup:', error);
    return null;
  }
});
