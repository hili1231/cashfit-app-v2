import 'package:cashfit/data/reward_task_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reward_task.dart';

class AdminCreateRewardTaskScreen extends StatefulWidget {
  const AdminCreateRewardTaskScreen({super.key});

  @override
  State<AdminCreateRewardTaskScreen> createState() =>
      _AdminCreateRewardTaskScreenState();
}

class _AdminCreateRewardTaskScreenState
    extends State<AdminCreateRewardTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController idController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  final TextEditingController maxCountController = TextEditingController();
  final TextEditingController buttonTextController = TextEditingController();

  RewardTask? selectedTask;
  List<RewardTask> tasks = [];
  RewardType type = RewardType.daily;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('rewards').get();
      if (!mounted) return;
      setState(() {
        tasks =
            snapshot.docs
                .map((doc) => RewardTask.fromJson(doc.data()))
                .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load tasks: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _loadTaskData(RewardTask task) {
    idController.text = task.id;
    titleController.text = task.title;
    descriptionController.text = task.description;
    pointsController.text = task.points.toString();
    maxCountController.text = task.maxCount.toString();
    buttonTextController.text = task.buttonText;
    setState(() {
      type = task.type;
      selectedTask = task;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final taskId = idController.text.trim().toLowerCase().replaceAll(' ', '_');
    final newTask = RewardTask(
      id: taskId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      points: int.parse(pointsController.text),
      type: type,
      maxCount: int.parse(maxCountController.text),
      isCompleted: false,
      isEnabled: false,
      buttonText: buttonTextController.text.trim(),
    );

    try {
      if (selectedTask != null) {
        await FirebaseFirestore.instance
            .collection('rewards')
            .doc(taskId)
            .update(newTask.toJson());
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("✅ Task updated successfully"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('rewards')
            .doc(taskId)
            .set(newTask.toJson());
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("✅ New task saved to database"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      setState(() {
        idController.clear();
        titleController.clear();
        descriptionController.clear();
        pointsController.clear();
        maxCountController.clear();
        buttonTextController.clear();
        selectedTask = null;
        type = RewardType.daily;
      });
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("⚠️ Error saving task: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _uploadStaticTasks() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await uploadTasksToFirebase();
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("✅ Static reward tasks uploaded successfully"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("⚠️ Error uploading static tasks: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(
    String label,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colorScheme.surfaceContainer,
    labelStyle: theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Manage Reward Tasks",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select Task
              DropdownButtonFormField<RewardTask>(
                value: selectedTask,
                decoration: _inputDecoration(
                  "Select Task to Edit",
                  theme,
                  colorScheme,
                ),
                isExpanded: true,
                dropdownColor: colorScheme.surfaceContainer,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items:
                    tasks.map((task) {
                      return DropdownMenuItem(
                        value: task,
                        child: Text(task.title),
                      );
                    }).toList(),
                onChanged: (task) {
                  if (task != null) {
                    _loadTaskData(task);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Task ID
              TextFormField(
                controller: idController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Task ID', theme, colorScheme),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: titleController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Title', theme, colorScheme),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: descriptionController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Description', theme, colorScheme),
                maxLines: 3,
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Points
              TextFormField(
                controller: pointsController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Points', theme, colorScheme),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reward Type
              DropdownButtonFormField<RewardType>(
                value: type,
                isExpanded: true,
                decoration: _inputDecoration("Reward Type", theme, colorScheme),
                dropdownColor: colorScheme.surfaceContainer,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items:
                    RewardType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => type = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Max Count
              TextFormField(
                controller: maxCountController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Max Count', theme, colorScheme),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Button Text
              TextFormField(
                controller: buttonTextController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: _inputDecoration('Button Text', theme, colorScheme),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveTask,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                ),
                child: Text(
                  selectedTask != null ? "Update Task" : "Save New Task",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Static Tasks
              ElevatedButton.icon(
                onPressed: _uploadStaticTasks,
                icon: Icon(Icons.upload_file, color: colorScheme.onSurface),
                label: Text(
                  "Upload Static Reward Tasks",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainer,
                  ),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
