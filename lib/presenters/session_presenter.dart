import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'home_presenter.dart';

class SessionState {
  final UserModel helper;
  final DateTime? selectedDate;
  final int selectedDuration;
  final String? selectedCategory;
  final bool isLoading;
  final SessionModel? bookedSession;
  final String? error;

  const SessionState({
    required this.helper,
    this.selectedDate,
    this.selectedDuration = 60,
    this.selectedCategory,
    this.isLoading = false,
    this.bookedSession,
    this.error,
  });

  SessionState copyWith({
    DateTime? selectedDate,
    int? selectedDuration,
    String? selectedCategory,
    bool? isLoading,
    SessionModel? bookedSession,
    String? error,
    bool clearError = false,
  }) {
    return SessionState(
      helper: helper,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      bookedSession: bookedSession ?? this.bookedSession,
      error: clearError ? null : error ?? this.error,
    );
  }

  bool get canBook =>
      selectedDate != null && selectedCategory != null && !isLoading;
}

class SessionNotifier extends FamilyNotifier<SessionState, UserModel> {
  @override
  SessionState build(UserModel arg) => SessionState(helper: arg);

  void selectDate(DateTime date) =>
      state = state.copyWith(selectedDate: date, clearError: true);

  void selectDuration(int minutes) =>
      state = state.copyWith(selectedDuration: minutes);

  void selectCategory(String category) =>
      state = state.copyWith(selectedCategory: category, clearError: true);

  Future<SessionModel?> bookSession() async {
    final user = ref.read(authProvider);
    if (user == null || !state.canBook) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await SupabaseService().bookSession(
        elderId: user.id,
        helperId: state.helper.id,
        scheduledAt: state.selectedDate!,
        category: state.selectedCategory!,
        durationMinutes: state.selectedDuration,
      );
      await NotificationService().sendSessionConfirmation(
        userId: user.id,
        helperName: state.helper.name,
        scheduledAt: state.selectedDate!,
      );
      state = state.copyWith(isLoading: false, bookedSession: session);
      ref.invalidate(userSessionsProvider);
      return session;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível agendar. Tente novamente.',
      );
      return null;
    }
  }
}

final sessionProvider =
    NotifierProviderFamily<SessionNotifier, SessionState, UserModel>(
        SessionNotifier.new);
