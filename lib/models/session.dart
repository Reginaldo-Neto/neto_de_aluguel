import 'user.dart';

enum SessionStatus { pending, confirmed, inProgress, completed, cancelled }

class SessionModel {
  final String id;
  final String elderId;
  final String helperId;
  final UserModel? helper;
  final UserModel? elder;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String category;
  final SessionStatus status;
  final double? rating;
  final String? notes;

  const SessionModel({
    required this.id,
    required this.elderId,
    required this.helperId,
    this.helper,
    this.elder,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.category,
    this.status = SessionStatus.pending,
    this.rating,
    this.notes,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      elderId: json['elder_id'] as String,
      helperId: json['helper_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      category: json['category'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.pending,
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'elder_id': elderId,
        'helper_id': helperId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'category': category,
        'status': status.name,
        'rating': rating,
        'notes': notes,
      };

  SessionModel copyWith({SessionStatus? status, double? rating}) {
    return SessionModel(
      id: id,
      elderId: elderId,
      helperId: helperId,
      helper: helper,
      elder: elder,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      category: category,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      notes: notes,
    );
  }

  SessionModel copyWith2({UserModel? helper, UserModel? elder}) {
    return SessionModel(
      id: id,
      elderId: elderId,
      helperId: helperId,
      helper: helper ?? this.helper,
      elder: elder ?? this.elder,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      category: category,
      status: status,
      rating: rating,
      notes: notes,
    );
  }

  String get statusLabel {
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
