import 'package:equatable/equatable.dart';
import 'package:smart_doc/Features/queue/data/models/queue_entry_model.dart';

abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class QueueInitial extends QueueState {
  const QueueInitial();
}

/// Loading state
class QueueLoading extends QueueState {
  const QueueLoading();
}

/// Queue loaded successfully
class QueueLoaded extends QueueState {
  final List<QueueEntry> entries;

  const QueueLoaded(this.entries);

  @override
  List<Object?> get props => [entries];
}

/// Queue empty state
class QueueEmpty extends QueueState {
  final String message;

  const QueueEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

/// Queue action in progress
class QueueActionInProgress extends QueueState {
  final String message;

  const QueueActionInProgress(this.message);

  @override
  List<Object?> get props => [message];
}

/// Queue action completed successfully
class QueueActionCompleted extends QueueState {
  final String message;

  const QueueActionCompleted(this.message);

  @override
  List<Object?> get props => [message];
}

/// Patient successfully joined queue
class QueueJoined extends QueueState {
  final QueueEntry queueEntry;

  const QueueJoined(this.queueEntry);

  @override
  List<Object?> get props => [queueEntry];
}

/// Queue updated (status or position changed)
class QueueUpdated extends QueueState {
  final QueueEntry queueEntry;

  const QueueUpdated(this.queueEntry);

  @override
  List<Object?> get props => [queueEntry];
}

/// Patient left queue
class QueueLeft extends QueueState {
  const QueueLeft();
}

/// Error state
class QueueError extends QueueState {
  final String message;
  final String? code;

  const QueueError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
