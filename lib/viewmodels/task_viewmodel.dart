import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/guest_model.dart';
import '../models/user_model.dart';
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

  TaskState copyWith({List<TaskModel>? tasks, bool? isLoading, bool? isDistributing}) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isDistributing: isDistributing ?? this.isDistributing,
    );
  }

  int get totalTasks => tasks.length;
  int get doneTasks => tasks.where((t) => t.isDone).length;
  double get progressPercent => totalTasks > 0 ? doneTasks / totalTasks : 0.0;

  List<TaskModel> tasksForUser(int userId) =>
      tasks.where((t) => t.assignedToUserId == userId).toList();

  List<TaskModel> tasksForGuest(int guestId) =>
      tasks.where((t) => t.assignedToGuestId == guestId).toList();

  List<TaskModel> get unassignedTasks =>
      tasks.where((t) => !t.hasAssignee).toList();
}

class TaskNotifier extends FamilyNotifier<TaskState, int> {
  @override
  TaskState build(int eventId) {
    Future.microtask(() => loadTasks(eventId));
    return const TaskState(isLoading: true);
  }

  Future<void> loadTasks(int eventId) async {
    state = state.copyWith(isLoading: true);
    final tasks = await DatabaseService.getTasksForEvent(eventId);
    state = TaskState(tasks: tasks, isLoading: false);
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

  Future<void> assignToGuest(int taskId, int? guestId, int eventId) async {
    await DatabaseService.updateTaskAssignment(taskId, guestId: guestId, userId: null);
    await loadTasks(eventId);
  }

  Future<void> assignToUser(int taskId, int userId, int eventId) async {
    await DatabaseService.updateTaskAssignment(taskId, guestId: null, userId: userId);
    await loadTasks(eventId);
  }

  Future<void> unassign(int taskId, int eventId) async {
    await DatabaseService.updateTaskAssignment(taskId, guestId: null, userId: null);
    await loadTasks(eventId);
  }

  Future<String> autoDistribute({
    required List<GuestModel> allGuests,
    required UserModel creator,
    required int eventId,
  }) async {
    if (state.tasks.isEmpty) return 'Aucune tâche à répartir.';

    final confirmedGuests = allGuests
        .where((g) => g.rsvpStatus == RsvpStatus.oui)
        .toList();

    state = state.copyWith(isDistributing: true);
    final allTasks = List<TaskModel>.from(state.tasks);
    final totalParticipants = confirmedGuests.length + 1;

    for (var i = 0; i < allTasks.length; i++) {
      final slot = i % totalParticipants;
      if (slot == 0) {
        await DatabaseService.updateTaskAssignment(
            allTasks[i].id!, guestId: null, userId: creator.id);
      } else {
        await DatabaseService.updateTaskAssignment(
            allTasks[i].id!, guestId: confirmedGuests[slot - 1].id, userId: null);
      }
    }

    await loadTasks(eventId);
    state = state.copyWith(isDistributing: false);

    final base = allTasks.length ~/ totalParticipants;
    final extra = allTasks.length % totalParticipants;
    final detail = extra == 0
        ? '$base tâche(s) par participant'
        : '$base ou ${base + 1} tâche(s) par participant';

    return '${allTasks.length} tâche(s) réparties entre $totalParticipants confirmés ($detail).';
  }
}

final taskProvider =
    NotifierProviderFamily<TaskNotifier, TaskState, int>(TaskNotifier.new);
