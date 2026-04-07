import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/session.dart';
import '../services/supabase_service.dart';
import 'login_presenter.dart';

// ── Auth state (usuário logado) ──────────────────────────────────

class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  void setUser(UserModel user) => state = user;

  Future<void> signOut() async {
    await SupabaseService().signOut();
    state = null;
  }

  void toggleAvailability() {
    if (state == null) return;
    state = state!.copyWith(isAvailable: !state!.isAvailable);
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// ── Home state (lista de ajudantes + filtro) ─────────────────────

class HomeState {
  final List<UserModel> helpers;
  final String? activeCategory;
  final bool isLoading;

  const HomeState({
    this.helpers = const [],
    this.activeCategory,
    this.isLoading = false,
  });

  HomeState copyWith({
    List<UserModel>? helpers,
    String? activeCategory,
    bool clearCategory = false,
    bool? isLoading,
  }) {
    return HomeState(
      helpers: helpers ?? this.helpers,
      activeCategory: clearCategory ? null : activeCategory ?? this.activeCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  final _service = SupabaseService();

  @override
  HomeState build() {
    loadHelpers();
    return const HomeState(isLoading: true);
  }

  Future<void> loadHelpers({String? category}) async {
    state = state.copyWith(isLoading: true);
    final helpers = await _service.getHelpers(category: category);
    state = state.copyWith(
      helpers: helpers,
      isLoading: false,
      activeCategory: category,
      clearCategory: category == null,
    );
  }

  void filterByCategory(String? category) {
    if (state.activeCategory == category) {
      loadHelpers();
    } else {
      loadHelpers(category: category);
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

// ── Sessions do usuário atual ────────────────────────────────────

final userSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return [];
  return SupabaseService().getSessions(userId: user.id);
});

// Provider para redirecionar baseado na role do usuário logado
final loginNotifierProvider = loginProvider;
