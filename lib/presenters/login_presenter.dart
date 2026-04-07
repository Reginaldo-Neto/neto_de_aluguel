import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

enum LoginMode { signIn, signUp }

class LoginState {
  final bool isLoading;
  final String? error;
  final LoginMode mode;
  final UserRole selectedRole;

  const LoginState({
    this.isLoading = false,
    this.error,
    this.mode = LoginMode.signIn,
    this.selectedRole = UserRole.elder,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    LoginMode? mode,
    UserRole? selectedRole,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      mode: mode ?? this.mode,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class LoginNotifier extends Notifier<LoginState> {
  final _service = SupabaseService();

  @override
  LoginState build() => const LoginState();

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == LoginMode.signIn ? LoginMode.signUp : LoginMode.signIn,
      clearError: true,
    );
  }

  void setRole(UserRole role) {
    state = state.copyWith(selectedRole: role, clearError: true);
  }

  Future<UserModel?> submit({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      UserModel? user;
      if (state.mode == LoginMode.signIn) {
        user = await _service.signIn(
          email: email,
          password: password,
          role: state.selectedRole,
        );
      } else {
        user = await _service.signUp(
          email: email,
          password: password,
          name: name ?? email.split('@').first,
          role: state.selectedRole,
        );
      }
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao entrar. Verifique seus dados e tente novamente.',
      );
      return null;
    }
  }
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
