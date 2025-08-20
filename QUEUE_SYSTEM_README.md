# Queue System for Smart Doc App

This document explains the queue system implementation for the Smart Doc Flutter application.

## Overview

The queue system allows patients to join a doctor's queue after completing their medical survey. The system automatically manages queue numbers, status updates, and real-time notifications.

## Architecture

### Domain Layer

- **QueueEntry**: Core entity representing a patient in a doctor's queue
- **QueueRepository**: Abstract interface for queue operations
- **QueueStatus**: Enum for queue statuses (waiting, in-progress, done, cancelled)

### Data Layer

- **QueueEntryModel**: Data model with JSON serialization
- **FirebaseQueueRepositoryImpl**: Firebase implementation of the repository

### Presentation Layer

- **QueueCubit**: State management for queue operations
- **QueueState**: States for different queue operations
- **QueuePage**: Main UI for queue management
- **QueueStatusCard**: Reusable widget for displaying queue status

## Firebase Structure

```
doctors/
  {doctorId}/
    queue/
      {queueEntryId}/
        {
          "patientId": "string",
          "doctorId": "string",
          "queueNumber": 1,
          "status": "waiting",
          "timestamp": "2024-01-01T10:00:00Z",
          "updatedAt": "2024-01-01T10:30:00Z"
        }
```

## Key Features

### 1. Automatic Queue Assignment

- When a patient completes a survey, they are automatically added to the doctor's queue
- Queue numbers are auto-incremented based on current queue length
- Prevents duplicate entries for the same patient

### 2. Real-time Updates

- Uses Firebase streams to listen for queue changes
- Automatically updates UI when queue status changes
- Supports multiple patients monitoring the same queue

### 3. Queue Management

- Join queue with automatic number assignment
- Leave queue with confirmation dialog
- Update queue status (waiting → in-progress → done)
- Refresh queue status manually

### 4. Status Tracking

- **waiting**: Patient is in queue, waiting for their turn
- **in-progress**: Patient is currently being seen by the doctor
- **done**: Patient's appointment is completed
- **cancelled**: Patient left the queue

## Usage Examples

### Joining a Queue

```dart
// In your Cubit or Bloc
final queueCubit = context.read<QueueCubit>();
await queueCubit.joinQueue(doctorId, patientId);
```

### Listening to Queue Updates

```dart
// The Cubit automatically listens to updates
BlocBuilder<QueueCubit, QueueState>(
  builder: (context, state) {
    if (state is QueueUpdated) {
      final queueEntry = state.queueEntry;
      return Text('Queue #${queueEntry.queueNumber} - ${queueEntry.statusDisplayName}');
    }
    return Container();
  },
);
```

### Leaving a Queue

```dart
final queueCubit = context.read<QueueCubit>();
await queueCubit.leaveQueue(doctorId, patientId);
```

## Integration with Survey System

The queue system automatically integrates with the survey system:

1. Patient completes medical survey
2. Survey is saved to Firebase
3. Patient is automatically added to doctor's queue
4. Queue status is displayed in real-time
5. Patient can monitor their position and status

## UI Components

### QueueStatusCard

A beautiful card widget that displays:

- Queue number
- Join time
- Current status with color-coded indicators
- Leave queue button

### QueuePage

Main page that shows:

- Current queue status (if in queue)
- Join queue form (if not in queue)
- Doctor information
- Queue actions and information

## Error Handling

The system includes comprehensive error handling:

- Firebase connection errors
- Permission denied errors
- Network timeout errors
- User-friendly Arabic error messages

## Security Rules

Ensure your Firebase security rules allow:

- Patients to read/write their own queue entries
- Doctors to read their queue
- Only authenticated users to access queue data

Example Firebase rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /doctors/{doctorId}/queue/{queueId} {
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

- Mock implementations for testing
- Comprehensive error scenarios
- State management testing
- UI widget testing

## Future Enhancements

- Estimated wait time calculations
- Queue priority system
- Doctor availability integration
- Push notifications for queue updates
- Queue analytics and reporting

## Dependencies

- `flutter_bloc`: State management
- `cloud_firestore`: Firebase integration
- `equatable`: Value equality
- `firebase_auth`: Authentication

## Getting Started

1. Ensure Firebase is properly configured
2. Add the queue feature to your app
3. Wrap your queue pages with `BlocProvider<QueueCubit>`
4. Use the provided UI components
5. Test the integration with your survey system

## Support

For questions or issues with the queue system, please refer to the code comments or create an issue in the project repository.
