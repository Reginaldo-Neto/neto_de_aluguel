enum UserRole { elder, helper }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final List<String> categories;
  final double rating;
  final int totalSessions;
  final String? bio;
  final double? hourlyRate;
  final bool isAvailable;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.categories = const [],
    this.rating = 0.0,
    this.totalSessions = 0,
    this.bio,
    this.hourlyRate,
    this.isAvailable = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] == 'helper' ? UserRole.helper : UserRole.elder,
      avatarUrl: json['avatar_url'] as String?,
      categories: List<String>.from(json['categories'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (json['total_sessions'] as int?) ?? 0,
      bio: json['bio'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role == UserRole.helper ? 'helper' : 'elder',
        'avatar_url': avatarUrl,
        'categories': categories,
        'rating': rating,
        'total_sessions': totalSessions,
        'bio': bio,
        'hourly_rate': hourlyRate,
        'is_available': isAvailable,
      };

  UserModel copyWith({
    String? name,
    bool? isAvailable,
    List<String>? categories,
    String? bio,
    double? hourlyRate,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      avatarUrl: avatarUrl,
      categories: categories ?? this.categories,
      rating: rating,
      totalSessions: totalSessions,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

const mockHelpers = [
  UserModel(
    id: 'h1',
    name: 'Ana Paula Silva',
    email: 'ana@example.com',
    role: UserRole.helper,
    categories: ['Companhia', 'Tecnologia'],
    rating: 4.9,
    totalSessions: 124,
    bio:
        'Adoro conversar e ajudar com tecnologia. Sou muito paciente e carinhosa.',
    hourlyRate: 35.0,
    isAvailable: true,
  ),
  UserModel(
    id: 'h2',
    name: 'Carlos Eduardo Matos',
    email: 'carlos@example.com',
    role: UserRole.helper,
    categories: ['Tecnologia', 'Administrativo'],
    rating: 4.7,
    totalSessions: 89,
    bio: 'Especialista em ajudar com celular, computador e contas.',
    hourlyRate: 40.0,
    isAvailable: true,
  ),
  UserModel(
    id: 'h3',
    name: 'Fernanda Lima',
    email: 'fernanda@example.com',
    role: UserRole.helper,
    categories: ['Companhia', 'Recreação'],
    rating: 5.0,
    totalSessions: 203,
    bio: 'Amo jogos, histórias e atividades lúdicas. Especializei-me em idosos.',
    hourlyRate: 30.0,
    isAvailable: false,
  ),
  UserModel(
    id: 'h4',
    name: 'Roberto Oliveira',
    email: 'roberto@example.com',
    role: UserRole.helper,
    categories: ['Saúde', 'Administrativo'],
    rating: 4.8,
    totalSessions: 67,
    bio: 'Auxílio com saúde, organização de medicamentos e consultas médicas.',
    hourlyRate: 45.0,
    isAvailable: true,
  ),
  UserModel(
    id: 'h5',
    name: 'Juliana Costa',
    email: 'juliana@example.com',
    role: UserRole.helper,
    categories: ['Recreação', 'Companhia'],
    rating: 4.6,
    totalSessions: 45,
    bio: 'Aulas de música, leitura e atividades criativas para todas as idades.',
    hourlyRate: 28.0,
    isAvailable: true,
  ),
];
