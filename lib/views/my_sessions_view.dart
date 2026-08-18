import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../presenters/home_presenter.dart';

/// Histórico de conversas/atendimentos do usuário logado. Serve tanto para o
/// idoso (mostra o voluntário) quanto para o voluntário (mostra o idoso),
/// separando em "Próximas" e "Anteriores".
class MySessionsView extends ConsumerWidget {
  const MySessionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final sessions = ref.watch(userSessionsProvider);
    final isElder = user?.role == UserRole.elder;

    return Scaffold(
      appBar: AppBar(
        title: Text(isElder ? 'Minhas conversas' : 'Meus atendimentos'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userSessionsProvider),
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorState(
            onRetry: () => ref.invalidate(userSessionsProvider),
          ),
          data: (list) {
            if (list.isEmpty) return _EmptyState(isElder: isElder);

            const upcomingStatuses = {
              SessionStatus.pending,
              SessionStatus.confirmed,
              SessionStatus.inProgress,
            };
            final upcoming =
                list.where((s) => upcomingStatuses.contains(s.status)).toList();
            final past =
                list.where((s) => !upcomingStatuses.contains(s.status)).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader('Próximas'),
                  const SizedBox(height: 8),
                  ...upcoming.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SessionTile(session: s, isElder: isElder),
                      )),
                  const SizedBox(height: 12),
                ],
                if (past.isNotEmpty) ...[
                  _SectionHeader('Anteriores'),
                  const SizedBox(height: 8),
                  ...past.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SessionTile(session: s, isElder: isElder),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel session;
  final bool isElder;
  const _SessionTile({required this.session, required this.isElder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A "contraparte" depende do papel de quem está olhando.
    final other = isElder ? session.helper : session.elder;
    final otherName = other?.name ?? (isElder ? 'Voluntário' : 'Participante');
    final hasPhoto = other?.avatarUrl != null && other!.avatarUrl!.isNotEmpty;

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
          backgroundImage: hasPhoto ? NetworkImage(other.avatarUrl!) : null,
          child: hasPhoto
              ? null
              : Text(
                  other?.initials ?? '?',
                  style:
                      TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
        ),
        title:
            Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${session.category} · ${_formatDate(session.scheduledAt)}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: _buildTrailing(context),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final canJoin = session.status == SessionStatus.confirmed ||
        session.status == SessionStatus.inProgress;
    if (canJoin) {
      return FilledButton.tonal(
        onPressed: () =>
            context.push('/video-call/${session.id}', extra: session),
        child: const Text('Entrar'),
      );
    }
    // O idoso avalia o voluntário em sessões concluídas.
    if (isElder && session.status == SessionStatus.completed) {
      return session.rating != null
          ? _RatingDisplay(rating: session.rating!)
          : _RateButton(session: session);
    }
    return _StatusBadge(status: session.status);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} às '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Botão "Avaliar" que abre o seletor de estrelas e grava a nota.
class _RateButton extends ConsumerWidget {
  final SessionModel session;
  const _RateButton({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.star_outline_rounded, size: 18),
      label: const Text('Avaliar'),
      onPressed: () async {
        final rating = await showDialog<double>(
          context: context,
          builder: (_) => _RatingDialog(
            helperName: session.helper?.name ?? 'voluntário',
          ),
        );
        if (rating == null) return;
        try {
          await SupabaseService().rateSession(session.id, rating);
          ref.invalidate(userSessionsProvider);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não foi possível enviar a avaliação.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }
}

/// Mostra a nota já dada (ex.: ⭐ 4.0).
class _RatingDisplay extends StatelessWidget {
  final double rating;
  const _RatingDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Diálogo com 5 estrelas; retorna a nota escolhida (1–5) via Navigator.pop.
class _RatingDialog extends StatefulWidget {
  final String helperName;
  const _RatingDialog({required this.helperName});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Avaliar ${widget.helperName}'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final filled = i < _stars;
          return IconButton(
            tooltip: '${i + 1}',
            icon: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 34,
            ),
            onPressed: () => setState(() => _stars = i + 1),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _stars == 0
              ? null
              : () => Navigator.pop(context, _stars.toDouble()),
          child: const Text('Enviar'),
        ),
      ],
    );
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
  final bool isElder;
  const _EmptyState({required this.isElder});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
            child: Text(isElder ? '💬' : '📋',
                style: const TextStyle(fontSize: 48))),
        const SizedBox(height: 12),
        Center(
          child: Text(
            isElder ? 'Nenhuma conversa ainda' : 'Nenhum atendimento ainda',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            isElder
                ? 'Suas ligações e agendamentos aparecerão aqui.'
                : 'Seus atendimentos aparecerão aqui.',
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
          child: Text('Erro ao carregar',
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
