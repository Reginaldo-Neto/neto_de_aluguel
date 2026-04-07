import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../presenters/session_presenter.dart';
import '../widgets/primary_button.dart';

class SessionView extends ConsumerWidget {
  final UserModel helper;
  const SessionView({super.key, required this.helper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider(helper));
    final notifier = ref.read(sessionProvider(helper).notifier);

    if (state.bookedSession != null) {
      return _BookingConfirmation(
        session: state,
        onGoHome: () => context.go('/home'),
        onStartCall: () => context.push(
          '/video-call/${state.bookedSession!.id}',
          extra: state.bookedSession,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar sessão'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelperHeader(helper: helper),
            const SizedBox(height: 28),
            _SectionTitle(title: '1. Escolha a categoria'),
            const SizedBox(height: 12),
            _CategorySelector(
              categories: helper.categories,
              selected: state.selectedCategory,
              onSelect: notifier.selectCategory,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: '2. Escolha a data e hora'),
            const SizedBox(height: 12),
            _DateSelector(
              selected: state.selectedDate,
              onSelect: notifier.selectDate,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: '3. Duração da sessão'),
            const SizedBox(height: 12),
            _DurationSelector(
              selected: state.selectedDuration,
              onSelect: notifier.selectDuration,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(state.error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ],
            const SizedBox(height: 32),
            if (helper.hourlyRate != null)
              _PriceSummary(
                hourlyRate: helper.hourlyRate!,
                durationMinutes: state.selectedDuration,
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Confirmar agendamento',
              onPressed: state.canBook ? notifier.bookSession : null,
              isLoading: state.isLoading,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperHeader extends StatelessWidget {
  final UserModel helper;
  const _HelperHeader({required this.helper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            helper.initials,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(helper.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 2),
                  Text('${helper.rating.toStringAsFixed(1)} · ${helper.totalSessions} sessões',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              if (helper.bio != null) ...[
                const SizedBox(height: 6),
                Text(helper.bio!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final void Function(String) onSelect;

  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected == cat;
        final catModel = mockCategories.firstWhere(
          (c) => c.name == cat,
          orElse: () => mockCategories.first,
        );
        return ChoiceChip(
          label: Text('${catModel.emoji} $cat'),
          selected: isSelected,
          onSelected: (_) => onSelect(cat),
          selectedColor: catModel.color.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? catModel.color : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }).toList(),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime? selected;
  final void Function(DateTime) onSelect;

  const _DateSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final slots = _generateSlots();
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = slots[index];
          final isSelected =
              selected != null && _sameSlot(selected!, slot);
          return GestureDetector(
            onTap: () => onSelect(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd/MM').format(slot),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(slot),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white70
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DateTime> _generateSlots() {
    final now = DateTime.now();
    final slots = <DateTime>[];
    for (int i = 1; i <= 7; i++) {
      final day = now.add(Duration(days: i));
      slots.add(DateTime(day.year, day.month, day.day, 9, 0));
      slots.add(DateTime(day.year, day.month, day.day, 14, 0));
      slots.add(DateTime(day.year, day.month, day.day, 16, 0));
    }
    return slots;
  }

  bool _sameSlot(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour;
}

class _DurationSelector extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;

  const _DurationSelector({required this.selected, required this.onSelect});

  static const _options = [30, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((min) {
        final isSelected = selected == min;
        return ChoiceChip(
          label: Text(min < 60
              ? '$min min'
              : '${min ~/ 60}h${min % 60 > 0 ? '${min % 60}min' : ''}'),
          selected: isSelected,
          onSelected: (_) => onSelect(min),
        );
      }).toList(),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final double hourlyRate;
  final int durationMinutes;

  const _PriceSummary(
      {required this.hourlyRate, required this.durationMinutes});

  @override
  Widget build(BuildContext context) {
    final total = hourlyRate * durationMinutes / 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Valor estimado',
              style: TextStyle(fontWeight: FontWeight.w500)),
          Text(
            'R\$ ${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingConfirmation extends StatelessWidget {
  final SessionState session;
  final VoidCallback onGoHome;
  final VoidCallback onStartCall;

  const _BookingConfirmation({
    required this.session,
    required this.onGoHome,
    required this.onStartCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Sessão agendada!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Sua sessão com ${session.helper.name} foi confirmada para '
                '${DateFormat("dd/MM 'às' HH:mm").format(session.selectedDate!)}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Iniciar videochamada',
                onPressed: onStartCall,
                icon: Icons.videocam_rounded,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onGoHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Voltar ao início',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
