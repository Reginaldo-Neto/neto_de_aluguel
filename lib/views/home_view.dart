import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../models/session.dart';
import '../presenters/home_presenter.dart';
import '../widgets/helper_card.dart';
import '../widgets/category_chip.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    return user.role == UserRole.elder
        ? _ElderHome(user: user)
        : _HelperHome(user: user);
  }
}

// ══════════════════════════════════════════
// ELDER HOME
// ══════════════════════════════════════════

class _ElderHome extends ConsumerWidget {
  final UserModel user;
  const _ElderHome({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${user.name.split(' ').first}! 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('O que você precisa hoje?',
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => homeNotifier.loadHelpers(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Categorias',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            CategoryChipGrid(
              activeCategory: homeState.activeCategory,
              onSelect: homeNotifier.filterByCategory,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    homeState.activeCategory != null
                        ? homeState.activeCategory!
                        : 'Todos os ajudantes',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('${homeState.helpers.length} disponíveis',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: homeState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : homeState.helpers.isEmpty
                      ? _EmptyHelpers()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: homeState.helpers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final helper = homeState.helpers[index];
                            return HelperCard(
                              helper: helper,
                              onTap: () =>
                                  context.push('/session/${helper.id}',
                                      extra: helper),
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

class _EmptyHelpers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Nenhum ajudante nessa categoria',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// HELPER HOME
// ══════════════════════════════════════════

class _HelperHome extends ConsumerWidget {
  final UserModel user;
  const _HelperHome({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(userSessionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${user.name.split(' ').first}! 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Suas sessões agendadas',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          _AvailabilityToggle(user: user),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _StatsRow(user: user),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Erro ao carregar sessões')),
              data: (list) => list.isEmpty
                  ? _NoSessions()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _SessionCard(session: list[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityToggle extends ConsumerWidget {
  final UserModel user;
  const _AvailabilityToggle({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          Text(
            user.isAvailable ? 'Online' : 'Offline',
            style: TextStyle(
              color: user.isAvailable ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Switch(
            value: user.isAvailable,
            onChanged: (_) =>
                ref.read(authProvider.notifier).toggleAvailability(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
              label: 'Avaliação',
              value: '⭐ ${user.rating.toStringAsFixed(1)}'),
          _Stat(label: 'Sessões', value: '${user.totalSessions}'),
          _Stat(
              label: 'Taxa/hora',
              value: 'R\$ ${user.hourlyRate?.toStringAsFixed(0) ?? '-'}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = session.scheduledAt.isAfter(DateTime.now());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            session.elder?.initials ?? '?',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
        ),
        title: Text(session.elder?.name ?? 'Idoso',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${session.category} · ${_formatDate(session.scheduledAt)}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: isUpcoming
            ? FilledButton.tonal(
                onPressed: () => context.push(
                  '/video-call/${session.id}',
                  extra: session,
                ),
                child: const Text('Entrar'),
              )
            : _StatusBadge(status: session.status),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final SessionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SessionStatus.completed:
        color = Colors.green;
        break;
      case SessionStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        SessionModel(
          id: '',
          elderId: '',
          helperId: '',
          scheduledAt: DateTime.now(),
          category: '',
          status: status,
        ).statusLabel,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _NoSessions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Nenhuma sessão agendada',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text('Quando alguém agendar com você, aparecerá aqui.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
