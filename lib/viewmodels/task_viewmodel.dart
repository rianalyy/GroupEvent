import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/guest_model.dart';
import '../services/database_service.dart';

class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final bool isDistributing;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isDistributing = false,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    bool? isDistributing,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isDistributing: isDistributing ?? this.isDistributing,
    );
  }

  int get totalTasks => tasks.length;
  int get doneTasks => tasks.where((t) => t.isDone).length;
  double get progressPercent => totalTasks > 0 ? doneTasks / totalTasks : 0.0;

  Map<int?, List<TaskModel>> get tasksByGuest {
    final map = <int?, List<TaskModel>>{};
    for (final task in tasks) {
      map.putIfAbsent(task.assignedToGuestId, () => []).add(task);
    }
    return map;
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

  Future<void> assignTask(int taskId, int? guestId, int eventId) async {
    await DatabaseService.updateTaskAssignment(taskId, guestId);
    await loadTasks(eventId);
  }

  // Répartition automatique  des tâches 
  Future<String> autoDistribute(List<GuestModel> guests, int eventId) async {
    if (guests.isEmpty) {
      return 'Aucun invité disponible pour la répartition.';
    }
    if (state.tasks.isEmpty) {
      return 'Aucune tâche à répartir.';
    }

    state = state.copyWith(isDistributing: true);

    final allTasks = state.tasks;
    final n = guests.length;

    for (var i = 0; i < allTasks.length; i++) {
      final assignedGuest = guests[i % n];
      await DatabaseService.updateTaskAssignment(allTasks[i].id!, assignedGuest.id);
    }

    await loadTasks(eventId);
    state = state.copyWith(isDistributing: false);

    final tasksPerPerson = (allTasks.length / n).floor();
    final extra = allTasks.length % n;
    if (extra == 0) {
      return '${allTasks.length} tâches réparties : $tasksPerPerson tâche(s) par participant.';
    } else {
      return '${allTasks.length} tâches réparties : $tasksPerPerson ou ${tasksPerPerson + 1} tâche(s) par participant.';
    }
  }

  Future<void> clearAssignments(int eventId) async {
    for (final task in state.tasks) {
      if (task.assignedToGuestId != null) {
        await DatabaseService.updateTaskAssignment(task.id!, null);
      }
    }
    await loadTasks(eventId);
  }
}

final taskProvider = NotifierProviderFamily<TaskNotifier, TaskState, int>(
  TaskNotifier.new,
);
