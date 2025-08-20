import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_doc/Core/di/app_dependency_injection.dart';
import '../../data/repositories/queue_repository.dart';
import '../../data/models/queue_entry_model.dart';
import 'queue_state.dart';

class QueueCubit extends Cubit<QueueState> {
  final QueueRepository _queueRepository;
  StreamSubscription<QueueEntry?>? _queueSubscription;
  StreamSubscription<List<QueueEntry>>? _queueListSubscription;

  QueueCubit({QueueRepository? queueRepository})
    : _queueRepository =
          queueRepository ?? AppDependencyInjection.queueRepository,
      super(const QueueInitial());

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    _queueListSubscription?.cancel();
    return super.close();
  }

  /// Join a doctor's queue
  Future<void> joinQueue(
    String doctorId,
    String patientId,
    String patientName,
  ) async {
    try {
      emit(const QueueLoading());

      final queueEntry = await _queueRepository.joinQueue(
        doctorId,
        patientId,
        patientName,
      );
      emit(QueueJoined(queueEntry));

      // Start listening to queue updates
      _listenToQueueUpdates(doctorId, patientId);
      _listenToDoctorQueue(doctorId);
    } catch (e) {
      if (e is QueueException) {
        emit(QueueError(e.message, code: e.code));
      } else {
        emit(QueueError('فشل في الانضمام للطابور: $e'));
      }
    }
  }

  /// Leave the current queue
  Future<void> leaveQueue(String doctorId, String patientId) async {
    try {
      emit(const QueueLoading());

      await _queueRepository.leaveQueue(doctorId, patientId);

      // Cancel the subscriptions
      _queueSubscription?.cancel();
      _queueListSubscription?.cancel();

      emit(const QueueLeft());
    } catch (e) {
      if (e is QueueException) {
        emit(QueueError(e.message, code: e.code));
      } else {
        emit(QueueError('فشل في مغادرة الطابور: $e'));
      }
    }
  }

  /// Get current queue position for a patient
  Future<QueueEntry?> getPatientQueuePosition(
    String doctorId,
    String patientId,
  ) async {
    try {
      return await _queueRepository.getPatientQueuePosition(
        doctorId,
        patientId,
      );
    } catch (e) {
      if (e is QueueException) {
        emit(QueueError(e.message, code: e.code));
      } else {
        emit(QueueError('فشل في جلب موقع الطابور: $e'));
      }
      return null;
    }
  }

  /// Get patient's position number in queue
  Future<int> getPatientQueuePositionNumber(
    String doctorId,
    String patientId,
  ) async {
    try {
      return await _queueRepository.getPatientQueuePositionNumber(
        doctorId,
        patientId,
      );
    } catch (e) {
      if (e is QueueException) {
        emit(QueueError(e.message, code: e.code));
      } else {
        emit(QueueError('فشل في جلب رقم الطابور: $e'));
      }
      return -1;
    }
  }

  /// Get current queue length for a doctor
  Future<int> getQueueLength(String doctorId) async {
    try {
      return await _queueRepository.getQueueLength(doctorId);
    } catch (e) {
      if (e is QueueException) {
        emit(QueueError(e.message, code: e.code));
      } else {
        emit(QueueError('فشل في جلب طول الطابور: $e'));
      }
      return 0;
    }
  }

  /// Listen to queue updates for a specific patient
  void _listenToQueueUpdates(String doctorId, String patientId) {
    _queueSubscription?.cancel();

    _queueSubscription = _queueRepository
        .listenToQueueUpdates(doctorId, patientId)
        .listen(
          (queueEntry) {
            try {
              if (queueEntry != null) {
                emit(QueueUpdated(queueEntry));
              } else {
                // Patient is no longer in queue
                emit(const QueueLeft());
              }
            } catch (e) {
              print('Error in queue update listener: $e');
              emit(QueueError('خطأ في معالجة تحديث الطابور: $e'));
            }
          },
          onError: (error) {
            print('Error in queue update stream: $error');
            if (error is QueueException) {
              emit(QueueError(error.message, code: error.code));
            } else {
              emit(QueueError('خطأ في الاستماع لتحديثات الطابور: $error'));
            }
          },
        );
  }

  /// Listen to doctor's queue changes
  void _listenToDoctorQueue(String doctorId) {
    _queueListSubscription?.cancel();

    _queueListSubscription = _queueRepository
        .listenToDoctorQueue(doctorId)
        .listen(
          (queueList) {
            try {
              if (state is QueueJoined || state is QueueUpdated) {
                final currentEntry = currentQueueEntry;
                if (currentEntry != null) {
                  // Update the current entry with the latest data
                  try {
                    final updatedEntry = queueList.firstWhere(
                      (entry) => entry.patientId == currentEntry.patientId,
                    );
                    emit(QueueUpdated(updatedEntry));
                  } catch (e) {
                    // If patient is no longer in the queue, emit QueueLeft
                    print(
                      'Patient no longer found in queue: ${currentEntry.patientId}',
                    );
                    emit(const QueueLeft());
                  }
                }
              }
            } catch (e) {
              print('Error in doctor queue listener: $e');
              emit(QueueError('خطأ في معالجة تحديث طابور الدكتور: $e'));
            }
          },
          onError: (error) {
            print('Error in doctor queue stream: $error');
            if (error is QueueException) {
              emit(QueueError(error.message, code: error.code));
            } else {
              emit(QueueError('خطأ في الاستماع لتحديثات الطابور: $error'));
            }
          },
        );
  }

  /// Check if patient is currently in a queue
  bool get isInQueue => state is QueueJoined || state is QueueUpdated;

  /// Get current queue entry
  QueueEntry? get currentQueueEntry {
    if (state is QueueJoined) {
      return (state as QueueJoined).queueEntry;
    } else if (state is QueueUpdated) {
      return (state as QueueUpdated).queueEntry;
    }
    return null;
  }

  /// Get current queue status
  QueueStatus? get currentQueueStatus => currentQueueEntry?.status;

  /// Get current doctor ID
  String? get currentDoctorId => currentQueueEntry?.doctorId;

  /// Check if queue is loading
  bool get isLoading => state is QueueLoading;

  /// Check if there's an error
  bool get hasError => state is QueueError;

  /// Get error message
  String? get errorMessage {
    if (state is QueueError) {
      return (state as QueueError).message;
    }
    return null;
  }

  /// Clear error state
  void clearError() {
    try {
      if (state is QueueError) {
        // Try to restore previous state if possible
        if (currentQueueEntry != null) {
          emit(QueueUpdated(currentQueueEntry!));
        } else {
          emit(const QueueInitial());
        }
      }
    } catch (e) {
      print('Error clearing error state: $e');
      emit(const QueueInitial());
    }
  }

  /// Refresh queue status
  Future<void> refreshQueueStatus() async {
    try {
      if (currentQueueEntry != null) {
        final updatedEntry = await getPatientQueuePosition(
          currentQueueEntry!.doctorId,
          currentQueueEntry!.patientId,
        );

        if (updatedEntry != null) {
          emit(QueueUpdated(updatedEntry));
        } else {
          emit(const QueueLeft());
        }
      }
    } catch (e) {
      print('Error refreshing queue status: $e');
      emit(QueueError('فشل في تحديث حالة الطابور: $e'));
    }
  }

  /// Find all queues for a specific patient
  Future<List<QueueEntry>> findPatientQueues(String patientId) async {
    try {
      // This method would need to be implemented in the repository
      // For now, we'll return an empty list
      // TODO: Implement this when the repository supports it
      return [];
    } catch (e) {
      print('Error finding patient queues: $e');
      return [];
    }
  }
}
