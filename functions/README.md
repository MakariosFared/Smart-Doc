# Firebase Cloud Functions for Clinic Queue Management

This directory contains Firebase Cloud Functions that handle push notifications for the clinic queue management system.

## Features

- **Real-time Queue Status Notifications**: Automatically sends FCM notifications when patient queue status changes
- **Custom Notifications**: Allows sending custom notifications to specific patients
- **Comprehensive Logging**: Logs all notification attempts and results in Firestore

## Functions

### 1. `onQueueStatusChange`

- **Trigger**: Firestore document update in `queues/{doctorId}/patients/{patientId}`
- **Purpose**: Automatically sends push notifications when patient status changes
- **Notifications Sent**:
  - `inProgress` → "دورك الآن - يرجى التوجه إلى الدكتور، دورك قد حان"
  - `done` → "تم إكمال الموعد - تم إكمال موعدك بنجاح، نتمنى لك الشفاء العاجل"
  - `cancelled` → "تم إلغاء الموعد - تم إلغاء موعدك، يرجى التواصل مع العيادة لإعادة الجدولة"

### 2. `sendCustomNotification`

- **Trigger**: HTTPS callable function
- **Purpose**: Allows sending custom notifications to specific patients
- **Authentication**: Requires user authentication

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onQueueStatusChange
```

### 3. Verify Deployment

```bash
firebase functions:list
```

## Firestore Structure

The functions expect the following Firestore structure:

```
users/{patientId}
├── name: string
├── fcmToken: string
├── role: string
└── currentQueueStatus: string

queues/{doctorId}/patients/{patientId}
├── patientId: string
├── patientName: string
├── queueNumber: number
├── status: string (waiting, inProgress, done, cancelled)
├── joinedAt: timestamp
└── updatedAt: timestamp

notifications/{notificationId}
├── patientId: string
├── doctorId: string
├── status: string
├── title: string
├── body: string
├── fcmToken: string
├── sentAt: timestamp
└── success: boolean
```

## Security Rules

The functions work with the following Firestore security rules:

- Users can read/write their own data
- Doctors can read basic info of all users
- Doctors can manage their own queues
- Patients can only read their own queue entries
- Notifications collection is read-only for users (only Cloud Functions can write)

## Testing

### Local Testing

```bash
# Start Firebase emulator
firebase emulators:start --only functions

# Test function locally
curl -X POST http://localhost:5001/your-project/us-central1/onQueueStatusChange
```

### Production Testing

1. Update a patient's status in Firestore
2. Check the function logs: `firebase functions:log`
3. Verify notification delivery in the patient's app

## Troubleshooting

### Common Issues

1. **Function not triggering**: Check if the Firestore document path matches exactly
2. **Notification not sent**: Verify the patient has a valid FCM token
3. **Permission denied**: Ensure Firestore security rules allow the operation

### Logs

```bash
# View function logs
firebase functions:log --only onQueueStatusChange

# View real-time logs
firebase functions:log --only onQueueStatusChange --follow
```

## Monitoring

Monitor function performance and errors in the Firebase Console:

1. Go to Functions > Logs
2. Check for errors and performance metrics
3. Set up alerts for function failures

## Cost Optimization

- Functions are billed per invocation
- Consider implementing rate limiting for high-traffic clinics
- Monitor function execution times and optimize if needed
