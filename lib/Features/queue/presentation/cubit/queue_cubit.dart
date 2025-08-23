import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../data/repositories/queue_repository.dart';
import '../../data/models/queue_entry_model.dart';
import 'queue_state.dart';

class QueueCubit extends Cubit<QueueState> {
  final QueueRepository _queueRepository;
  StreamSubscription<List<QueueEntry>>? _queueSubscription;
  String? _currentDoctorId; // Track current doctor for reconnection

  QueueCubit({QueueRepository? queueRepository})
    : _queueRepository =
          queueRepository ?? AppDependencyInjection.queueRepository,
      super(const QueueInitial());

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    return super.close();
  }

  /// Start listening to real-time queue updates
  void startListeningToQueue(String doctorId) {
    if (doctorId.isEmpty) {
      emit(const QueueError('Doctor ID cannot be empty'));
      return;
    }

    // Stop previous subscription if exists
    _queueSubscription?.cancel();

    _currentDoctorId = doctorId;
    emit(const QueueLoading());

    print('🔄 Starting to listen to queue for doctor: $doctorId');

    _queueSubscription = _queueRepository
        .getQueueStream(doctorId)
        .listen(
          (entries) {
            try {
              if (entries.isEmpty) {
                emit(const QueueEmpty('لا يوجد مرضى في الطابور حالياً'));
              } else {
                // Filter out invalid entries
                final validEntries = entries.where((e) => e.isValid).toList();
                if (validEntries.isEmpty) {
                  emit(const QueueEmpty('لا يوجد مرضى صالحين في الطابور'));
                } else {
                  emit(QueueLoaded(validEntries));
                }
              }
            } catch (e) {
              print('❌ Error processing queue entries: $e');
              emit(QueueError('فشل في معالجة بيانات الطابور: $e'));
            }
          },
          onError: (error) {
            print('❌ Error in queue stream: $error');
            emit(QueueError('فشل في تحميل الطابور: $error'));
          },
        );
  }

  /// Stop listening to queue updates
  void stopListeningToQueue() {
    _queueSubscription?.cancel();
    _currentDoctorId = null;
    emit(const QueueInitial());
    print('🛑 Stopped listening to queue updates');
  }

  /// Reconnect to queue if connection was lost
  void reconnectToQueue() {
    if (_currentDoctorId != null) {
      print('🔄 Reconnecting to queue for doctor: $_currentDoctorId');
      startListeningToQueue(_currentDoctorId!);
    }
  }

  /// Update patient status
  Future<void> updatePatientStatus(
    String doctorId,
    String patientId,
    QueueStatus newStatus,
  ) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        emit(const QueueError('Doctor ID and Patient ID cannot be empty'));
        return;
      }

      emit(QueueActionInProgress('جاري تحديث حالة المريض...'));

      await _queueRepository.updatePatientStatus(
        doctorId,
        patientId,
        newStatus,
      );

      emit(QueueActionCompleted('تم تحديث حالة المريض بنجاح'));

      // Force refresh the queue to ensure immediate update
      if (_currentDoctorId == doctorId) {
        print('✅ Forcing queue refresh after status update');
        // Restart the stream to get fresh data
        _queueSubscription?.cancel();
        startListeningToQueue(doctorId);
      }

      // Clear the completed state after a delay to return to normal state
      Future.delayed(const Duration(seconds: 2), () {
        if (state is QueueActionCompleted) {
          // Only clear if we're still in completed state
          if (_currentDoctorId != null) {
            emit(QueueLoaded(getCurrentQueue()));
          }
        }
      });
    } catch (e) {
      print('❌ Error updating patient status: $e');
      emit(QueueError('فشل في تحديث حالة المريض: $e'));

      // Return to the last known good state after error
      Future.delayed(const Duration(seconds: 3), () {
        if (state is QueueError && _currentDoctorId != null) {
          // Try to restore the last known queue state
          final currentQueue = getCurrentQueue();
          if (currentQueue.isNotEmpty) {
            emit(QueueLoaded(currentQueue));
          } else {
            // If no current queue, restart listening
            startListeningToQueue(_currentDoctorId!);
          }
        }
      });
    }
  }

  /// Add patient to queue
  Future<void> addPatientToQueue(
    String doctorId,
    String patientId,
    String patientName,
  ) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty || patientName.isEmpty) {
        emit(const QueueError('جميع البيانات مطلوبة لإضافة المريض للطابور'));
        return;
      }

      emit(QueueActionInProgress('جاري إضافة المريض للطابور...'));

      await _queueRepository.addPatientToQueue(
        doctorId,
        patientId,
        patientName,
      );

      emit(QueueActionCompleted('تم إضافة المريض للطابور بنجاح'));

      // Force refresh the queue to ensure immediate update
      if (_currentDoctorId == doctorId) {
        print('✅ Forcing queue refresh after adding patient');
        _queueSubscription?.cancel();
        startListeningToQueue(doctorId);
      }

      // Clear the completed state after a delay to return to normal state
      Future.delayed(const Duration(seconds: 2), () {
        if (state is QueueActionCompleted) {
          // Only clear if we're still in completed state
          if (_currentDoctorId != null) {
            emit(QueueLoaded(getCurrentQueue()));
          }
        }
      });
    } catch (e) {
      print('❌ Error adding patient to queue: $e');
      emit(QueueError('فشل في إضافة المريض للطابور: $e'));
    }
  }

  /// Remove patient from queue
  Future<void> removePatientFromQueue(String doctorId, String patientId) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        emit(const QueueError('Doctor ID and Patient ID cannot be empty'));
        return;
      }

      emit(QueueActionInProgress('جاري إزالة المريض من الطابور...'));

      await _queueRepository.removePatientFromQueue(doctorId, patientId);

      emit(QueueActionCompleted('تم إزالة المريض من الطابور بنجاح'));

      // Force refresh the queue to ensure immediate update
      if (_currentDoctorId == doctorId) {
        print('✅ Forcing queue refresh after removing patient');
        _queueSubscription?.cancel();
        startListeningToQueue(doctorId);
      }

      // Clear the completed state after a delay to return to normal state
      Future.delayed(const Duration(seconds: 2), () {
        if (state is QueueActionCompleted) {
          // Only clear if we're still in completed state
          if (_currentDoctorId != null) {
            emit(QueueLoaded(getCurrentQueue()));
          }
        }
      });
    } catch (e) {
      print('❌ Error removing patient from queue: $e');
      emit(QueueError('فشل في إزالة المريض من الطابور: $e'));
    }
  }

  /// Get patient's current queue status
  Future<QueueEntry?> getPatientQueueStatus(
    String patientId,
    String doctorId,
  ) async {
    try {
      if (patientId.isEmpty || doctorId.isEmpty) {
        print('❌ Error: patientId and doctorId cannot be empty');
        return null;
      }

      return await _queueRepository.getPatientQueueStatus(patientId, doctorId);
    } catch (e) {
      print('❌ Error getting patient queue status: $e');
      emit(QueueError('فشل في جلب حالة المريض في الطابور: $e'));
      return null;
    }
  }

  /// Get current queue entries
  List<QueueEntry> getCurrentQueue() {
    if (state is QueueLoaded) {
      return (state as QueueLoaded).entries;
    }
    return [];
  }

  /// Manually refresh the queue data
  Future<void> refreshQueue() async {
    if (_currentDoctorId != null) {
      print('🔄 Manually refreshing queue for doctor: $_currentDoctorId');
      _queueSubscription?.cancel();
      startListeningToQueue(_currentDoctorId!);
    }
  }

  /// Get next patient in queue
  QueueEntry? getNextPatient() {
    final queue = getCurrentQueue();
    final waitingPatients = queue
        .where((entry) => entry.status == QueueStatus.waiting)
        .toList();

    if (waitingPatients.isNotEmpty) {
      // Sort by queue number if available
      waitingPatients.sort(
        (a, b) => (a.queueNumber ?? 0).compareTo(b.queueNumber ?? 0),
      );
      return waitingPatients.first;
    }
    return null;
  }

  /// Get current patient being served
  QueueEntry? getCurrentPatient() {
    final queue = getCurrentQueue();
    final inProgressPatients = queue
        .where((entry) => entry.status == QueueStatus.inProgress)
        .toList();

    if (inProgressPatients.isNotEmpty) {
      return inProgressPatients.first;
    }
    return null;
  }

  /// Get queue statistics
  Map<String, dynamic>? getQueueStatistics() {
    try {
      final queue = getCurrentQueue();
      if (queue.isEmpty) return null;

      final waitingCount = queue
          .where((e) => e.status == QueueStatus.waiting)
          .length;
      final inProgressCount = queue
          .where((e) => e.status == QueueStatus.inProgress)
          .length;
      final completedCount = queue
          .where((e) => e.status == QueueStatus.done)
          .length;
      final cancelledCount = queue
          .where((e) => e.status == QueueStatus.cancelled)
          .length;

      return {
        'totalPatients': queue.length,
        'waitingPatients': waitingCount,
        'inProgressPatients': inProgressCount,
        'completedPatients': completedCount,
        'cancelledPatients': cancelledCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error calculating queue statistics: $e');
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    if (state is QueueError) {
      if (_currentDoctorId != null) {
        // Try to reconnect
        reconnectToQueue();
      } else {
        emit(const QueueInitial());
      }
    }
  }

  /// Check if currently listening to a queue
  bool get isListening =>
      _queueSubscription != null && !_queueSubscription!.isPaused;

  /// Get current doctor ID being monitored
  String? get currentDoctorId => _currentDoctorId;
}
