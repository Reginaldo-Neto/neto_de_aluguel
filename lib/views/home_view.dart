import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/user.dart';
import '../models/session.dart';
import '../presenters/home_presenter.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
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
    final themeMode = ref.watch(themeModeProvider);
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
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Minhas conversas',
            onPressed: () => context.push('/my-sessions'),
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            tooltip: 'Alternar tema',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
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
            _InstantCallBanner(
              onCall: () => _startInstantMatch(context, ref),
            ),
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
                        : 'Voluntários disponíveis',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('${homeState.helpers.length} online',
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
                              onTap: () => context.push(
                                  '/session/${helper.id}',
                                  extra: helper),
                              onCall: () =>
                                  _callSpecificHelper(context, ref, helper),
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

Future<void> _startInstantMatch(BuildContext context, WidgetRef ref) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _MatchingDialog(),
  );

  // Busca fresca no Supabase — ignora cache local
  final helpers = await SupabaseService().getHelpers();

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (helpers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhum voluntário online no momento. Tente em breve!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final helper = helpers.first;
  final user = ref.read(authProvider)!;
  await _startCall(context, ref, helper: helper, category: 'Geral', user: user);
}

Future<void> _callSpecificHelper(
    BuildContext context, WidgetRef ref, UserModel helper) async {
  final user = ref.read(authProvider)!;
  final category = helper.categories.where((c) => c != 'Geral').isNotEmpty
      ? helper.categories.where((c) => c != 'Geral').first
      : 'Geral';
  await _startCall(context, ref, helper: helper, category: category, user: user);
}

/// Persiste a sessão imediata e navega para a videochamada.
Future<void> _startCall(
  BuildContext context,
  WidgetRef ref, {
  required UserModel helper,
  required String category,
  required UserModel user,
}) async {
  try {
    final session = await SupabaseService().createImmediateSession(
      elderId: user.id,
      helperId: helper.id,
      category: category,
    );
    await NotificationService().sendInstantCallInvite(
      helperId: helper.id,
      elderName: user.name,
    );
    ref.invalidate(userSessionsProvider);
    if (context.mounted) {
      context.push('/video-call/${session.id}', extra: session);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível iniciar a ligação. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _InstantCallBanner extends StatelessWidget {
  final VoidCallback onCall;
  const _InstantCallBanner({required this.onCall});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisa de ajuda agora?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conectamos você com um voluntário disponível em segundos.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Ligar agora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('📞', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

class _MatchingDialog extends StatelessWidget {
  const _MatchingDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Buscando voluntário...',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Aguarde um momento', style: theme.textTheme.bodySmall),
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
          Text('Nenhum voluntário nessa categoria',
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
    final themeMode = ref.watch(themeModeProvider);
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
            Text('Suas conversas agendadas',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          _AvailabilityToggle(user: user),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Meus atendimentos',
            onPressed: () => context.push('/my-sessions'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Meu perfil',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            tooltip: 'Alternar tema',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
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
          if (user.categories.isEmpty || user.categories.every((c) => c == 'Geral'))
            _NoCategoriesBanner(
              onTap: () => context.push('/profile'),
            ),
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

class _NoCategoriesBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NoCategoriesBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: theme.colorScheme.onSecondaryContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Adicione suas especialidades para aparecer em mais categorias.',
                style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.onSecondaryContainer),
          ],
        ),
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
          Container(
              width: 1,
              height: 36,
              color: theme.colorScheme.onPrimaryContainer
                  .withValues(alpha: 0.2)),
          _Stat(label: 'Atendimentos', value: '${user.totalSessions}'),
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
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.7))),
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
    final canJoin = session.status == SessionStatus.confirmed ||
        session.status == SessionStatus.inProgress;

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
            style:
                TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
        ),
        title: Text(session.elder?.name ?? 'Participante',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${session.category} · ${_formatDate(session.scheduledAt)}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: canJoin
            ? FilledButton.tonal(
                onPressed: () => context.push(
                  '/video-call/${session.id}',
                  extra: session,
                ),
                child: const Text('Entrar'),
              )
            : _StatusBadgeSession(status: session.status),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadgeSession extends StatelessWidget {
  final SessionStatus status;
  const _StatusBadgeSession({required this.status});

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
          Text('Nenhuma conversa agendada',
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
