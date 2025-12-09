import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../models/organization_models.dart';
import '../providers/organization_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/aura_gradient_text.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: AuraColors.getBackgroundColor(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AuraColors.getTextPrimary(isDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AuraGradientText(
          'Organización',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AuraColors.getTextPrimary(isDark),
          unselectedLabelColor: AuraColors.getTextMuted(isDark),
          indicatorColor: AuraColors.getAccentColor(isDark),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendario'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Tareas'),
            Tab(
              icon: Icon(Icons.notifications_outlined),
              text: 'Recordatorios',
            ),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Recetas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(isDark),
          _buildTasksTab(isDark),
          _buildRemindersTab(isDark),
          _buildRecipesTab(isDark),
        ],
      ),
    );
  }

  // ==================== CALENDAR TAB ====================
  Widget _buildCalendarTab(bool isDark) {
    return Consumer<OrganizationProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildCalendarHeader(isDark, provider),
            _buildCalendarGrid(isDark, provider),
            const SizedBox(height: 16),
            Expanded(child: _buildDayEvents(isDark, provider)),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader(bool isDark, OrganizationProvider provider) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: AuraColors.getTextPrimary(isDark),
            ),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AuraColors.getTextPrimary(isDark),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: AuraColors.getTextPrimary(isDark),
            ),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCalendarGrid(bool isDark, OrganizationProvider provider) {
    final datesWithItems = provider.getDatesWithItems();
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days
                .map(
                  (day) => SizedBox(
                    width: 40,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AuraColors.getTextMuted(isDark),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Grid de días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayOffset,
              );
              final isSelected =
                  provider.selectedDate.year == date.year &&
                  provider.selectedDate.month == date.month &&
                  provider.selectedDate.day == date.day;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final hasItems = datesWithItems.contains(
                DateTime(date.year, date.month, date.day),
              );

              return GestureDetector(
                onTap: () => provider.setSelectedDate(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AuraColors.getAccentColor(isDark)
                        : isToday
                        ? AuraColors.getAccentColor(isDark).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayOffset',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AuraColors.getTextPrimary(isDark),
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasItems && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AuraColors.getAccentColor(isDark),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDayEvents(bool isDark, OrganizationProvider provider) {
    final events = provider.eventsForSelectedDate;
    final tasks = provider.tasksForSelectedDate;

    if (events.isEmpty && tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AuraColors.getTextMuted(isDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin eventos para este día',
              style: TextStyle(color: AuraColors.getTextMuted(isDark)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddEventDialog(isDark, provider),
              icon: const Icon(Icons.add),
              label: const Text('Agregar evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraColors.getAccentColor(isDark),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (events.isNotEmpty) ...[
          _buildSectionHeader(isDark, 'Eventos', Icons.event),
          ...events.map((e) => _buildEventCard(isDark, e, provider)),
        ],
        if (tasks.isNotEmpty) ...[
          _buildSectionHeader(isDark, 'Tareas', Icons.check_circle_outline),
          ...tasks.map((t) => _buildTaskCard(isDark, t, provider)),
        ],
      ],
    );
  }

  // ==================== TASKS TAB ====================
  Widget _buildTasksTab(bool isDark) {
    return Consumer<OrganizationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Add task button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddTaskDialog(isDark, provider),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva tarea'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.getAccentColor(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            // Task filters
            _buildTaskFilters(isDark, provider),
            // Task list
            Expanded(
              child: provider.tasks.isEmpty
                  ? _buildEmptyState(
                      isDark,
                      'No tienes tareas',
                      Icons.check_circle_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.tasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(
                              isDark,
                              provider.tasks[index],
                              provider,
                            )
                            .animate()
                            .fadeIn(delay: (50 * index).ms)
                            .slideX(begin: 0.1);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskFilters(bool isDark, OrganizationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'Todas', provider.tasks.length, true),
          const SizedBox(width: 8),
          _buildFilterChip(
            isDark,
            'Pendientes',
            provider.pendingTasks.length,
            false,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            isDark,
            'Completadas',
            provider.completedTasks.length,
            false,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildFilterChip(
    bool isDark,
    String label,
    int count,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AuraColors.getAccentColor(isDark)
            : AuraColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          fontSize: 12,
          color: isSelected
              ? Colors.white
              : AuraColors.getTextSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    bool isDark,
    TaskItem task,
    OrganizationProvider provider,
  ) {
    final priorityColors = {1: Colors.green, 2: Colors.orange, 3: Colors.red};

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: priorityColors[task.priority] ?? Colors.grey,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => provider.toggleTaskComplete(task.id),
            activeColor: AuraColors.getAccentColor(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              color: AuraColors.getTextPrimary(isDark),
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: task.dueDate != null
              ? Text(
                  _formatDate(task.dueDate!),
                  style: TextStyle(
                    color: AuraColors.getTextMuted(isDark),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: task.category != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.getAccentColor(isDark).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category!,
                    style: TextStyle(
                      fontSize: 10,
                      color: AuraColors.getAccentColor(isDark),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ==================== REMINDERS TAB ====================
  Widget _buildRemindersTab(bool isDark) {
    return Consumer<OrganizationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Add reminder button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddReminderDialog(isDark, provider),
                      icon: const Icon(Icons.add_alert),
                      label: const Text('Nuevo recordatorio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.getAccentColor(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            // Reminder list
            Expanded(
              child: provider.reminders.isEmpty
                  ? _buildEmptyState(
                      isDark,
                      'No tienes recordatorios',
                      Icons.notifications_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.reminders.length,
                      itemBuilder: (context, index) {
                        return _buildReminderCard(
                              isDark,
                              provider.reminders[index],
                              provider,
                            )
                            .animate()
                            .fadeIn(delay: (50 * index).ms)
                            .slideX(begin: 0.1);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(
    bool isDark,
    Reminder reminder,
    OrganizationProvider provider,
  ) {
    final isPast = reminder.dateTime.isBefore(DateTime.now());

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteReminder(reminder.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast && !reminder.isCompleted
                ? Colors.orange.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : AuraColors.getAccentColor(isDark).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                reminder.isCompleted ? Icons.check : Icons.notifications_active,
                color: reminder.isCompleted
                    ? Colors.green
                    : AuraColors.getAccentColor(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      color: AuraColors.getTextPrimary(isDark),
                      fontWeight: FontWeight.w600,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AuraColors.getTextMuted(isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(reminder.dateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast && !reminder.isCompleted
                              ? Colors.orange
                              : AuraColors.getTextMuted(isDark),
                        ),
                      ),
                      if (reminder.repeat) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: AuraColors.getTextMuted(isDark),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: reminder.isCompleted,
              onChanged: (_) => provider.toggleReminderComplete(reminder.id),
              activeColor: AuraColors.getAccentColor(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RECIPES TAB ====================
  Widget _buildRecipesTab(bool isDark) {
    return Consumer<OrganizationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Add recipe button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddRecipeDialog(isDark, provider),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva receta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.getAccentColor(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            // Recipe list
            Expanded(
              child: provider.recipes.isEmpty
                  ? _buildEmptyState(
                      isDark,
                      'No tienes recetas guardadas',
                      Icons.restaurant_menu,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: provider.recipes.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(
                              isDark,
                              provider.recipes[index],
                              provider,
                            )
                            .animate()
                            .fadeIn(delay: (50 * index).ms)
                            .scale(begin: const Offset(0.95, 0.95));
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(
    bool isDark,
    Recipe recipe,
    OrganizationProvider provider,
  ) {
    final categoryIcons = {
      'desayuno': Icons.free_breakfast,
      'almuerzo': Icons.lunch_dining,
      'cena': Icons.dinner_dining,
      'postre': Icons.cake,
      'snack': Icons.cookie,
    };

    return GestureDetector(
      onTap: () => _showRecipeDetail(isDark, recipe, provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AuraColors.getAccentColor(isDark).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    categoryIcons[recipe.category?.toLowerCase()] ??
                        Icons.restaurant,
                    color: AuraColors.getAccentColor(isDark),
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.toggleRecipeFavorite(recipe.id),
                  child: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: recipe.isFavorite
                        ? Colors.red
                        : AuraColors.getTextMuted(isDark),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.title,
              style: TextStyle(
                color: AuraColors.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (recipe.totalTime > 0)
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AuraColors.getTextMuted(isDark),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.totalTime} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: AuraColors.getTextMuted(isDark),
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.list,
                  size: 14,
                  color: AuraColors.getTextMuted(isDark),
                ),
                const SizedBox(width: 4),
                Text(
                  '${recipe.ingredients.length} ingredientes',
                  style: TextStyle(
                    fontSize: 11,
                    color: AuraColors.getTextMuted(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSectionHeader(bool isDark, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AuraColors.getTextSecondary(isDark)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AuraColors.getTextPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    bool isDark,
    CalendarEvent event,
    OrganizationProvider provider,
  ) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteEvent(event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: event.color != null
                  ? Color(int.parse(event.color!.replaceFirst('#', '0xFF')))
                  : AuraColors.getAccentColor(isDark),
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: AuraColors.getTextPrimary(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AuraColors.getTextMuted(isDark),
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    event.isAllDay
                        ? 'Todo el día'
                        : _formatTime(event.startDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AuraColors.getAccentColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AuraColors.getTextMuted(isDark)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AuraColors.getTextMuted(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pídele a Aura que te ayude a agregar',
            style: TextStyle(
              fontSize: 14,
              color: AuraColors.getTextMuted(isDark).withOpacity(0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ==================== DIALOGS ====================

  void _showAddTaskDialog(bool isDark, OrganizationProvider provider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    int priority = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva tarea',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                decoration: InputDecoration(
                  hintText: 'Título de la tarea',
                  hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                  filled: true,
                  fillColor: AuraColors.getSurfaceColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Descripción (opcional)',
                  hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                  filled: true,
                  fillColor: AuraColors.getSurfaceColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() => selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AuraColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AuraColors.getTextMuted(isDark),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate != null
                            ? _formatDate(selectedDate!)
                            : 'Fecha límite (opcional)',
                        style: TextStyle(
                          color: selectedDate != null
                              ? AuraColors.getTextPrimary(isDark)
                              : AuraColors.getTextMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Priority selector
              Text(
                'Prioridad',
                style: TextStyle(
                  color: AuraColors.getTextSecondary(isDark),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityButton(isDark, 'Baja', 1, priority, (p) {
                    setModalState(() => priority = p);
                  }),
                  const SizedBox(width: 8),
                  _buildPriorityButton(isDark, 'Media', 2, priority, (p) {
                    setModalState(() => priority = p);
                  }),
                  const SizedBox(width: 8),
                  _buildPriorityButton(isDark, 'Alta', 3, priority, (p) {
                    setModalState(() => priority = p);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      provider.addTask(
                        TaskItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : null,
                          createdAt: DateTime.now(),
                          dueDate: selectedDate,
                          priority: priority,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.getAccentColor(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Crear tarea'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(
    bool isDark,
    String label,
    int value,
    int current,
    Function(int) onTap,
  ) {
    final colors = {1: Colors.green, 2: Colors.orange, 3: Colors.red};
    final isSelected = value == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors[value]!.withOpacity(0.2)
                : AuraColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors[value]! : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? colors[value]
                  : AuraColors.getTextMuted(isDark),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog(bool isDark, OrganizationProvider provider) {
    final titleController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo recordatorio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                decoration: InputDecoration(
                  hintText: '¿Qué quieres recordar?',
                  hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                  filled: true,
                  fillColor: AuraColors.getSurfaceColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // DateTime picker
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setModalState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AuraColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AuraColors.getTextMuted(isDark),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDateTime(selectedDateTime),
                        style: TextStyle(
                          color: AuraColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      provider.addReminder(
                        Reminder(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          dateTime: selectedDateTime,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.getAccentColor(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Crear recordatorio'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog(bool isDark, OrganizationProvider provider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isAllDay = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nuevo evento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                decoration: InputDecoration(
                  hintText: 'Nombre del evento',
                  hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                  filled: true,
                  fillColor: AuraColors.getSurfaceColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Descripción (opcional)',
                  hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                  filled: true,
                  fillColor: AuraColors.getSurfaceColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Todo el día',
                    style: TextStyle(
                      color: AuraColors.getTextSecondary(isDark),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isAllDay,
                    onChanged: (v) => setModalState(() => isAllDay = v),
                    activeColor: AuraColors.getAccentColor(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      provider.addEvent(
                        CalendarEvent(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : null,
                          startDate: provider.selectedDate,
                          isAllDay: isAllDay,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.getAccentColor(isDark),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Crear evento'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRecipeDialog(bool isDark, OrganizationProvider provider) {
    final titleController = TextEditingController();
    final ingredientsController = TextEditingController();
    final stepsController = TextEditingController();
    String? category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva receta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AuraColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Nombre de la receta',
                    hintStyle: TextStyle(
                      color: AuraColors.getTextMuted(isDark),
                    ),
                    filled: true,
                    fillColor: AuraColors.getSurfaceColor(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AuraColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: category,
                    hint: Text(
                      'Categoría',
                      style: TextStyle(color: AuraColors.getTextMuted(isDark)),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AuraColors.getSurfaceColor(isDark),
                    items: ['Desayuno', 'Almuerzo', 'Cena', 'Postre', 'Snack']
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.toLowerCase(),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: AuraColors.getTextPrimary(isDark),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => category = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ingredientsController,
                  style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ingredientes (uno por línea)',
                    hintStyle: TextStyle(
                      color: AuraColors.getTextMuted(isDark),
                    ),
                    filled: true,
                    fillColor: AuraColors.getSurfaceColor(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stepsController,
                  style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Pasos (uno por línea)',
                    hintStyle: TextStyle(
                      color: AuraColors.getTextMuted(isDark),
                    ),
                    filled: true,
                    fillColor: AuraColors.getSurfaceColor(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        final ingredients = ingredientsController.text
                            .split('\n')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();
                        final steps = stepsController.text
                            .split('\n')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();

                        provider.addRecipe(
                          Recipe(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            title: titleController.text.trim(),
                            ingredients: ingredients,
                            steps: steps,
                            category: category,
                            createdAt: DateTime.now(),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraColors.getAccentColor(isDark),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar receta'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecipeDetail(
    bool isDark,
    Recipe recipe,
    OrganizationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AuraColors.getTextMuted(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AuraColors.getTextPrimary(isDark),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      recipe.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: recipe.isFavorite
                          ? Colors.red
                          : AuraColors.getTextMuted(isDark),
                    ),
                    onPressed: () {
                      provider.toggleRecipeFavorite(recipe.id);
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade300,
                    ),
                    onPressed: () {
                      provider.deleteRecipe(recipe.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              if (recipe.category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AuraColors.getAccentColor(isDark).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recipe.category!,
                    style: TextStyle(
                      color: AuraColors.getAccentColor(isDark),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              if (recipe.totalTime > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AuraColors.getTextMuted(isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.totalTime} min',
                      style: TextStyle(color: AuraColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Ingredientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 12),
              ...recipe.ingredients.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AuraColors.getAccentColor(isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          i,
                          style: TextStyle(
                            color: AuraColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 12),
              ...recipe.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AuraColors.getAccentColor(isDark),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: AuraColors.getTextPrimary(isDark),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
