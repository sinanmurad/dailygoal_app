import 'package:app/core/models/models.dart' show User, Challenge;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/models.dart' as models;

// AuthService sınıfı
class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<User?> getCurrentUser() async {
    // Mevcut kullanıcıyı getirme implementasyonu
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData =
            await _supabase.from('users').select().eq('id', user.id).single();
        return User.fromMap(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  Future<User> login(String usernameOrEmail, String password) async {
    try {
      // Demo hesap kontrolü
      if ((usernameOrEmail == 'demo' ||
              usernameOrEmail == 'demo@example.com') &&
          password == 'demo123') {
        return User(
          id: 'demo-user-id',
          username: 'Demo User',
          email: 'demo@example.com',
          totalPoints: 150,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );
      }

      String email;
      final isEmail = usernameOrEmail.contains('@');

      if (isEmail) {
        // Doğrudan e-posta ile giriş
        email = usernameOrEmail;
      } else {
        try {
          // Kullanıcı adı ile giriş - önce profiles tablosundan e-postayı bul
          final profileResponse = await _supabase
              .from('profiles')
              .select('email')
              .eq('username', usernameOrEmail)
              .single();

          email = profileResponse['email'];
        } catch (e) {
          // Eğer profiles tablosunda bulunamazsa, public.users tablosunda arama yap
          try {
            final userResponse = await _supabase
                .from('users')
                .select('email')
                .eq('username', usernameOrEmail)
                .single();

            email = userResponse['email'];
          } catch (e) {
            throw Exception(
                'Bu kullanıcı adına sahip bir kullanıcı bulunamadı');
          }
        }
      }

      // Auth ile giriş yap
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Giriş başarısız');
      }

      // Kullanıcı bilgilerini public.users tablosundan al
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return User.fromMap(userResponse);
    } catch (e) {
      throw Exception('Giriş yapılamadı: ${e.toString()}');
    }
  }

  Future<User> register(String username, String email, String password) async {
    try {
      // Önce auth'a kayıt
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Kayıt başarısız');
      }

      // Sonra users tablosuna kullanıcı bilgilerini ekle
      final newUser = User(
        id: authResponse.user!.id,
        username: username,
        email: email,
        totalPoints: 0,
        createdAt: DateTime.now(),
      );

      await _supabase.from('users').insert(newUser.toMap());

      return newUser;
    } catch (e) {
      throw Exception('Kayıt yapılamadı: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}

// Arkadaşlık işlemleri için yeni metodlar
Future<Map<String, dynamic>> addFriend(
    String friendId, dynamic _supabase) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    final response = await _supabase
        .from('friendships')
        .insert({
          'user_id': user.id,
          'friend_id': friendId,
          'status': 'pending',
        })
        .select()
        .single();

    return response;
  } catch (e) {
    throw Exception('Arkadaş eklenemedi: $e');
  }
}

Future<List<Map<String, dynamic>>> getFriends(dynamic _supabase) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    final response = await _supabase
        .from('friendships')
        .select('*, profiles!friendships_friend_id_fkey(*)')
        .or('user_id.eq.${user.id},friend_id.eq.${user.id}')
        .eq('status', 'accepted');

    return response;
  } catch (e) {
    throw Exception('Arkadaşlar alınamadı: $e');
  }
}

Future<List<Map<String, dynamic>>> getPendingRequests(dynamic _supabase) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    final response = await _supabase
        .from('friendships')
        .select('*, profiles!friendships_user_id_fkey(*)')
        .eq('friend_id', user.id)
        .eq('status', 'pending');

    return response;
  } catch (e) {
    throw Exception('Bekleyen istekler alınamadı: $e');
  }
}

// TaskService sınıfını da buraya ekleyin (eğer varsa)

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<models.Task>> getTasks(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((taskData) => models.Task.fromMap(taskData))
          .toList();
    } catch (e) {
      throw Exception('Görevler alınamadı: $e');
    }
  }

  Future<models.Task> updateTask(models.Task task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .update(task.toMap())
          .eq('id', task.id)
          .select()
          .single();

      return models.Task.fromMap(response);
    } catch (e) {
      throw Exception('Görev güncellenemedi: $e');
    }
  }

  Future<void> completeTask(String taskId, String userId) async {
    try {
      await _supabase
          .from('tasks')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Görev tamamlanamadı: $e');
    }
  }

  Future<List<models.Challenge>> getChallenges(String userId) async {
    try {
      final response = await _supabase
          .from('challenges_with_stats')
          .select()
          .or('challenger_id.eq.$userId,challenged_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((challengeData) => models.Challenge.fromMap(challengeData))
          .toList();
    } catch (e) {
      throw Exception('Meydan okumalar alınamadı: $e');
    }
  }
// TaskService'e aşağıdaki metodları ekleyin

// Beğenileri getir

  Future<List<models.Like>> getChallengeLikes(String challengeId) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al
      final response = await supabase
          .from('challenge_likes')
          .select('*, user:user_id(*)')
          .eq('challenge_id', challengeId)
          .order('created_at', ascending: false);

      return response.map((data) => models.Like.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching likes: $e');
      throw Exception('Failed to load likes');
    }
  }

