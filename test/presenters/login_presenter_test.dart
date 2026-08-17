import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neto_de_aluguel/models/user.dart';
import 'package:neto_de_aluguel/presenters/login_presenter.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('estado inicial: modo signIn, papel elder, sem loading/erro', () {
    final state = container.read(loginProvider);
    expect(state.mode, LoginMode.signIn);
    expect(state.selectedRole, UserRole.elder);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('toggleMode alterna entre signIn e signUp', () {
    final notifier = container.read(loginProvider.notifier);

    notifier.toggleMode();
    expect(container.read(loginProvider).mode, LoginMode.signUp);

    notifier.toggleMode();
    expect(container.read(loginProvider).mode, LoginMode.signIn);
  });

  test('setRole muda o papel selecionado', () {
    final notifier = container.read(loginProvider.notifier);

    notifier.setRole(UserRole.helper);
    expect(container.read(loginProvider).selectedRole, UserRole.helper);

    notifier.setRole(UserRole.elder);
    expect(container.read(loginProvider).selectedRole, UserRole.elder);
  });
}
