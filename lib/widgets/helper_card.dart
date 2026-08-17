import 'package:flutter/material.dart';
import '../models/user.dart';

class HelperCard extends StatelessWidget {
  final UserModel helper;
  final VoidCallback onTap;
  final VoidCallback? onCall;

  const HelperCard({
    super.key,
    required this.helper,
    required this.onTap,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(helper: helper),
                const SizedBox(width: 12),
                Expanded(child: _Info(helper: helper)),
                _StatusBadge(isAvailable: helper.isAvailable),
              ],
            ),
            if (onCall != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: const Text('Agendar'),
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Ligar'),
                      onPressed: helper.isAvailable ? onCall : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;
  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAvailable ? 'Online' : 'Offline',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel helper;
  const _Avatar({required this.helper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            helper.initials,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (helper.isAvailable)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final UserModel helper;
  const _Info({required this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helper.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 2),
            Text(
              '${helper.rating.toStringAsFixed(1)} · ${helper.totalSessions} atendimentos',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        if (helper.categories.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: helper.categories
                .where((c) => c != 'Geral')
                .take(2)
                .map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
