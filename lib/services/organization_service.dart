import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/organization_models.dart';

/// Servicio para persistir y recuperar datos de organización
class OrganizationService {
  static const String _tasksKey = 'aura_tasks';
  static const String _remindersKey = 'aura_reminders';
  static const String _recipesKey = 'aura_recipes';
  static const String _eventsKey = 'aura_events';
  static const String _notesKey = 'aura_notes';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== TASKS ====================

  Future<List<TaskItem>> getTasks() async {
    try {
      final String? data = _prefs?.getString(_tasksKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => TaskItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    try {
      final String data = jsonEncode(tasks.map((e) => e.toJson()).toList());
      await _prefs?.setString(_tasksKey, data);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // ==================== REMINDERS ====================

  Future<List<Reminder>> getReminders() async {
    try {
      final String? data = _prefs?.getString(_remindersKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => Reminder.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      return [];
    }
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      final String data = jsonEncode(reminders.map((e) => e.toJson()).toList());
      await _prefs?.setString(_remindersKey, data);
    } catch (e) {
      debugPrint('Error saving reminders: $e');
    }
  }

  // ==================== RECIPES ====================

  Future<List<Recipe>> getRecipes() async {
    try {
      final String? data = _prefs?.getString(_recipesKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => Recipe.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      return [];
    }
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    try {
      final String data = jsonEncode(recipes.map((e) => e.toJson()).toList());
      await _prefs?.setString(_recipesKey, data);
    } catch (e) {
      debugPrint('Error saving recipes: $e');
    }
  }

  // ==================== EVENTS ====================

  Future<List<CalendarEvent>> getEvents() async {
    try {
      final String? data = _prefs?.getString(_eventsKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading events: $e');
      return [];
    }
  }

  Future<void> saveEvents(List<CalendarEvent> events) async {
    try {
      final String data = jsonEncode(events.map((e) => e.toJson()).toList());
      await _prefs?.setString(_eventsKey, data);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  // ==================== NOTES ====================

  Future<List<QuickNote>> getNotes() async {
    try {
      final String? data = _prefs?.getString(_notesKey);
      if (data == null) return [];
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => QuickNote.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading notes: $e');
      return [];
    }
  }

  Future<void> saveNotes(List<QuickNote> notes) async {
    try {
      final String data = jsonEncode(notes.map((e) => e.toJson()).toList());
      await _prefs?.setString(_notesKey, data);
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  // ==================== CLEAR ALL ====================

  Future<void> clearAll() async {
    await _prefs?.remove(_tasksKey);
    await _prefs?.remove(_remindersKey);
    await _prefs?.remove(_recipesKey);
    await _prefs?.remove(_eventsKey);
    await _prefs?.remove(_notesKey);
  }
}
