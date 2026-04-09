import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;

  const TaskState({this.tasks = const [], this.isLoading = false});

  TaskState copyWith({List<TaskModel>? tasks, bool? isLoading}) {
    return TaskState(tasks: tasks ?? this.tasks, isLoading: isLoading ?? this.isLoading);
  }
}

class TaskNotifier extends FamilyNotifier<TaskState, int> {
  @override
  TaskState build(int eventId) {
    loadTasks(eventId);
    return const TaskState(isLoading: true);
  }

  Future<void> loadTasks(int eventId) async {
    state = state.copyWith(isLoading: true);
    final tasks = await DatabaseService.getTasksForEvent(eventId);
    state = state.copyWith(tasks: tasks, isLoading: false);
  }

  Future<void> toggleTask(int taskId, bool isDone, int eventId) async {
    await DatabaseService.updateTaskDone(taskId, isDone);
    await loadTasks(eventId);
  }

  Future<void> addTask(String title, int eventId) async {
    if (title.trim().isEmpty) return;
    await DatabaseService.insertTask(TaskModel(eventId: eventId, title: title.trim()));
    await loadTasks(eventId);
  }

  Future<void> deleteTask(int taskId, int eventId) async {
    await DatabaseService.deleteTask(taskId);
    await loadTasks(eventId);
  }
}

final taskProvider = NotifierProviderFamily<TaskNotifier, TaskState, int>(TaskNotifier.new);
