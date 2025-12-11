import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/chat_message.dart';
import '../providers/theme_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/aura_provider.dart';
import '../widgets/animated_aura_logo.dart';
import '../widgets/chat_bubble.dart';
import 'live_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Usar el servicio de Gemini del Provider, no crear uno nuevo
  GeminiService get _geminiService => Provider.of<AuraProvider>(context, listen: false).gemini;
  
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Gemini ya está inicializado desde AuraProvider en el SplashScreen
    // Solo preparamos el estado inicial para un nuevo chat
    _messages = [];
    _currentChatId = null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _createNewChat() async {
    _messagesSubscription?.cancel();

    // Solo limpiar el estado sin crear en Firestore
    // El chat se creará cuando se envíe el primer mensaje
    setState(() {
      _currentChatId = null;
      _messages = [];
    });
  }

  Future<String> _generateChatTitle(String firstMessage) async {
    try {
      final prompt =
          '''
Genera un título corto y descriptivo (máximo 4-5 palabras) para una conversación que comienza con este mensaje:
"$firstMessage"

Responde SOLO con el título, sin comillas ni explicaciones.
''';
      final title = await _geminiService.sendMessage(prompt);
      return title.trim().length > 40
          ? '${title.trim().substring(0, 40)}...'
          : title.trim();
    } catch (e) {
      // Fallback: usar el primer mensaje como título
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;
    }
  }

  void _loadChat(String chatId) {
    _messagesSubscription?.cancel();

    setState(() {
      _currentChatId = chatId;
      _messages = [];
    });

    _listenToMessages(chatId);
    Navigator.pop(context); // Cerrar el drawer
  }

  void _listenToMessages(String chatId) {
    _messagesSubscription = _firestoreService.getMessages(chatId).listen((
      messages,
    ) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _processAuraActions(String response) {
    final organizationProvider = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    );

    // Detectar bloques de acción JSON [AURA_ACTION]...[/AURA_ACTION]
    final actionRegex = RegExp(
      r'\[AURA_ACTION\](.*?)\[/AURA_ACTION\]',
      dotAll: true,
    );

    for (final match in actionRegex.allMatches(response)) {
      final jsonStr = match.group(1)?.trim();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'task') {
            final title = data['title'] as String? ?? '';
            final priorityStr = data['priority'] as String? ?? 'media';
            final dateStr = data['dueDate'] as String?;
            final hasAlarm = data['hasAlarm'] as bool? ?? false;
            
            if (title.isNotEmpty) {
              DateTime? dueDate;
              if (dateStr != null) {
                try {
                  dueDate = DateTime.parse(dateStr);
                } catch (_) {}
              }

              int priority = 2;
              if (priorityStr.toLowerCase() == 'alta') priority = 1;
              if (priorityStr.toLowerCase() == 'baja') priority = 3;

              organizationProvider.createTaskFromAI(
                title: title,
                priority: priority,
                dueDate: dueDate,
                hasAlarm: hasAlarm,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tarea creada: $title')),
              );
            }
          } else if (type == 'reminder') {
            final title = data['title'] as String? ?? '';
            final dateTimeStr = data['dateTime'] as String?;
            final hasAlarm = data['hasAlarm'] as bool? ?? true;

            if (title.isNotEmpty && dateTimeStr != null) {
              try {
                final dateTime = DateTime.parse(dateTimeStr);
                organizationProvider.createReminderFromAI(
                  title: title,
                  dateTime: dateTime,
                  hasAlarm: hasAlarm,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Recordatorio creado: $title')),
                );
              } catch (_) {}
            }
          } else if (type == 'event') {
            final title = data['title'] as String? ?? '';
            final startStr = data['startDate'] as String?;
            final endStr = data['endDate'] as String?;

            if (title.isNotEmpty && startStr != null) {
              try {
                final start = DateTime.parse(startStr);
                final end = endStr != null
                    ? DateTime.parse(endStr)
                    : start.add(const Duration(hours: 1));
                organizationProvider.createEventFromAI(
                  title: title,
                  startDate: start,
                  endDate: end,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Evento creado: $title')),
                );
              } catch (_) {}
            }
          } else if (type == 'recipe') {
            final title = data['title'] as String? ?? '';
            final ingredients = (data['ingredients'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final steps = (data['steps'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final prepTime = data['prepTime'] as int? ?? 30;

            if (title.isNotEmpty) {
              organizationProvider.createRecipeFromAI(
                title: title,
                ingredients: ingredients,
                steps: steps,
                prepTime: prepTime,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Receta guardada: $title')),
              );
            }
          }
        } catch (e) {
          debugPrint('Error parsing AURA_ACTION: $e');
        }
      }
    }

    // Mantener compatibilidad con formato antiguo (opcional, pero seguro)
    // Detectar acciones de tareas (Legacy)
    final taskRegex = RegExp(
      r'\[TASK:([^\]]+)\](?:\[PRIORITY:(alta|media|baja)\])?(?:\[DATE:([^\]]+)\])?',
      caseSensitive: false,
    );
    for (final match in taskRegex.allMatches(response)) {
      final title = match.group(1)?.trim() ?? '';
      final priorityStr = match.group(2)?.toLowerCase() ?? 'media';
      final dateStr = match.group(3);

      if (title.isNotEmpty) {
        DateTime? dueDate;
        if (dateStr != null) {
          try {
            dueDate = DateTime.parse(dateStr);
          } catch (_) {}
        }

        int priority = 2;
        if (priorityStr == 'alta') priority = 1;
        if (priorityStr == 'baja') priority = 3;

        organizationProvider.createTaskFromAI(
          title: title,
          priority: priority,
          dueDate: dueDate,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final auraProvider = Provider.of<AuraProvider>(context, listen: false);
    final selectedImage = auraProvider.selectedImage;

    if (message.isEmpty && selectedImage == null) return;

    // Crear el chat si es el primer mensaje
    bool isFirstMessage = _currentChatId == null;
    if (isFirstMessage) {
      try {
        final chatId = await _firestoreService.createChat();
        setState(() {
          _currentChatId = chatId;
        });
        _listenToMessages(chatId);
      } catch (e) {
        debugPrint('Error creating chat: $e');
        return;
      }
    }

    String? imageBase64;
    if (selectedImage != null) {
      try {
        final bytes = await File(selectedImage.path).readAsBytes();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        debugPrint('Error encoding image: $e');
      }
    }

    final userMessage = ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
      imageBase64: imageBase64,
    );

    // Guardar mensaje del usuario en Firestore
    await _firestoreService.addMessage(_currentChatId!, userMessage);

    _messageController.clear();
    final messageForTitle = message;
    setState(() {
      _isLoading = true;
    });

    try {
      String response;
      
      if (selectedImage != null) {
        // Multimodal chat
        response = await auraProvider.chatWithAura(message.isEmpty ? "Analiza esta imagen" : message);
        auraProvider.clearSelectedImage();
      } else {
        // Text chat with context
        final organizationProvider = Provider.of<OrganizationProvider>(
          context,
          listen: false,
        );
        final orgContext = organizationProvider.getSummaryForAI();

        response = await _geminiService.sendMessage(
          message,
          organizationContext: orgContext,
        );
      }

      _processAuraActions(response);

      // Limpiar los tags de acciones de la respuesta visible
      String cleanResponse = response
          .replaceAll(RegExp(r'\[AURA_ACTION\].*?\[/AURA_ACTION\]', dotAll: true), '')
          .replaceAll(
            RegExp(r'\[TASK:[^\]]+\](\[PRIORITY:[^\]]+\])?(\[DATE:[^\]]+\])?'),
            '',
          )
          .replaceAll(RegExp(r'\[REMINDER:[^\]]+\]\[DATETIME:[^\]]+\]'), '')
          .replaceAll(
            RegExp(r'\[EVENT:[^\]]+\]\[START:[^\]]+\](\[END:[^\]]+\])?'),
            '',
          )
          .replaceAll(
            RegExp(
              r'\[RECIPE:[^\]]+\]\[INGREDIENTS:[^\]]+\]\[STEPS:[^\]]+\](\[TIME:\d+\])?',
            ),
            '',
          )
          .trim();

      final aiMessage = ChatMessage(
        content: cleanResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Guardar respuesta de la IA en Firestore
      await _firestoreService.addMessage(_currentChatId!, aiMessage);

      // Si es el primer mensaje, generar título con IA
      if (isFirstMessage) {
        final title = await _generateChatTitle(messageForTitle.isNotEmpty ? messageForTitle : "Análisis de imagen");
        await _firestoreService.updateChatTitle(_currentChatId!, title);
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        content:
            'Error: No pude procesar tu mensaje. Por favor intenta de nuevo.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _firestoreService.addMessage(_currentChatId!, errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteChat(String chatId) async {
    await _firestoreService.deleteChat(chatId);
    if (chatId == _currentChatId) {
      _createNewChat();
    }
  }

  void _openOrganization() {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/organization');
  }

  void _openSettings() {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/settings');
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      endDrawer: _buildDrawer(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeView(isDark)
                  : _buildChatList(isDark),
            ),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.getBackgroundColor(isDark),
        border: Border(
          bottom: BorderSide(
            color: AuraColors.getSurfaceColor(isDark),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedAuraLogo(height: 36, showLogo: _messages.isNotEmpty),
          const Spacer(),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu,
                color: AuraColors.getTextPrimary(isDark),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      child: SafeArea(
        child: Column(
          children: [
            // Header del drawer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Image.asset('assets/icons/aura_logo_header.png', height: 36),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: AuraColors.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AuraColors.getSurfaceColor(isDark), height: 1),

            // Botón nuevo chat
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _createNewChat();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AuraColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AuraColors.getAccentColor(
                        isDark,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: AuraColors.getAccentColor(isDark),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nuevo chat',
                        style: TextStyle(
                          color: AuraColors.getAccentColor(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Título historial
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Historial de chats',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AuraColors.getTextMuted(isDark),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Lista de chats
            Expanded(
              child: StreamBuilder<List<ChatSession>>(
                stream: _firestoreService.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AuraColors.getAccentColor(isDark),
                      ),
                    );
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AuraColors.getTextMuted(isDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin conversaciones',
                            style: TextStyle(
                              color: AuraColors.getTextMuted(isDark),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final isSelected = chat.id == _currentChatId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AuraColors.getSurfaceColor(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          onTap: () => _loadChat(chat.id),
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: AuraColors.getTextSecondary(isDark),
                            size: 18,
                          ),
                          title: Text(
                            chat.title,
                            style: TextStyle(
                              color: AuraColors.getTextPrimary(isDark),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            chat.lastMessage,
                            style: TextStyle(
                              color: AuraColors.getTextMuted(isDark),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AuraColors.getTextMuted(isDark),
                              size: 18,
                            ),
                            onPressed: () => _deleteChat(chat.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Divider(color: AuraColors.getSurfaceColor(isDark), height: 1),

            // Botones inferiores
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPanelButton(
                    isDark: isDark,
                    icon: Icons.checklist_rounded,
                    label: 'Organización',
                    onTap: _openOrganization,
                  ),
                  const SizedBox(height: 8),
                  _buildPanelButton(
                    isDark: isDark,
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    onTap: _openSettings,
                  ),
                  const SizedBox(height: 8),
                  _buildPanelButton(
                    isDark: isDark,
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    onTap: _signOut,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red[400]!
        : AuraColors.getTextSecondary(isDark);
    final textColor = isDestructive
        ? Colors.red[400]!
        : AuraColors.getTextPrimary(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AuraColors.getTextMuted(isDark),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Image.asset(
            'assets/icons/aura_logo_header.png',
            height: 100,
            fit: BoxFit.contain,
          ).animate().scale(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            'Tu IA de planificación visual',
            style: TextStyle(
              fontSize: 18,
              color: AuraColors.getTextSecondary(isDark),
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Tómame una foto y te ayudo a organizar tu vida',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AuraColors.getTextMuted(isDark),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 48),
          _buildFeatureCards(isDark),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(bool isDark) {
    final features = [
      {
        'icon': Icons.cleaning_services_outlined,
        'title': 'Organizar',
        'desc': 'Planes de orden',
      },
      {
        'icon': Icons.restaurant_outlined,
        'title': 'Recetas',
        'desc': 'Con lo que tengas',
      },
      {
        'icon': Icons.checkroom_outlined,
        'title': 'Outfits',
        'desc': 'Combinaciones de ropa',
      },
      {
        'icon': Icons.lightbulb_outlined,
        'title': 'Ideas',
        'desc': 'Sugerencias rápidas',
      },
      {
        'icon': Icons.checklist_outlined,
        'title': 'Tareas',
        'desc': 'Listas inteligentes',
      },
      {
        'icon': Icons.event_outlined,
        'title': 'Eventos',
        'desc': 'Planifica tu día',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          decoration: BoxDecoration(
            color: AuraColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 28,
                color: AuraColors.getTextSecondary(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
              Text(
                feature['desc'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: AuraColors.getTextMuted(isDark),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
      },
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AuraColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AuraColors.getTextSecondary(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aura está pensando...',
                        style: TextStyle(
                          color: AuraColors.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final message = _messages[index];
        return ChatBubble(message: message);
      },
    );
  }

  Widget _buildInputArea(bool isDark) {
    final auraProvider = Provider.of<AuraProvider>(context);
    final selectedImage = auraProvider.selectedImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.getBackgroundColor(isDark),
        border: Border(
          top: BorderSide(color: AuraColors.getSurfaceColor(isDark)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(selectedImage.path),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => auraProvider.clearSelectedImage(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.view_in_ar, color: AuraColors.getAccentColor(isDark)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveViewScreen()),
                    );
                  },
                  tooltip: 'Vista en vivo',
                ),
                IconButton(
                  icon: Icon(Icons.add, color: AuraColors.getAccentColor(isDark)),
                  onPressed: () => _showAttachmentOptions(context, isDark),
                  tooltip: 'Adjuntar',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        color: AuraColors.getTextMuted(isDark),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AuraColors.getSurfaceColor(isDark),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AuraColors.getAccentColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.send,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context, bool isDark) {
    final auraProvider = Provider.of<AuraProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.getSurfaceColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image, color: AuraColors.getAccentColor(isDark)),
              title: Text(
                'Galería',
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                auraProvider.pickFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AuraColors.getAccentColor(isDark)),
              title: Text(
                'Tomar foto',
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement take photo directly or reuse LiveView
                // For now, we can use LiveView as it is the camera interface
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveViewScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file, color: AuraColors.getAccentColor(isDark)),
              title: Text(
                'Subir archivo',
                style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente: Subir archivos')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