// Beğeni ekle/kaldır
  Future<void> toggleChallengeLike(String challengeId, String userId) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al

      // Önce beğeni var mı kontrol et
      final existingLike = await supabase
          .from('challenge_likes')
          .select()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId)
          .maybeSingle()
          .catchError((_) => null);

      if (existingLike != null) {
        // Beğeni varsa kaldır
        await supabase
            .from('challenge_likes')
            .delete()
            .eq('challenge_id', challengeId)
            .eq('user_id', userId);
      } else {
        // Beğeni yoksa ekle
        await supabase.from('challenge_likes').insert({
          'challenge_id': challengeId,
          'user_id': userId,
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      throw Exception('Failed to toggle like');
    }
  }

// Yorumları getir
  Future<List<models.Comment>> getChallengeComments(String challengeId) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al
      final response = await supabase
          .from('challenge_comments')
          .select('*, user:user_id(*)')
          .eq('challenge_id', challengeId)
          .order('created_at', ascending: false);

      return response.map((data) => models.Comment.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Failed to load comments');
    }
  }

// Yorum ekle
  Future<models.Comment> addChallengeComment(
      String challengeId, String userId, String text) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al
      final response = await supabase
          .from('challenge_comments')
          .insert({
            'challenge_id': challengeId,
            'user_id': userId,
            'text': text,
          })
          .select('*, user:user_id(*)')
          .single();

      return models.Comment.fromMap(response);
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  Future<models.Challenge> createChallenge(models.Challenge challenge) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al
      final taskResponse = await createTask(challenge.task);

      // Challenge oluştururken task_id'yi yeni oluşturulan task'ın ID'si ile güncelle
      final challengeData = challenge.toMap();
      challengeData['task_id'] = taskResponse.id;

      final response = await supabase
          .from('challenges')
          .insert(challengeData)
          .select('*, tasks(*)')
          .single();

      return models.Challenge.fromMap(response);
    } catch (e) {
      throw Exception('Meydan okuma oluşturulamadı: $e');
    }
  }

// createTask metodunuzun da tanımlı olduğundan emin olun
  Future<models.Task> createTask(models.Task task) async {
    try {
      final supabase = Supabase.instance.client; // Supabase istemcisini al
      final response =
          await supabase.from('tasks').insert(task.toMap()).select().single();

      return models.Task.fromMap(response);
    } catch (e) {
      throw Exception('Görev oluşturulamadı: $e');
    }
  }
  // TaskService'e aşağıdaki metodu ekleyin:

// TaskService'e ekleyin
  Future<List<Challenge>> getPublicChallenges() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('challenges')
          .select('*, tasks(*)')
          .order('created_at', ascending: false);

      return response.map((data) => Challenge.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching public challenges: $e');
      throw Exception('Failed to load public challenges');
    }
  }

  Future<models.Challenge> updateChallenge(models.Challenge challenge) async {
    try {
      final response = await _supabase
          .from('challenges')
          .update(challenge.toMap())
          .eq('id', challenge.id)
          .select('*, tasks(*)')
          .single();

      return models.Challenge.fromMap(response);
    } catch (e) {
      throw Exception('Meydan okuma güncellenemedi: $e');
    }
  }

  // ✅ YENİ: BEGENI VE YORUM METOTLARI
  Future<void> toggleLike(String challengeId, String userId) async {
    final existing = await _supabase
        .from('likes')
        .select()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('likes')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } else {
      await _supabase.from('likes').insert({
        'challenge_id': challengeId,
        'user_id': userId,
      });
    }
  }

  Future<void> addComment(
      String challengeId, String userId, String username, String text) async {
    await _supabase.from('comments').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'username': username,
      'text': text,
    });
  }
}
