import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../presenters/login_presenter.dart';
import '../presenters/home_presenter.dart';
import '../widgets/primary_button.dart';

class LoginView extends HookConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final nameCtrl = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> handleSubmit() async {
      if (!formKey.currentState!.validate()) return;
      final user = await notifier.submit(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        name: state.mode == LoginMode.signUp ? nameCtrl.text.trim() : null,
      );
      if (user != null && context.mounted) {
        ref.read(authProvider.notifier).setUser(user);
        context.go('/home');
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  const SizedBox(height: 40),
                  _RoleSelector(
                    selected: state.selectedRole,
                    onSelect: notifier.setRole,
                  ),
                  const SizedBox(height: 28),
                  if (state.mode == LoginMode.signUp) ...[
                    _Field(
                      controller: nameCtrl,
                      label: 'Seu nome completo',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _Field(
                    controller: emailCtrl,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    controller: passwordCtrl,
                    label: 'Senha',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: state.error!),
                  ],
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: state.mode == LoginMode.signIn ? 'Entrar' : 'Criar conta',
                    onPressed: handleSubmit,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: notifier.toggleMode,
                    child: Text(
                      state.mode == LoginMode.signIn
                          ? 'Não tem conta? Cadastre-se'
                          : 'Já tem conta? Entrar',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.favorite_rounded,
              size: 44, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text('Neto de Aluguel',
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        const SizedBox(height: 6),
        Text('Ajuda e companhia com um clique',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final void Function(UserRole) onSelect;

  const _RoleSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eu sou...', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            _RoleOption(
              label: 'Idoso',
              emoji: '👴',
              selected: selected == UserRole.elder,
              onTap: () => onSelect(UserRole.elder),
            ),
            const SizedBox(width: 12),
            _RoleOption(
              label: 'Ajudante',
              emoji: '🤝',
              selected: selected == UserRole.helper,
              onTap: () => onSelect(UserRole.helper),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
