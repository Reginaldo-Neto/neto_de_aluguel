import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/user.dart';
import 'models/session.dart';
import 'presenters/home_presenter.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/session_view.dart';
import 'views/video_call_view.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter _buildRouter(UserModel? currentUser) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: currentUser != null ? '/home' : '/login',
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final isOnLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginView()),
      GoRoute(path: '/home', builder: (_, __) => const HomeView()),
      GoRoute(
        path: '/session/:helperId',
        builder: (_, state) => SessionView(helper: state.extra as UserModel),
      ),
      GoRoute(
        path: '/video-call/:sessionId',
        builder: (_, state) => VideoCallView(session: state.extra as SessionModel),
      ),
    ],
  );
}

class NetoDeAluguelApp extends ConsumerWidget {
  const NetoDeAluguelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    return MaterialApp.router(
      title: 'Neto de Aluguel',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: _buildRouter(currentUser),
    );
  }
}

// ── Paleta de cores ──────────────────────────────────────────────

const _kSeed       = Color(0xFF6750A4); // roxo Material You
const _kBgLight    = Color(0xFFF6F4FF); // fundo levemente lilás
const _kCardLight  = Color(0xFFFFFFFF);
const _kBgDark     = Color(0xFF1C1B1F);
const _kCardDark   = Color(0xFF2B2930);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final cs = ColorScheme.fromSeed(
    seedColor: _kSeed,
    brightness: brightness,
    // garante superfícies claras no light mode
    surface: isDark ? _kBgDark : _kBgLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? _kBgDark : _kBgLight,

    // ── AppBar ───────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isDark ? _kBgDark : _kBgLight,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    ),

    // ── Tipografia acessível (fonte maior) ───────────────────────
    textTheme: TextTheme(
      displayLarge:  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge:    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium:   const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      bodyLarge:     const TextStyle(fontSize: 16),
      bodyMedium:    const TextStyle(fontSize: 15),
      bodySmall:     const TextStyle(fontSize: 13),
      labelLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
    ),

    // ── Cards ────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? _kCardDark : _kCardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── FilledButton — fundo primário, texto SEMPRE branco ────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,          // ← corrige letras pretas
        disabledBackgroundColor: cs.primary.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
      ),
    ),

    // ── FilledButton.tonal — texto sempre escuro legível ──────────
    // (usado nos botões secundários como "Entrar" no card)

    // ── ElevatedButton ───────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        minimumSize: const Size(88, 52),
        elevation: 0,
      ),
    ),

    // ── OutlinedButton ───────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        minimumSize: const Size(88, 52),
      ),
    ),

    // ── TextButton ───────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: cs.primary),
    ),

    // ── Inputs ───────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? cs.surfaceContainerHighest : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
    ),

    // ── Chips ────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(fontSize: 14),
      backgroundColor: isDark ? _kCardDark : const Color(0xFFEDE9FF),
    ),

    // ── Switch ───────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : cs.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest,
      ),
    ),
  );
}
