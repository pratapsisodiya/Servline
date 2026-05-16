import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servline/providers/auth_provider.dart';
import 'package:servline/repositories/feedback_repository.dart';

/// Feedback state
class FeedbackState {
  final int selectedRating;
  final String notes;
  final List<String> selectedTags;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;

  const FeedbackState({
    this.selectedRating = 0,
    this.notes = '',
    this.selectedTags = const [],
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.error,
  });

  FeedbackState copyWith({
    int? selectedRating,
    String? notes,
    List<String>? selectedTags,
    bool? isSubmitting,
    bool? isSubmitted,
    String? error,
  }) {
    return FeedbackState(
      selectedRating: selectedRating ?? this.selectedRating,
      notes: notes ?? this.notes,
      selectedTags: selectedTags ?? this.selectedTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      error: error,
    );
  }
}

/// Feedback Notifier
class FeedbackNotifier extends Notifier<FeedbackState> {
  @override
  FeedbackState build() {
    return const FeedbackState();
  }

  FeedbackRepository get _feedbackRepo => ref.read(feedbackRepositoryProvider);

  /// Set rating
  void setRating(int rating) {
    state = state.copyWith(selectedRating: rating);
  }

  /// Set notes
  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  /// Toggle tag
  void toggleTag(String tag) {
    final currentTags = List<String>.from(state.selectedTags);
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }
    state = state.copyWith(selectedTags: currentTags);
  }

  /// Submit feedback
  Future<bool> submitFeedback({
    required String ticketId,
    required String locationId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    if (state.selectedRating == 0) {
      state = state.copyWith(error: 'Please select a rating');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _feedbackRepo.submitFeedback(
        userId: user.id,
        ticketId: ticketId,
        locationId: locationId,
        rating: state.selectedRating,
        notes: state.notes.isNotEmpty ? state.notes : null,
        tags: state.selectedTags,
      );

      state = state.copyWith(isSubmitting: false, isSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Reset feedback state
  void reset() {
    state = const FeedbackState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Feedback provider
final feedbackProvider = NotifierProvider<FeedbackNotifier, FeedbackState>(
  FeedbackNotifier.new,
);
