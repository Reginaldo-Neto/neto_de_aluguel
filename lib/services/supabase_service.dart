import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/session.dart';

final _db = Supabase.instance.client;

class SupabaseService {
  // ──────────────────────────── Auth ────────────────────────────

  Future<UserModel?> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final res = await _db.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) return null;
    return _fetchProfile(res.user!.id);
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role.name},
    );
    if (res.user == null) return null;
    // Aguarda o trigger criar o perfil
    await Future.delayed(const Duration(milliseconds: 500));
    return _fetchProfile(res.user!.id);
  }

  Future<void> signOut() async {
    await _db.auth.signOut();
  }

  Future<UserModel?> currentUser() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  // ──────────────────────────── Perfil ────────────────────────────

  Future<UserModel?> _fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson({...data, 'email': _db.auth.currentUser?.email ?? ''});
  }

  // ──────────────────────────── Helpers ────────────────────────────

  Future<List<UserModel>> getHelpers({String? category, bool onlyAvailable = true}) async {
    final List<dynamic> data = onlyAvailable
        ? await _db
            .from('profiles')
            .select()
            .eq('role', 'helper')
            .eq('is_available', true)
            .order('rating', ascending: false)
        : await _db
            .from('profiles')
            .select()
            .eq('role', 'helper')
            .order('rating', ascending: false);

    final helpers = data
        .map((row) => UserModel.fromJson({...row, 'email': ''}))
        .toList();

    // "Geral" e null mostram todos os helpers
    if (category == null || category == 'Geral') return helpers;
    return helpers.where((h) => h.categories.contains(category)).toList();
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _db
        .from('profiles')
        .update({'is_available': isAvailable})
        .eq('id', userId);
  }

  Future<void> updateCategories(String userId, List<String> categories) async {
    await _db
        .from('profiles')
        .update({'categories': categories})
        .eq('id', userId);
  }

  // ──────────────────────────── Sessões ────────────────────────────

  Future<List<SessionModel>> getSessions({required String userId}) async {
    final List<dynamic> data = await _db
        .from('sessions')
        .select('*, helper:profiles!helper_id(*), elder:profiles!elder_id(*)')
        .or('elder_id.eq.$userId,helper_id.eq.$userId')
        .order('scheduled_at', ascending: false);

    return data.map((row) {
      UserModel? helper;
      UserModel? elder;

      if (row['helper'] != null) {
        helper = UserModel.fromJson({...row['helper'], 'email': ''});
      }
      if (row['elder'] != null) {
        elder = UserModel.fromJson({...row['elder'], 'email': ''});
      }

      return SessionModel.fromJson({
        ...row,
      }).copyWith2(helper: helper, elder: elder);
    }).toList();
  }

  Future<SessionModel> bookSession({
    required String elderId,
    required String helperId,
    required DateTime scheduledAt,
    required String category,
    required int durationMinutes,
  }) async {
    final Map<String, dynamic> data = await _db
        .from('sessions')
        .insert({
          'elder_id': elderId,
          'helper_id': helperId,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'category': category,
          'duration_minutes': durationMinutes,
          'status': 'confirmed',
        })
        .select('*, helper:profiles!helper_id(*)')
        .single();

    UserModel? helper;
    if (data['helper'] != null) {
      helper = UserModel.fromJson({...data['helper'], 'email': ''});
    }

    return SessionModel.fromJson(data).copyWith2(helper: helper);
  }

  /// Cria uma sessão imediata (ligação instantânea ou direta) já em andamento
  /// e persiste no banco, retornando a sessão com id real e perfis anexados.
  Future<SessionModel> createImmediateSession({
    required String elderId,
    required String helperId,
    required String category,
  }) async {
    final Map<String, dynamic> data = await _db
        .from('sessions')
        .insert({
          'elder_id': elderId,
          'helper_id': helperId,
          'scheduled_at': DateTime.now().toUtc().toIso8601String(),
          'category': category,
          'duration_minutes': 60,
          'status': SessionStatus.inProgress.name,
        })
        .select('*, helper:profiles!helper_id(*), elder:profiles!elder_id(*)')
        .single();

    UserModel? helper;
    UserModel? elder;
    if (data['helper'] != null) {
      helper = UserModel.fromJson({...data['helper'], 'email': ''});
    }
    if (data['elder'] != null) {
      elder = UserModel.fromJson({...data['elder'], 'email': ''});
    }

    return SessionModel.fromJson(data).copyWith2(helper: helper, elder: elder);
  }

  /// Marca uma sessão como concluída (chamado ao encerrar a videochamada).
  Future<void> completeSession(String sessionId) async {
    await _db
        .from('sessions')
        .update({'status': SessionStatus.completed.name})
        .eq('id', sessionId);
  }
}
