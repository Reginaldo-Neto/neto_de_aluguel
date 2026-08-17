import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../presenters/home_presenter.dart';

/// Histórico de conversas do idoso: lista as sessões dele (agendadas,
/// concluídas ou canceladas), com a opção de entrar nas que estão por vir.
class MySessionsView extends ConsumerWidget {
  const MySessionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(userSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas conversas'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userSessionsProvider),
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorState(
            onRetry: () => ref.invalidate(userSessionsProvider),
          ),
          data: (list) => list.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ElderSessionCard(session: list[index]),
                ),
        ),
      ),
    );
  }
}

class _ElderSessionCard extends StatelessWidget {
  final SessionModel session;
  const _ElderSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canJoin = session.status == SessionStatus.confirmed ||
        session.status == SessionStatus.inProgress;
    final helperName = session.helper?.name ?? 'Voluntário';

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
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            session.helper?.initials ?? '?',
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(helperName,
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
            : _StatusBadge(status: session.status),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} às '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
        _label(status),
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  String _label(SessionStatus status) {
    switch (status) {
      case SessionStatus.pending:
        return 'Aguardando';
      case SessionStatus.confirmed:
        return 'Confirmado';
      case SessionStatus.inProgress:
        return 'Em andamento';
      case SessionStatus.completed:
        return 'Concluído';
      case SessionStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView para permitir o pull-to-refresh mesmo vazio.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Center(child: Text('💬', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 12),
        Center(
          child: Text('Nenhuma conversa ainda',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Suas ligações e agendamentos aparecerão aqui.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text('Erro ao carregar suas conversas',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}
