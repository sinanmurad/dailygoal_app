import 'package:app/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/widgets.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final task = taskProvider.tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => Task(
            id: taskId,
            title: 'Görev Bulunamadı',
            description: 'Bu görev mevcut değil.',
            category: TaskCategory.other,
            difficulty: TaskDifficulty.easy,
            points: 0,
            createdAt: DateTime.now(),
            createdBy: '',
            userId: '',
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              if (!task.isCompleted)
                IconButton(
                  onPressed: () {
                    taskProvider.completeTask(task.id, task.userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Görev tamamlandı! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Görev Kartı
                TaskCard(
                  task: task,
                  showCompleteButton: false,
                ),

                const SizedBox(height: 24),

                // Açıklama
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Açıklama',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Detaylar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detaylar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.star,
                          label: 'Puan',
                          value: '${task.points}',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.speed,
                          label: 'Zorluk',
                          value: _getDifficultyText(task.difficulty),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.category,
                          label: 'Kategori',
                          value: _getCategoryText(task.category),
                        ),
                        if (task.deadline != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.schedule,
                            label: 'Bitiş Tarihi',
                            value: DateFormat('dd/MM/yyyy HH:mm')
                                .format(task.deadline!),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          label: 'Durum',
                          value:
                              task.isCompleted ? 'Tamamlandı' : 'Devam Ediyor',
                        ),
                        if (task.completedAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.event_available,
                            label: 'Tamamlanma Tarihi',
                            value: DateFormat('dd/MM/yyyy HH:mm')
                                .format(task.completedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getDifficultyText(TaskDifficulty difficulty) {
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

  String _getCategoryText(TaskCategory category) {
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
}
