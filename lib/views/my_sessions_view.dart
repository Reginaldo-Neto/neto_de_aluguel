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

class _SessionTile extends ConsumerWidget {
  final SessionModel session;
  final bool isElder;
  const _SessionTile({required this.session, required this.isElder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // A "contraparte" depende do papel de quem está olhando.
    final other = isElder ? session.helper : session.elder;
    final otherName = other?.name ?? (isElder ? 'Voluntário' : 'Participante');
    final hasPhoto = other?.avatarUrl != null && other!.avatarUrl!.isNotEmpty;
    final isPast = session.status == SessionStatus.completed ||
        session.status == SessionStatus.cancelled;
    final hasNotes = session.notes != null && session.notes!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isPast ? () => _editNotes(context, ref) : null,
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
        isThreeLine: isPast,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${session.category} · ${_formatDate(session.scheduledAt)}',
              style: const TextStyle(fontSize: 13),
            ),
            if (hasNotes)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (isPast)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Toque para adicionar anotação',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
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
    // Avaliação mútua em sessões concluídas.
    if (session.status == SessionStatus.completed) {
      if (isElder) {
        return session.rating != null
            ? _RatingDisplay(rating: session.rating!)
            : _RateButton(session: session);
      }
      return session.elderRating != null
          ? _RatingDisplay(rating: session.elderRating!)
          : _RateButton(session: session, rateElder: true);
    }
    return _StatusBadge(status: session.status);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} às '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NotesDialog(initial: session.notes ?? ''),
    );
    if (result == null) return;
    try {
      await SupabaseService().updateSessionNotes(session.id, result);
      ref.invalidate(userSessionsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a anotação.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Diálogo de anotações do atendimento; retorna o texto via Navigator.pop.
class _NotesDialog extends StatefulWidget {
  final String initial;
  const _NotesDialog({required this.initial});

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anotações'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Escreva suas anotações sobre este atendimento',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Botão "Avaliar" que abre o seletor de estrelas e grava a nota.
/// Com [rateElder] true, o voluntário avalia o idoso; caso contrário, o idoso
/// avalia o voluntário.
class _RateButton extends ConsumerWidget {
  final SessionModel session;
  final bool rateElder;
  const _RateButton({required this.session, this.rateElder = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetName = rateElder
        ? (session.elder?.name ?? 'participante')
        : (session.helper?.name ?? 'voluntário');
    return TextButton.icon(
      icon: const Icon(Icons.star_outline_rounded, size: 18),
      label: const Text('Avaliar'),
      onPressed: () async {
        final rating = await showDialog<double>(
          context: context,
          builder: (_) => _RatingDialog(targetName: targetName),
        );
        if (rating == null) return;
        try {
          if (rateElder) {
            await SupabaseService().rateElder(session.id, rating);
          } else {
            await SupabaseService().rateSession(session.id, rating);
          }
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
  final String targetName;
  const _RatingDialog({required this.targetName});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Avaliar ${widget.targetName}'),
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
