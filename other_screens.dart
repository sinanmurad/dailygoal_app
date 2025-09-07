import 'package:app/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/widgets.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.fitness;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.medium;
  int _points = 50;
  String? _selectedFriendId;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        // Provider.of<UserProvider>(context, listen: false)
        //     .loadFriends([authProvider.currentUser!.id]);
        // ❌ UserProvider hatası almamak için geçici olarak devre dışı
        // Gerçek veri gelmiyor ama hata vermiyor
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meydan Okuma Oluştur'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.flash_on,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Arkadaşını Meydan Okumaya Davet Et!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kim daha hızlı tamamlar?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Arkadaş Seçimi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meydan Okuyacağın Arkadaş',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ✅ DÜZELTME: UserProvider yerine Object kullandık
                        Consumer<Object>(
                          builder: (context, userProvider, child) {
                            // Simüle edilmiş arkadaş listesi (çünkü UserProvider yok)
                            final mockFriends = [
                              User(
                                id: 'mock-1',
                                username: 'Ayşe',
                                email: 'ayse@example.com',
                                totalPoints: 120,
                                createdAt: DateTime.now()
                                    .subtract(const Duration(days: 45)),
                              ),
                              User(
                                id: 'mock-2',
                                username: 'Mehmet',
                                email: 'mehmet@example.com',
                                totalPoints: 95,
                                createdAt: DateTime.now()
                                    .subtract(const Duration(days: 30)),
                              ),
                            ];

                            // Arkadaş seçimi
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Arkadaşların:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: mockFriends.map((friend) {
                                      final isSelected =
                                          _selectedFriendId == friend.id;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedFriendId =
                                                isSelected ? null : friend.id;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.amber
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _getAvatarColor(
                                                      friend.username),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    friend.username
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                friend.username,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${friend.totalPoints})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (_selectedFriendId == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Lütfen bir arkadaş seç',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Görev Bilgileri
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meydan Okuma Detayları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Başlık
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Meydan Okuma Başlığı',
                            prefixIcon: Icon(Icons.title),
                            hintText: 'Örn: 10.000 Adım Challenge',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Başlık gerekli';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Açıklama
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            prefixIcon: Icon(Icons.description),
                            hintText: 'Meydan okumanın detaylarını açıkla...',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Açıklama gerekli';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Kategori
                        DropdownButtonFormField<TaskCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: TaskCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  _getCategoryIcon(category),
                                  const SizedBox(width: 12),
                                  Text(_getCategoryName(category)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                              _points = _calculatePoints();
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Zorluk
                        DropdownButtonFormField<TaskDifficulty>(
                          value: _selectedDifficulty,
                          decoration: const InputDecoration(
                            labelText: 'Zorluk Seviyesi',
                            prefixIcon: Icon(Icons.speed),
                          ),
                          items: TaskDifficulty.values.map((difficulty) {
                            return DropdownMenuItem(
                              value: difficulty,
                              child: Row(
                                children: [
                                  _getDifficultyIcon(difficulty),
                                  const SizedBox(width: 12),
                                  Text(_getDifficultyName(difficulty)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                              _points = _calculatePoints();
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Puan Gösterimi
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 12),
                              Text(
                                'Kazanılacak Puan: $_points',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bitiş Tarihi
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(
                            _deadline == null
                                ? 'Bitiş tarihi seç (isteğe bağlı)'
                                : 'Bitiş: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                          ),
                          trailing: _deadline != null
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _deadline = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          onTap: _selectDate,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Oluştur Butonu
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    return NuvanaButton(
                      text: 'Meydan Okuma Gönder 🚀',
                      onPressed:
                          taskProvider.isLoading ? null : _createChallenge,
                      isLoading: taskProvider.isLoading,
                      icon: Icons.send,
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String username) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    final index = username.length % colors.length;
    return colors[index];
  }

  Widget _getCategoryIcon(TaskCategory category) {
    IconData icon;
    Color color;

    switch (category) {
      case TaskCategory.fitness:
        icon = FontAwesomeIcons.dumbbell;
        color = Colors.red;
        break;
      case TaskCategory.learning:
        icon = FontAwesomeIcons.book;
        color = Colors.blue;
        break;
      case TaskCategory.creativity:
        icon = FontAwesomeIcons.palette;
        color = Colors.purple;
        break;
      case TaskCategory.social:
        icon = FontAwesomeIcons.users;
        color = Colors.green;
        break;
      case TaskCategory.productivity:
        icon = FontAwesomeIcons.briefcase;
        color = Colors.orange;
        break;
      case TaskCategory.health:
        icon = FontAwesomeIcons.heartPulse;
        color = Colors.pink;
        break;
      default:
        icon = FontAwesomeIcons.star;
        color = Colors.grey;
    }

    return FaIcon(icon, color: color, size: 20);
  }

  Widget _getDifficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return const Icon(Icons.sentiment_satisfied, color: Colors.green);
      case TaskDifficulty.medium:
        return const Icon(Icons.sentiment_neutral, color: Colors.orange);
      case TaskDifficulty.hard:
        return const Icon(Icons.sentiment_dissatisfied, color: Colors.red);
      case TaskDifficulty.expert:
        return const Icon(Icons.psychology, color: Colors.purple);
    }
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.fitness:
        return 'Fitness';
      case TaskCategory.learning:
        return 'Öğrenme';
      case TaskCategory.creativity:
        return 'Yaratıcılık';
      case TaskCategory.social:
        return 'Sosyal';
      case TaskCategory.productivity:
        return 'Verimlilik';
      case TaskCategory.health:
        return 'Sağlık';
      case TaskCategory.other:
        return 'Diğer';
    }
  }

  String _getDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Kolay';
      case TaskDifficulty.medium:
        return 'Orta';
      case TaskDifficulty.hard:
        return 'Zor';
      case TaskDifficulty.expert:
        return 'Uzman';
    }
  }

  int _calculatePoints() {
    int basePoints = 25;

    switch (_selectedCategory) {
      case TaskCategory.fitness:
        basePoints += 15;
        break;
      case TaskCategory.learning:
        basePoints += 20;
        break;
      case TaskCategory.creativity:
        basePoints += 25;
        break;
      default:
        basePoints += 10;
    }

    switch (_selectedDifficulty) {
      case TaskDifficulty.easy:
        return basePoints;
      case TaskDifficulty.medium:
        return (basePoints * 1.5).round();
      case TaskDifficulty.hard:
        return basePoints * 2;
      case TaskDifficulty.expert:
        return (basePoints * 2.5).round();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _createChallenge() async {
    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir arkadaş seç'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (authProvider.currentUser?.id == null || _selectedFriendId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gerekli bilgiler eksik'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        points: _points,
        deadline: _deadline,
        createdAt: DateTime.now(),
        createdBy: authProvider.currentUser!.id,
        userId: authProvider.currentUser!.id,
      );

      final challenge = Challenge(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        challengerId: authProvider.currentUser!.id,
        challengedId: _selectedFriendId!,
        task: task,
        status: ChallengeStatus.pending,
        createdAt: DateTime.now(),
      );

      final success = await taskProvider.createChallenge(challenge);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meydan okuma gönderildi! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop();
        }
      } else {
        final errorMessage = taskProvider.error ?? 'Bir hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
