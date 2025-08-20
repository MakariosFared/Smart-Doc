# New Queue System for Smart Doc App

This document explains the updated queue system implementation for the Smart Doc Flutter application using the new Firestore structure.

## Overview

The new queue system automatically adds patients to a doctor's queue after they complete their medical survey. The system uses a simplified Firestore structure and provides real-time queue monitoring.

## New Firestore Structure

```
queues/
  {doctorId}/
    patients/
      {patientId}/
        {
          "patientId": "string",
          "patientName": "string",
          "doctorId": "string",
          "status": "waiting",
          "timestamp": "2024-01-01T10:00:00Z"
        }
```

## Key Changes from Previous Version

1. **Simplified Structure**: Uses `queues/{doctorId}/patients` instead of `doctors/{doctorId}/queue`
2. **No Queue Numbers**: Position is calculated dynamically based on timestamp order
3. **Automatic Integration**: Patients are automatically added to queue after survey completion
4. **Real-time Updates**: Uses Firebase streams for live queue monitoring

## Architecture

### Domain Layer

- **QueueEntry**: Core entity with patientName (no queueNumber)
- **QueueRepository**: Interface for queue operations
- **QueueStatus**: Enum (waiting, inProgress, done, cancelled)

### Data Layer

- **QueueEntryModel**: Data model with JSON serialization
- **FirebaseQueueRepositoryImpl**: Firebase implementation using new structure

### Presentation Layer

- **QueueCubit**: State management for queue operations
- **QueueDisplayPage**: Main queue monitoring page
- **QueueStatusPage**: Simple status page for patients not in queue

## Key Features

### 1. Automatic Queue Assignment

- Patient completes medical survey
- Automatically added to selected doctor's queue
- No manual queue joining required

### 2. Dynamic Position Calculation

- Queue position calculated based on timestamp order
- First patient to join = position 1
- Real-time position updates

### 3. Real-time Monitoring

- Firebase streams for live updates
- Automatic UI refresh when queue changes
- Patient can see their current position

### 4. Simple Queue Management

- Join queue automatically after survey
- Leave queue with confirmation
- View full queue list with current patient highlighted

## Implementation Details

### Survey Integration

```dart
// In survey_screen.dart
void _joinQueueAndCreateAppointment(...) async {
  // ... create appointment ...

  // Automatically add patient to queue
  final queueCubit = context.read<QueueCubit>();
  await queueCubit.joinQueue(
    doctorId,
    patientId,
    patientName,
  );

  // Navigate to queue display page
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => QueueDisplayPage(
        doctorId: doctorId,
        doctorName: null,
      ),
    ),
  );
}
```

### Queue Display Page

The `QueueDisplayPage` shows:

- Current queue status (in queue or not)
- Position number if in queue
- Full queue list with patient highlighting
- Join/Leave queue buttons

### Queue Status Page

The `QueueStatusPage` shows:

- Instructions for joining queue
- Navigation to book appointment
- General queue information

## Usage Flow

1. **Patient selects doctor** → Goes to appointment booking
2. **Patient fills survey** → Survey is submitted
3. **Automatic queue join** → Patient added to doctor's queue
4. **Navigate to queue page** → Shows current position and full queue
5. **Real-time updates** → Position updates automatically

## UI Components

### QueueDisplayPage

- **Status Card**: Shows if patient is in queue and their position
- **Queue List**: Full list of patients with current patient highlighted
- **Action Buttons**: Join/Leave queue based on current status

### QueueStatusPage

- **Info Card**: Welcome message and current status
- **Instructions**: Step-by-step guide to join queue
- **Action Buttons**: Navigate to booking or home

## Firebase Security Rules

Ensure your Firestore security rules allow:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /queues/{doctorId}/patients/{patientId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        (request.auth.uid == resource.data.patientId ||
         request.auth.uid == doctorId);
    }
  }
}
```

## Testing

The system includes:

- Comprehensive error handling
- Arabic error messages
- Network timeout handling
- State management testing
- UI component testing

## Dependencies

- `flutter_bloc`: State management
- `cloud_firestore`: Firebase integration
- `equatable`: Value equality
- `firebase_auth`: Authentication

## Getting Started

1. **Update Firebase Rules**: Use the new security rules above
2. **Add Queue Feature**: Import the queue feature in your app
3. **Wrap with BlocProvider**: Provide QueueCubit to your queue pages
4. **Test Survey Flow**: Complete a survey to test automatic queue joining
5. **Monitor Queue**: Use QueueDisplayPage to see real-time updates

## Migration from Old System

If you're upgrading from the previous queue system:

1. **Data Migration**: Export old queue data and import to new structure
2. **Update Imports**: Change import paths to use new queue system
3. **Test Integration**: Verify survey completion still works
4. **Update Navigation**: Ensure queue navigation points to new pages

## Future Enhancements

- **Estimated Wait Time**: Calculate based on queue position and doctor availability
- **Queue Priority**: Add priority system for urgent cases
- **Doctor Dashboard**: Show queue management interface for doctors
- **Push Notifications**: Notify patients when their turn approaches
- **Queue Analytics**: Track queue performance and patient flow

## Support

For questions or issues with the new queue system:

1. Check the Firebase console for data structure
2. Verify security rules are properly configured
3. Test the survey completion flow
4. Check console logs for error messages

## Example Usage

```dart
// Join queue automatically after survey
final queueCubit = context.read<QueueCubit>();
await queueCubit.joinQueue(doctorId, patientId, patientName);

// Listen to queue updates
queueCubit.listenToDoctorQueue(doctorId).listen((queueList) {
  // Update UI with new queue data
  setState(() {
    _queueList = queueList;
  });
});

// Get patient's position
final position = await queueCubit.getPatientQueuePositionNumber(
  doctorId,
  patientId
);
print('Patient is at position: $position');
```

This new system provides a much simpler and more intuitive queue experience for both patients and developers.
