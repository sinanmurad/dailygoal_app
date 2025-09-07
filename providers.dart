import 'package:flutter/material.dart';
import 'package:app/core/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// Theme Provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveThemeMode();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.toString().split('.').last);
  }
}

// Auth Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    _checkAuthStatus();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Düzeltilmiş login metodu - bool döndürüyor
  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // AuthService üzerinden login işlemi
      _currentUser = await _authService.login(usernameOrEmail, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register metodu
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(username, email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class TaskProvider extends ChangeNotifier {
  final Map<String, List<Like>> _challengeLikes = {};
  final Map<String, List<Comment>> _challengeComments = {};
  final TaskService _taskService;
  List<Task> _tasks = [];
  List<Challenge> _challenges = [];
  List<Challenge> _publicChallenges = []; // Yeni: public challenges listesi
  bool _isLoading = false;
  bool _isLoadingPublic = false; // Yeni: public challenges yüklenme durumu
  String? _error;
  List<User> _friends = []; // _friends değişkenini ekleyin

  List<User> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskProvider(this._taskService);

  List<Task> get tasks => _tasks;
  List<Challenge> get challenges => _challenges;
  List<Challenge> get publicChallenges => _publicChallenges; // Getter
  bool get isLoadingPublic => _isLoadingPublic; // Getter

  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();

  // Yeni: Public challenge'ları yükleme metodu
  Future<void> loadPublicChallenges() async {
    _isLoadingPublic = true;
    notifyListeners();

    try {
      _publicChallenges = await _taskService.getPublicChallenges();
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingPublic = false;
    notifyListeners();
  }

  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasks(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChallenges(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _challenges = await _taskService.getChallenges(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTask(Task task) async {
    try {
      final createdTask = await _taskService.createTask(task);
      _tasks.add(createdTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      final updatedTask = await _taskService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(String taskId, String userId) async {
    try {
      await _taskService.completeTask(taskId, userId);
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createChallenge(Challenge challenge) async {
    try {
      final createdChallenge = await _taskService.createChallenge(challenge);
      _challenges.add(createdChallenge);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChallenge(Challenge challenge) async {
    try {
      final updatedChallenge = await _taskService.updateChallenge(challenge);
      final index = _challenges.indexWhere((c) => c.id == challenge.id);
      if (index != -1) {
        _challenges[index] = updatedChallenge;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadChallengeLikes(String challengeId) async {
    try {
      final likes = await _taskService.getChallengeLikes(challengeId);
      _challengeLikes[challengeId] = likes;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadChallengeComments(String challengeId) async {
    try {
      final comments = await _taskService.getChallengeComments(challengeId);
      _challengeComments[challengeId] = comments;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleChallengeLike(String challengeId, String userId) async {
    try {
      await _taskService.toggleChallengeLike(challengeId, userId);
      await loadChallengeLikes(challengeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addChallengeComment(
      String challengeId, String userId, String text) async {
    try {
      await _taskService.addChallengeComment(challengeId, userId, text);
      await loadChallengeComments(challengeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addFriend(String friendId) async {
    try {
      final friend = User(
        id: friendId,
        username: 'New Friend',
        email: 'newfriend@example.com',
        totalPoints: 0,
        createdAt: DateTime.now(),
      );
      _friends.add(friend);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      _friends.removeWhere((friend) => friend.id == friendId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  int getChallengeLikes(String challengeId) {
    return _challengeLikes[challengeId]?.length ?? 0;
  }

  bool isChallengeLiked(String challengeId, String userId) {
    return _challengeLikes[challengeId]
            ?.any((like) => like.user.id == userId) ??
        false;
  }

  List<Comment> getChallengeComments(String challengeId) {
    return _challengeComments[challengeId] ?? [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
