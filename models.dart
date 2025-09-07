class User {
  final String id;
  final String username;
  final String email;
  final int totalPoints;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.totalPoints,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      totalPoints: map['total_points'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'total_points': totalPoints,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final int points;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? deadline;
  final DateTime createdAt;
  final String createdBy;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.points,
    this.isCompleted = false,
    this.completedAt,
    this.deadline,
    required this.createdAt,
    required this.createdBy,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.toString() == 'TaskCategory.${map['category']}',
        orElse: () => TaskCategory.other,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.toString() == 'TaskDifficulty.${map['difficulty']}',
        orElse: () => TaskDifficulty.easy,
      ),
      points: map['points'] ?? 0,
      isCompleted: map['is_completed'] ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      deadline:
          map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      createdAt: DateTime.parse(map['created_at']),
      createdBy: map['created_by']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'points': points,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskDifficulty? difficulty,
    int? points,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? deadline,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String challengerId;
  final String challengedId;
  final Task task;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final int? likes;
  final List<ChallengeComment>? comments;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengerId,
    required this.challengedId,
    required this.task,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.likes = 0,
    this.comments,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) {
    List<ChallengeComment> commentList = [];
    if (map['comments'] != null && map['comments'] is List) {
      commentList = (map['comments'] as List)
          .map((c) => ChallengeComment.fromMap(c))
          .toList();
    }

    return Challenge(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      challengerId: map['challenger_id']?.toString() ?? '',
      challengedId: map['challenged_id']?.toString() ?? '',
      task: Task.fromMap(map['tasks'] ?? {}),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.toString() == 'ChallengeStatus.${map['status']}',
        orElse: () => ChallengeStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at']),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'])
          : null,
      likes: map['likes_count'] ?? 0,
      comments: commentList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'challenger_id': challengerId,
      'challenged_id': challengedId,
      'task_id': task.id,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'likes_count': likes,
      'comments': comments?.map((c) => c.toMap()).toList(),
    };
  }
}

class Like {
  final String id;
  final String challengeId;
  final User user;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.challengeId,
    required this.user,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'],
      challengeId: json['challenge_id'],
      user: User.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      id: map['id'],
      challengeId: map['challenge_id'],
      user: User.fromMap(map['user']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Comment {
  final String id;
  final String challengeId;
  final User user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.challengeId,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      challengeId: json['challenge_id'],
      user: User.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      challengeId: map['challenge_id'],
      user: User.fromMap(map['user']),
      text: map['text'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

enum TaskCategory {
  fitness,
  learning,
  creativity,
  social,
  productivity,
  health,
  other,
}

enum TaskDifficulty {
  easy,
  medium,
  hard,
  expert,
}

enum ChallengeStatus {
  pending,
  accepted,
  completed,
  rejected,
  expired,
}

class ChallengeComment {
  final String id;
  final String challengeId;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  ChallengeComment({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory ChallengeComment.fromMap(Map<String, dynamic> map) {
    return ChallengeComment(
      id: map['id'].toString(),
      challengeId: map['challenge_id'].toString(),
      userId: map['user_id'].toString(),
      username: map['username'] ?? '',
      text: map['text'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'username': username,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
