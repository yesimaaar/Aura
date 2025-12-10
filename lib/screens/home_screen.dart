import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/chat_message.dart';
import '../providers/theme_provider.dart';
import '../providers/organization_provider.dart';
import '../widgets/animated_aura_logo.dart';
import '../widgets/chat_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _selectedImageBase64;
  String? _currentChatId;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _geminiService.initialize();
    _createNewChat();
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

    try {
      final chatId = await _firestoreService.createChat();
      setState(() {
        _currentChatId = chatId;
        _messages = [];
      });
      _listenToMessages(chatId);
    } catch (e) {
      debugPrint('Error creating chat: $e');
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
    _messagesSubscription =
        _firestoreService.getMessages(chatId).listen((messages) {
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

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBase64 = base64Encode(bytes);
      });
    }
  }

  void _processAuraActions(String response) {
    final organizationProvider =
        Provider.of<OrganizationProvider>(context, listen: false);

    // Detectar acciones de tareas
    final taskRegex = RegExp(
        r'\[TASK:([^\]]+)\](?:\[PRIORITY:(alta|media|baja)\])?(?:\[DATE:([^\]]+)\])?',
        caseSensitive: false);
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

    // Detectar acciones de recordatorios
    final reminderRegex =
        RegExp(r'\[REMINDER:([^\]]+)\]\[DATETIME:([^\]]+)\]');
    for (final match in reminderRegex.allMatches(response)) {
      final title = match.group(1)?.trim() ?? '';
      final dateTimeStr = match.group(2);

      if (title.isNotEmpty && dateTimeStr != null) {
        try {
          final dateTime = DateTime.parse(dateTimeStr);
          organizationProvider.createReminderFromAI(
            title: title,
            dateTime: dateTime,
          );
        } catch (_) {}
      }
    }

    // Detectar acciones de eventos
    final eventRegex = RegExp(
        r'\[EVENT:([^\]]+)\]\[START:([^\]]+)\](?:\[END:([^\]]+)\])?');
    for (final match in eventRegex.allMatches(response)) {
      final title = match.group(1)?.trim() ?? '';
      final startStr = match.group(2);
      final endStr = match.group(3);

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
        } catch (_) {}
      }
    }

    // Detectar acciones de recetas
    final recipeRegex = RegExp(
        r'\[RECIPE:([^\]]+)\]\[INGREDIENTS:([^\]]+)\]\[STEPS:([^\]]+)\](?:\[TIME:(\d+)\])?');
    for (final match in recipeRegex.allMatches(response)) {
      final title = match.group(1)?.trim() ?? '';
      final ingredientsStr = match.group(2) ?? '';
      final stepsStr = match.group(3) ?? '';
      final timeStr = match.group(4);

      if (title.isNotEmpty) {
        final ingredients =
            ingredientsStr.split(',').map((e) => e.trim()).toList();
        final steps = stepsStr.split('|').map((e) => e.trim()).toList();
        final prepTime = timeStr != null ? int.tryParse(timeStr) ?? 30 : 30;

        organizationProvider.createRecipeFromAI(
          title: title,
          ingredients: ingredients,
          steps: steps,
          prepTime: prepTime,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImageBase64 == null) return;
    if (_currentChatId == null) return;

    final userMessage = ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
      imageBase64: _selectedImageBase64,
    );

    // Guardar mensaje del usuario en Firestore
    await _firestoreService.addMessage(_currentChatId!, userMessage);

    // Actualizar título del chat si es el primer mensaje
    if (_messages.length <= 1 && message.isNotEmpty) {
      String title =
          message.length > 30 ? '${message.substring(0, 30)}...' : message;
      await _firestoreService.updateChatTitle(_currentChatId!, title);
    }

    _messageController.clear();
    final imageToSend = _selectedImageBase64;
    setState(() {
      _selectedImageBase64 = null;
      _isLoading = true;
    });

    try {
      final organizationProvider =
          Provider.of<OrganizationProvider>(context, listen: false);
      final orgContext = organizationProvider.getSummaryForAI();

      String response;
      if (imageToSend != null) {
        response = await _geminiService.sendMessageWithImage(
          message.isEmpty ? "¿Qué ves en esta imagen?" : message,
          imageToSend,
          organizationContext: orgContext,
        );
      } else {
        response = await _geminiService.sendMessage(
          message,
          organizationContext: orgContext,
        );
      }

      _processAuraActions(response);

      // Limpiar los tags de acciones de la respuesta visible
      String cleanResponse = response
          .replaceAll(
              RegExp(
                  r'\[TASK:[^\]]+\](\[PRIORITY:[^\]]+\])?(\[DATE:[^\]]+\])?'),
              '')
          .replaceAll(RegExp(r'\[REMINDER:[^\]]+\]\[DATETIME:[^\]]+\]'), '')
          .replaceAll(
              RegExp(r'\[EVENT:[^\]]+\]\[START:[^\]]+\](\[END:[^\]]+\])?'), '')
          .replaceAll(
              RegExp(
                  r'\[RECIPE:[^\]]+\]\[INGREDIENTS:[^\]]+\]\[STEPS:[^\]]+\](\[TIME:\d+\])?'),
              '')
          .trim();

      final aiMessage = ChatMessage(
        content: cleanResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Guardar respuesta de la IA en Firestore
      await _firestoreService.addMessage(_currentChatId!, aiMessage);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          AnimatedAuraLogo(height: 44, showLogo: _messages.isNotEmpty),
          const Spacer(),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu,
                color: AuraColors.getTextPrimary(isDark),
                size: 24,
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
                  Image.asset(
                    'assets/icons/aura_logo_header.png',
                    height: 36,
                  ),
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
                      color:
                          AuraColors.getAccentColor(isDark).withValues(alpha: 0.3),
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
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.getBackgroundColor(isDark),
        border: Border(
          top: BorderSide(
            color: AuraColors.getSurfaceColor(isDark),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImageBase64 != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 80,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_selectedImageBase64!),
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImageBase64 = null),
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AuraColors.getSurfaceColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AuraColors.getTextSecondary(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AuraColors.getSurfaceColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AuraColors.getTextSecondary(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: AuraColors.getTextPrimary(isDark),
                    ),
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
}
