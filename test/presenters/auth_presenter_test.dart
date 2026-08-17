import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neto_de_aluguel/models/user.dart';
import 'package:neto_de_aluguel/presenters/home_presenter.dart';

void main() {
  test('authProvider inicia sem usuario por padrao', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(authProvider), isNull);
  });

  test('setUser define o usuario logado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final user = mockHelpers.first;
    container.read(authProvider.notifier).setUser(user);

    expect(container.read(authProvider)?.id, user.id);
  });

  test('setCategories atualiza as categorias do usuario logado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(authProvider.notifier).setUser(mockHelpers.first);
    container.read(authProvider.notifier).setCategories(['Saúde', 'Educação']);

    expect(container.read(authProvider)?.categories, ['Saúde', 'Educação']);
  });
}
