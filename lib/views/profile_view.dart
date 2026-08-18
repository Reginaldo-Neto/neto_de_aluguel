import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../presenters/home_presenter.dart';
import '../services/supabase_service.dart';
import '../widgets/primary_button.dart';

/// Tela de perfil: o usuário edita nome, bio e — se for voluntário —
/// valor/hora e especialidades.
class ProfileView extends HookConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();

    final isHelper = user.role == UserRole.helper;
    final theme = Theme.of(context);

    final nameCtrl = useTextEditingController(text: user.name);
    final bioCtrl = useTextEditingController(text: user.bio ?? '');
    final rateCtrl = useTextEditingController(
        text: user.hourlyRate != null ? user.hourlyRate!.toStringAsFixed(0) : '');
    final categories = useState<Set<String>>(
        Set.from(user.categories.where((c) => c != 'Geral')));
    final isLoading = useState(false);
    final isUploadingPhoto = useState(false);

    Future<void> pickAndUploadPhoto() async {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (file == null) return;

      isUploadingPhoto.value = true;
      try {
        final bytes = await file.readAsBytes();
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        final url = await SupabaseService().uploadAvatar(
          userId: user.id,
          bytes: bytes,
          fileExt: ext,
        );
        await SupabaseService().updateAvatarUrl(user.id, url);
        ref.read(authProvider.notifier).updateProfile(avatarUrl: url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto atualizada!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível enviar a foto.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        isUploadingPhoto.value = false;
      }
    }

    Future<void> save() async {
      isLoading.value = true;
      final name = nameCtrl.text.trim();
      final bio = bioCtrl.text.trim();
      final rate = double.tryParse(rateCtrl.text.replaceAll(',', '.'));
      try {
        await SupabaseService().updateProfile(
          userId: user.id,
          name: name.isEmpty ? null : name,
          bio: bio,
          hourlyRate: isHelper ? rate : null,
        );
        ref.read(authProvider.notifier).updateProfile(
              name: name.isEmpty ? null : name,
              bio: bio,
              hourlyRate: isHelper ? rate : null,
            );
        if (isHelper) {
          final cats = categories.value.toList();
          await SupabaseService().updateCategories(user.id, cats);
          ref.read(authProvider.notifier).setCategories(cats);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível salvar. Tente novamente.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _AvatarEditor(
                user: user,
                isUploading: isUploadingPhoto.value,
                onEdit: pickAndUploadPhoto,
              ),
            ),
            const SizedBox(height: 28),
            _Label('Nome'),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Seu nome completo',
              ),
            ),
            const SizedBox(height: 20),
            _Label('Sobre mim'),
            const SizedBox(height: 8),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Conte um pouco sobre você',
                alignLabelWithHint: true,
              ),
            ),
            if (isHelper) ...[
              const SizedBox(height: 12),
              _Label('Valor por hora (R\$)'),
              const SizedBox(height: 8),
              TextField(
                controller: rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  hintText: 'Ex.: 35',
                ),
              ),
              const SizedBox(height: 24),
              _Label('Minhas especialidades'),
              const SizedBox(height: 4),
              Text(
                'Você já aparece em "Geral". Selecione especialidades para '
                'aparecer em mais categorias.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...mockCategories.where((c) => c.name != 'Geral').map((cat) {
                final selected = categories.value.contains(cat.name);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${cat.emoji}  ${cat.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(cat.description),
                  value: selected,
                  activeColor: cat.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onChanged: (v) {
                    final next = Set<String>.from(categories.value);
                    if (v == true) {
                      next.add(cat.name);
                    } else {
                      next.remove(cat.name);
                    }
                    categories.value = next;
                  },
                );
              }),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event_busy_rounded),
                  title: const Text('Dias em que não atendo'),
                  subtitle: const Text('Marque suas folgas no calendário'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/availability'),
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Salvar',
              onPressed: save,
              isLoading: isLoading.value,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  final UserModel user;
  final bool isUploading;
  final VoidCallback onEdit;
  const _AvatarEditor({
    required this.user,
    required this.isUploading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: hasPhoto ? NetworkImage(user.avatarUrl!) : null,
          child: isUploading
              ? const CircularProgressIndicator()
              : hasPhoto
                  ? null
                  : Text(
                      user.initials,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isUploading ? null : onEdit,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}
