/// Modelo para una tarea
class TaskItem {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? category;
  final int priority; // 1: baja, 2: media, 3: alta
  final bool hasAlarm;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.category,
    this.priority = 2,
    this.hasAlarm = false,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? category,
    int? priority,
    bool? hasAlarm,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      hasAlarm: hasAlarm ?? this.hasAlarm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'category': category,
    'priority': priority,
    'hasAlarm': hasAlarm,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    isCompleted: json['isCompleted'] ?? false,
    category: json['category'],
    priority: json['priority'] ?? 2,
    hasAlarm: json['hasAlarm'] ?? false,
  );
}

/// Modelo para un recordatorio
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool isCompleted;
  final bool repeat;
  final String? repeatType; // daily, weekly, monthly
  final bool hasAlarm;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.repeat = false,
    this.repeatType,
    this.hasAlarm = true,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    bool? repeat,
    String? repeatType,
    bool? hasAlarm,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      repeat: repeat ?? this.repeat,
      repeatType: repeatType ?? this.repeatType,
      hasAlarm: hasAlarm ?? this.hasAlarm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'isCompleted': isCompleted,
    'repeat': repeat,
    'repeatType': repeatType,
    'hasAlarm': hasAlarm,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dateTime: DateTime.parse(json['dateTime']),
    isCompleted: json['isCompleted'] ?? false,
    repeat: json['repeat'] ?? false,
    repeatType: json['repeatType'],
    hasAlarm: json['hasAlarm'] ?? true,
  );
}

/// Modelo para una receta
class Recipe {
  final String id;
  final String title;
  final String? description;
  final List<String> ingredients;
  final List<String> steps;
  final int? prepTime; // en minutos
  final int? cookTime; // en minutos
  final String? category; // desayuno, almuerzo, cena, postre, snack
  final DateTime createdAt;
  final bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.ingredients,
    required this.steps,
    this.prepTime,
    this.cookTime,
    this.category,
    required this.createdAt,
    this.isFavorite = false,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    int? prepTime,
    int? cookTime,
    String? category,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  int get totalTime => (prepTime ?? 0) + (cookTime ?? 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'ingredients': ingredients,
    'steps': steps,
    'prepTime': prepTime,
    'cookTime': cookTime,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    ingredients: List<String>.from(json['ingredients'] ?? []),
    steps: List<String>.from(json['steps'] ?? []),
    prepTime: json['prepTime'],
    cookTime: json['cookTime'],
    category: json['category'],
    createdAt: DateTime.parse(json['createdAt']),
    isFavorite: json['isFavorite'] ?? false,
  );
}

/// Modelo para un evento del calendario
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? color; // hex color
  final String? category;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    this.color,
    this.category,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? color,
    String? category,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isAllDay': isAllDay,
    'color': color,
    'category': category,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    startDate: DateTime.parse(json['startDate']),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    isAllDay: json['isAllDay'] ?? false,
    color: json['color'],
    category: json['category'],
  );
}

/// Modelo para una nota rápida
class QuickNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? color;

  QuickNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.color,
  });

  QuickNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return QuickNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'color': color,
  };

  factory QuickNote.fromJson(Map<String, dynamic> json) => QuickNote(
    id: json['id'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
    color: json['color'],
  );
}
