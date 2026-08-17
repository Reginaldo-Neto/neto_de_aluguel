import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neto_de_aluguel/models/user.dart';
import 'package:neto_de_aluguel/presenters/session_presenter.dart';

void main() {
  final helper = mockHelpers.first;
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('estado inicial guarda o helper e nao permite agendar', () {
    final state = container.read(sessionProvider(helper));
    expect(state.helper, helper);
    expect(state.selectedDuration, 60);
    expect(state.canBook, isFalse);
  });

  test('canBook exige data E categoria', () {
    final notifier = container.read(sessionProvider(helper).notifier);

    notifier.selectDate(DateTime(2030, 1, 1, 9));
    expect(container.read(sessionProvider(helper)).canBook, isFalse);

    notifier.selectCategory('Companhia');
    expect(container.read(sessionProvider(helper)).canBook, isTrue);
  });

  test('selectDuration atualiza a duracao escolhida', () {
    final notifier = container.read(sessionProvider(helper).notifier);

    notifier.selectDuration(90);
    expect(container.read(sessionProvider(helper)).selectedDuration, 90);
  });
}
