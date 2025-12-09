import 'package:flutter/foundation.dart';
import '../models/organization_models.dart';
import '../services/organization_service.dart';

/// Provider para gestionar el estado de organización
class OrganizationProvider extends ChangeNotifier {
  final OrganizationService _service = OrganizationService();

  List<TaskItem> _tasks = [];
  List<Reminder> _reminders = [];
  List<Recipe> _recipes = [];
  List<CalendarEvent> _events = [];
  List<QuickNote> _notes = [];

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  // Getters
  List<TaskItem> get tasks => _tasks;
  List<Reminder> get reminders => _reminders;
  List<Recipe> get recipes => _recipes;
  List<CalendarEvent> get events => _events;
  List<QuickNote> get notes => _notes;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  // Getters filtrados
  List<TaskItem> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();
  List<TaskItem> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<Reminder> get upcomingReminders =>
      _reminders
          .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<CalendarEvent> get eventsForSelectedDate => _events
      .where(
        (e) =>
            e.startDate.year == _selectedDate.year &&
            e.startDate.month == _selectedDate.month &&
            e.startDate.day == _selectedDate.day,
      )
      .toList();

  List<TaskItem> get tasksForSelectedDate => _tasks
      .where(
        (t) =>
            t.dueDate != null &&
            t.dueDate!.year == _selectedDate.year &&
            t.dueDate!.month == _selectedDate.month &&
            t.dueDate!.day == _selectedDate.day,
      )
      .toList();

  /// Inicializar provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.init();
      _tasks = await _service.getTasks();
      _reminders = await _service.getReminders();
      _recipes = await _service.getRecipes();
      _events = await _service.getEvents();
      _notes = await _service.getNotes();
    } catch (e) {
      debugPrint('Error initializing OrganizationProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambiar fecha seleccionada
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ==================== TASKS ====================

  Future<void> addTask(TaskItem task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _service.saveTasks(_tasks);
  }

  Future<void> updateTask(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
      await _service.saveTasks(_tasks);
    }
  }

  Future<void> toggleTaskComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
      await _service.saveTasks(_tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _service.saveTasks(_tasks);
  }

  // ==================== REMINDERS ====================

  Future<void> addReminder(Reminder reminder) async {
    _reminders.insert(0, reminder);
    notifyListeners();
    await _service.saveReminders(_reminders);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      notifyListeners();
      await _service.saveReminders(_reminders);
    }
  }

  Future<void> toggleReminderComplete(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: !_reminders[index].isCompleted,
      );
      notifyListeners();
      await _service.saveReminders(_reminders);
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    notifyListeners();
    await _service.saveReminders(_reminders);
  }

  // ==================== RECIPES ====================

  Future<void> addRecipe(Recipe recipe) async {
    _recipes.insert(0, recipe);
    notifyListeners();
    await _service.saveRecipes(_recipes);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = recipe;
      notifyListeners();
      await _service.saveRecipes(_recipes);
    }
  }

  Future<void> toggleRecipeFavorite(String recipeId) async {
    final index = _recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      _recipes[index] = _recipes[index].copyWith(
        isFavorite: !_recipes[index].isFavorite,
      );
      notifyListeners();
      await _service.saveRecipes(_recipes);
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    _recipes.removeWhere((r) => r.id == recipeId);
    notifyListeners();
    await _service.saveRecipes(_recipes);
  }

  // ==================== EVENTS ====================

  Future<void> addEvent(CalendarEvent event) async {
    _events.insert(0, event);
    notifyListeners();
    await _service.saveEvents(_events);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
      await _service.saveEvents(_events);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
    await _service.saveEvents(_events);
  }

  // ==================== NOTES ====================

  Future<void> addNote(QuickNote note) async {
    _notes.insert(0, note);
    notifyListeners();
    await _service.saveNotes(_notes);
  }

  Future<void> updateNote(QuickNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      notifyListeners();
      await _service.saveNotes(_notes);
    }
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _service.saveNotes(_notes);
  }

  // ==================== AI HELPERS ====================

  /// Crear tarea desde texto de IA
  Future<TaskItem> createTaskFromAI({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 2,
    String? category,
  }) async {
    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      category: category,
    );
    await addTask(task);
    return task;
  }

  /// Crear recordatorio desde texto de IA
  Future<Reminder> createReminderFromAI({
    required String title,
    String? description,
    required DateTime dateTime,
    bool repeat = false,
    String? repeatType,
  }) async {
    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dateTime: dateTime,
      repeat: repeat,
      repeatType: repeatType,
    );
    await addReminder(reminder);
    return reminder;
  }

  /// Crear receta desde texto de IA
  Future<Recipe> createRecipeFromAI({
    required String title,
    String? description,
    required List<String> ingredients,
    required List<String> steps,
    int? prepTime,
    int? cookTime,
    String? category,
  }) async {
    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      ingredients: ingredients,
      steps: steps,
      prepTime: prepTime,
      cookTime: cookTime,
      category: category,
      createdAt: DateTime.now(),
    );
    await addRecipe(recipe);
    return recipe;
  }

  /// Crear evento desde texto de IA
  Future<CalendarEvent> createEventFromAI({
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = false,
    String? category,
  }) async {
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      category: category,
    );
    await addEvent(event);
    return event;
  }

  /// Obtener resumen para IA
  String getSummaryForAI() {
    final pendingCount = pendingTasks.length;
    final upcomingRemindersCount = upcomingReminders.length;
    final todayEvents = eventsForSelectedDate.length;
    final recipesCount = recipes.length;

    return '''
Estado actual de organización:
- Tareas pendientes: $pendingCount
- Recordatorios próximos: $upcomingRemindersCount
- Eventos hoy: $todayEvents
- Recetas guardadas: $recipesCount
''';
  }

  /// Obtener fechas con eventos/tareas para el calendario
  Set<DateTime> getDatesWithItems() {
    final dates = <DateTime>{};

    for (final task in _tasks) {
      if (task.dueDate != null) {
        dates.add(
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day),
        );
      }
    }

    for (final event in _events) {
      dates.add(
        DateTime(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        ),
      );
    }

    for (final reminder in _reminders) {
      dates.add(
        DateTime(
          reminder.dateTime.year,
          reminder.dateTime.month,
          reminder.dateTime.day,
        ),
      );
    }

    return dates;
  }
}
