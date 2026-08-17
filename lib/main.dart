import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'models/user.dart';
import 'presenters/home_presenter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Restaura a sessão persistida: se o Supabase já tem um usuário autenticado,
  // carrega o perfil antes do primeiro frame para não cair na tela de login
  // a cada reabertura do app.
  UserModel? initialUser;
  if (Supabase.instance.client.auth.currentSession != null) {
    try {
      initialUser = await SupabaseService().currentUser();
    } catch (_) {
      initialUser = null;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => AuthNotifier(initialUser)),
      ],
      child: const NetoDeAluguelApp(),
    ),
  );
}
