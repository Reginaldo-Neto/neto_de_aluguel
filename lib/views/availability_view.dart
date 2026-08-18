import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../presenters/home_presenter.dart';
import '../services/supabase_service.dart';

const _weekdaysPt = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

const _monthsPt = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String _formatDayPt(DateTime d) =>
    '${_weekdaysPt[d.weekday - 1]}, ${d.day} de ${_monthsPt[d.month - 1]} de ${d.year}';

/// Tela onde o voluntário marca os dias em que NÃO vai atender.
class AvailabilityView extends HookConsumerWidget {
  const AvailabilityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final service = SupabaseService();
    final days = useState<List<DateTime>>([]);
    final isLoading = useState(true);

    useEffect(() {
      Future<void> load() async {
        try {
          days.value = await service.getUnavailableDays(user.id);
        } catch (_) {
          // mantém lista vazia em caso de erro
        } finally {
          isLoading.value = false;
        }
      }

      load();
      return null;
    }, const []);

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    Future<void> addDay() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
        helpText: 'Escolha um dia indisponível',
      );
      if (picked == null) return;
      final d = DateTime(picked.year, picked.month, picked.day);
      if (days.value.any((x) => sameDay(x, d))) return;
      try {
        await service.addUnavailableDay(user.id, d);
        days.value = [...days.value, d]..sort();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível salvar o dia.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    Future<void> removeDay(DateTime d) async {
      final previous = days.value;
      days.value = days.value.where((x) => !sameDay(x, d)).toList();
      try {
        await service.removeUnavailableDay(user.id, d);
      } catch (_) {
        days.value = previous; // desfaz se falhar
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dias indisponíveis'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addDay,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar dia'),
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marque os dias em que você não poderá atender. '
                    'Eles ficam registrados no seu perfil.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: days.value.isEmpty
                        ? _Empty()
                        : ListView.separated(
                            itemCount: days.value.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final d = days.value[i];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.event_busy_rounded),
                                  title: Text(_formatDayPt(d)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    tooltip: 'Remover',
                                    onPressed: () => removeDay(d),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Nenhum dia bloqueado',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text('Toque em "Adicionar dia" para marcar uma folga.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
