import 'dart:typed_data';
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

  /// Atualiza dados editáveis do perfil (nome, bio, valor/hora).
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    double? hourlyRate,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;
    if (updates.isEmpty) return;
    await _db.from('profiles').update(updates).eq('id', userId);
  }

  /// Atualiza a URL do avatar do perfil.
  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await _db
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

  /// Envia a foto para o bucket "avatars" e retorna a URL pública.
  /// O arquivo é salvo em `<userId>/avatar.<ext>` (a policy amarra a pasta
  /// ao dono). Adiciona um parâmetro anti-cache para forçar o refresh.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final ext = fileExt.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final path = '$userId/avatar.$ext';

    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    final url = _db.storage.from('avatars').getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ─────────────────────── Indisponibilidade ───────────────────────

  /// Dias em que o voluntário marcou que NÃO vai atender.
  Future<List<DateTime>> getUnavailableDays(String helperId) async {
    final List<dynamic> data = await _db
        .from('helper_unavailability')
        .select('day')
        .eq('helper_id', helperId)
        .order('day');
    return data.map((r) => DateTime.parse(r['day'] as String)).toList();
  }

  Future<void> addUnavailableDay(String helperId, DateTime day) async {
    final iso = _dateOnly(day);
    await _db.from('helper_unavailability').upsert(
      {'helper_id': helperId, 'day': iso},
      onConflict: 'helper_id,day',
    );
  }

  Future<void> removeUnavailableDay(String helperId, DateTime day) async {
    final iso = _dateOnly(day);
    await _db
        .from('helper_unavailability')
        .delete()
        .eq('helper_id', helperId)
        .eq('day', iso);
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  /// Registra a avaliação (1–5) que o idoso deu ao voluntário na sessão.
  Future<void> rateSession(String sessionId, double rating) async {
    await _db
        .from('sessions')
        .update({'rating': rating})
        .eq('id', sessionId);
  }

  /// Registra a avaliação (1–5) que o voluntário deu ao idoso na sessão.
  Future<void> rateElder(String sessionId, double rating) async {
    await _db
        .from('sessions')
        .update({'elder_rating': rating})
        .eq('id', sessionId);
  }

  /// Salva as anotações de um atendimento.
  Future<void> updateSessionNotes(String sessionId, String notes) async {
    await _db
        .from('sessions')
        .update({'notes': notes})
        .eq('id', sessionId);
  }
}
