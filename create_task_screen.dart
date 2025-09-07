import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/providers/providers.dart';
import 'package:app/core/models/models.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.other;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final newTask = Task(
        id: const Uuid().v4(),
        userId: authProvider.currentUser!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        points: _calculatePoints(_selectedDifficulty),
        isCompleted: false,
        createdAt: DateTime.now(),
        createdBy: authProvider.currentUser!.id,
      );

      final success = await taskProvider.createTask(newTask);

      if (success && mounted) {
        Navigator.pop(context); // Ekranı kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev başarıyla oluşturuldu')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taskProvider.error ?? 'Görev oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _calculatePoints(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.medium:
        return 25;
      case TaskDifficulty.hard:
        return 50;
      default:
        return 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Görev Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Görev Başlığı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
              ),
              DropdownButtonFormField<TaskCategory>(
                value: _selectedCategory,
                items: TaskCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              DropdownButtonFormField<TaskDifficulty>(
                value: _selectedDifficulty,
                items: TaskDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Zorluk'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createTask,
                child: const Text('Görev Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
