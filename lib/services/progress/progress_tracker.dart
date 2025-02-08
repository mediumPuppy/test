import 'dart:async';

/// Abstract class defining the interface for tracking content progress
abstract class ProgressTracker {
  /// Stream of progress updates
  Stream<double> get progressStream;

  /// Current progress value between 0.0 and 1.0
  double get currentProgress;

  /// Whether the content is marked as completed
  bool get isCompleted;

  /// Update the progress value
  Future<void> updateProgress(double progress);

  /// Mark the content as completed
  Future<void> markCompleted();

  /// Reset progress to initial state
  Future<void> reset();

  /// Clean up resources
  void dispose();
}
