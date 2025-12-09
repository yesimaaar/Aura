import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/aura_gradient_text.dart';
import 'live_view_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  File? _attachedImage;
  final List<List<ChatMessage>> _chatHistory = [];
  int _currentChatIndex = -1;

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage([String? quickAction]) async {
    final text = quickAction ?? _chatController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;

    final provider = context.read<AuraProvider>();
    final originalQuery = text.isNotEmpty ? text : 'Analiza esta imagen';
    final originalImage = _attachedImage;
    
    setState(() {
      _messages.add(ChatMessage(
        text: originalQuery,
        isUser: true,
        image: _attachedImage,
      ));
      _chatController.clear();
      _isTyping = true;
    });
    
    final imageToAnalyze = _attachedImage;
    _attachedImage = null;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      String response;
      
      // Usar Gemini si está disponible
      if (provider.isGeminiReady) {
        if (imageToAnalyze != null) {
          // Chat con imagen
          response = await provider.chatWithAuraAndImage(
            text.isNotEmpty ? text : 'Analiza esta imagen y dame sugerencias útiles',
            imageToAnalyze,
          );
        } else {
          // Chat solo texto
          response = await provider.chatWithAura(text);
        }
      } else {
        // Fallback a respuestas mock si Gemini no está listo
        await Future.delayed(const Duration(milliseconds: 800));
        response = _getAuraResponse(text, imageToAnalyze);
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            suggestions: _getSuggestions(text, imageToAnalyze),
            originalQuery: originalQuery,
            originalImage: originalImage,
          ));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: '⚠️ Hubo un error al procesar tu mensaje.\n\nIntenta de nuevo o verifica tu conexión.',
            isUser: false,
            originalQuery: originalQuery,
            originalImage: originalImage,
          ));
        });
        debugPrint('Error en Gemini: $e');
      }
    }
  }

  Future<void> _retryMessage(ChatMessage message) async {
    if (message.originalQuery == null) return;
    
    // Remover el mensaje de error/respuesta anterior
    setState(() {
      _messages.remove(message);
      _attachedImage = message.originalImage;
    });
    
    // Reintentar
    await _sendMessage(message.originalQuery);
  }

  String _getAuraResponse(String query, File? image) {
    final lowerQuery = query.toLowerCase();
    
    if (image != null) {
      if (lowerQuery.contains('organizar') || lowerQuery.contains('espacio') || lowerQuery.contains('cuarto')) {
        return '📸 He analizado tu espacio.\n\n'
            '**Lo que veo:**\n'
            '• Varios objetos fuera de lugar\n'
            '• Área de trabajo con potencial\n'
            '• Oportunidad de mejorar la organización\n\n'
            '**Mi plan para ti:**\n'
            '1. Despeja las superficies principales\n'
            '2. Agrupa objetos similares\n'
            '3. Crea zonas definidas (trabajo, descanso, almacenamiento)\n'
            '4. Elimina lo que no uses en 6 meses\n\n'
            '¿Quieres que detalle algún paso?';
      } else if (lowerQuery.contains('receta') || lowerQuery.contains('comida') || lowerQuery.contains('cocina') || lowerQuery.contains('nevera')) {
        return '🍳 He revisado los ingredientes que veo.\n\n'
            '**Ingredientes detectados:**\n'
            '• Vegetales variados\n'
            '• Proteínas disponibles\n'
            '• Condimentos básicos\n\n'
            '**Recetas que puedo sugerirte:**\n'
            '1. 🥗 Ensalada energética (15 min)\n'
            '2. 🍝 Pasta rápida con vegetales (20 min)\n'
            '3. 🥘 Salteado express (10 min)\n\n'
            '¿Cuál te interesa? Puedo darte los pasos.';
      } else if (lowerQuery.contains('outfit') || lowerQuery.contains('ropa') || lowerQuery.contains('vestir')) {
        return '👔 He analizado tu ropa.\n\n'
            '**Lo que veo:**\n'
            '• Prendas casuales y formales\n'
            '• Colores neutros predominantes\n'
            '• Buenas opciones para combinar\n\n'
            '**Outfits que te sugiero:**\n'
            '1. 🎨 Look casual-chic para hoy\n'
            '2. 💼 Outfit semi-formal versátil\n'
            '3. 🏃 Combinación cómoda para el día\n\n'
            '¿Te describo alguno en detalle?';
      } else {
        return '📸 He analizado tu imagen.\n\n'
            '**Lo que puedo hacer:**\n'
            '• Organizar el espacio que veo\n'
            '• Crear listas de tareas\n'
            '• Sugerir mejoras\n'
            '• Generar un plan de acción\n\n'
            '¿Qué te gustaría que haga con lo que veo?';
      }
    }
    
    // Respuestas para texto sin imagen
    if (lowerQuery.contains('hola') || lowerQuery.contains('hey') || lowerQuery.contains('hi') || lowerQuery.contains('buenas')) {
      return '¡Hey! 👋\n\n'
          'Soy Aura, tu IA de planificación visual.\n\n'
          'Puedo ayudarte con:\n'
          '• 🏠 Organizar espacios\n'
          '• 🍳 Recetas con tus ingredientes\n'
          '• 👔 Armar outfits\n'
          '• 📝 Planificar tareas\n\n'
          '💡 **Tip:** Si subes una foto, puedo darte ayuda más específica.\n\n'
          '¿En qué te ayudo hoy?';
    } else if (lowerQuery.contains('organizar') || lowerQuery.contains('orden') || lowerQuery.contains('limpiar')) {
      return '🧹 ¡Me encanta organizar!\n\n'
          'Aquí van algunos tips generales:\n\n'
          '**Regla de los 5 minutos:**\n'
          'Si algo toma menos de 5 min, hazlo ya.\n\n'
          '**Método de las 3 cajas:**\n'
          '1. 📦 Guardar\n'
          '2. 🎁 Donar\n'
          '3. 🗑️ Tirar\n\n'
          '💡 **Para ayuda personalizada:** Sube una foto del espacio y te hago un plan específico.';
    } else if (lowerQuery.contains('receta') || lowerQuery.contains('cocinar') || lowerQuery.contains('comer')) {
      return '🍳 ¡Hora de cocinar!\n\n'
          '**Recetas rápidas universales:**\n\n'
          '1. **Pasta express** (15 min)\n'
          '   Pasta + aceite + ajo + lo que tengas\n\n'
          '2. **Wrap rápido** (5 min)\n'
          '   Tortilla + proteína + vegetales\n\n'
          '3. **Bowl energético** (10 min)\n'
          '   Arroz/quinoa + proteína + vegetales\n\n'
          '💡 **Para recetas personalizadas:** Tómale foto a tu nevera y te digo qué preparar con lo que tienes.';
    } else if (lowerQuery.contains('outfit') || lowerQuery.contains('ropa') || lowerQuery.contains('vestir') || lowerQuery.contains('combinar')) {
      return '👔 ¡Vamos a armar tu look!\n\n'
          '**Tips de combinación:**\n\n'
          '• **Regla 3 colores:** No uses más de 3 colores diferentes\n'
          '• **Neutros base:** Negro, blanco, gris van con todo\n'
          '• **Un statement:** Una pieza que destaque\n\n'
          '**Combos seguros:**\n'
          '• Jeans + camiseta blanca + blazer\n'
          '• Negro total + accesorio de color\n'
          '• Denim + denim (tono diferente)\n\n'
          '💡 **Para outfit personalizado:** Sube foto de tu ropa disponible.';
    } else if (lowerQuery.contains('plan') || lowerQuery.contains('tarea') || lowerQuery.contains('productiv')) {
      return '📋 ¡Planifiquemos!\n\n'
          '**Método Eisenhower:**\n\n'
          '1. ⚡ **Urgente + Importante** → Hazlo YA\n'
          '2. 📅 **Importante** → Agenda tiempo\n'
          '3. 👥 **Urgente** → Delega si puedes\n'
          '4. ❌ **Ni uno ni otro** → Elimínalo\n\n'
          '**Pomodoro básico:**\n'
          '25 min trabajo → 5 min descanso → repetir\n\n'
          '💡 **Para plan personalizado:** Cuéntame más sobre qué necesitas organizar.';
    } else if (lowerQuery.contains('ayuda') || lowerQuery.contains('puedes') || lowerQuery.contains('haces')) {
      return '✨ Soy Aura, tu asistente de planificación visual.\n\n'
          '**Mis superpoderes:**\n\n'
          '📸 **Con fotos puedo:**\n'
          '• Analizar y organizar espacios\n'
          '• Identificar ingredientes y dar recetas\n'
          '• Armar outfits con tu ropa\n'
          '• Crear planes de acción visuales\n\n'
          '💬 **Sin fotos puedo:**\n'
          '• Darte tips de organización\n'
          '• Sugerir recetas generales\n'
          '• Ayudarte a planificar\n'
          '• Responder preguntas\n\n'
          '¿Qué te gustaría hacer?';
    }
    
    // Respuesta genérica
    return '¡Entendido! 🎯\n\n'
        'Puedo ayudarte con eso.\n\n'
        '💡 **Tip:** Si me envías una foto relacionada, puedo darte una respuesta mucho más personalizada y específica.\n\n'
        '¿Quieres contarme más detalles o prefieres subir una imagen?';
  }

  List<String> _getSuggestions(String query, File? image) {
    if (image != null) {
      return ['Dame más detalles', 'Crea lista de tareas', 'Siguiente paso'];
    }
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('organizar') || lowerQuery.contains('orden')) {
      return ['📷 Subir foto', 'Tips rápidos', 'Método KonMari'];
    } else if (lowerQuery.contains('receta') || lowerQuery.contains('cocin')) {
      return ['📷 Foto de nevera', 'Receta rápida', 'Ideas saludables'];
    } else if (lowerQuery.contains('outfit') || lowerQuery.contains('ropa')) {
      return ['📷 Foto de ropa', 'Tips de estilo', 'Colores que combinan'];
    }
    return ['📷 Subir imagen', 'Organizar espacio', 'Ideas de recetas'];
  }

  Future<void> _pickImage() async {
    final provider = context.read<AuraProvider>();
    await provider.pickFromGallery();
    if (provider.currentImage != null && mounted) {
      setState(() {
        _attachedImage = File(provider.currentImage!.path);
      });
    }
  }

  void _openLiveView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveViewScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _startNewChat() {
    if (_messages.isNotEmpty) {
      // Guardar chat actual en historial
      _chatHistory.add(List.from(_messages));
    }
    setState(() {
      _messages = [];
      _currentChatIndex = -1;
      _attachedImage = null;
    });
  }

  void _showChatHistory(bool isDark) {
    if (_chatHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay chats anteriores'),
          backgroundColor: AuraColors.getSurfaceColor(isDark),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildHistorySheet(isDark),
    );
  }

  Widget _buildHistorySheet(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AuraColors.getTextPrimary(isDark)),
              const SizedBox(width: 12),
              Text(
                'Historial de chats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.getTextPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[_chatHistory.length - 1 - index];
                final firstMessage = chat.isNotEmpty ? chat.first.text : 'Chat vacío';
                final preview = firstMessage.length > 50 
                    ? '${firstMessage.substring(0, 50)}...' 
                    : firstMessage;
                
                return ListTile(
                  onTap: () {
                    // Guardar chat actual si tiene mensajes
                    if (_messages.isNotEmpty && _currentChatIndex == -1) {
                      _chatHistory.add(List.from(_messages));
                    }
                    setState(() {
                      _currentChatIndex = _chatHistory.length - 1 - index;
                      _messages = List.from(_chatHistory[_currentChatIndex]);
                    });
                    Navigator.pop(context);
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AuraColors.getSurfaceColor(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AuraColors.getTextSecondary(isDark),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    preview,
                    style: TextStyle(
                      color: AuraColors.getTextPrimary(isDark),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${chat.length} mensajes',
                    style: TextStyle(
                      color: AuraColors.getTextMuted(isDark),
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AuraColors.getTextMuted(isDark),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _chatHistory.removeAt(_chatHistory.length - 1 - index);
                      });
                      Navigator.pop(context);
                      if (_chatHistory.isNotEmpty) {
                        _showChatHistory(isDark);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            
            // Chat area
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeScreen(isDark)
                  : _buildChatList(isDark),
            ),
            
            // Attached image preview
            if (_attachedImage != null) _buildImagePreview(isDark),
            
            // Quick actions (only when no messages)
            if (_messages.isEmpty) _buildQuickActions(isDark),
            
            // Chat input
            _buildChatInput(isDark),
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
          const AuraGradientText(
            'Aura',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Nuevo chat
          GestureDetector(
            onTap: _startNewChat,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_comment_outlined,
                color: AuraColors.getTextSecondary(isDark),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Historial
          GestureDetector(
            onTap: () => _showChatHistory(isDark),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history,
                color: AuraColors.getTextSecondary(isDark),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings
          GestureDetector(
            onTap: _openSettings,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AuraColors.getTextSecondary(isDark),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWelcomeScreen(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.auto_awesome_outlined,
            size: 80,
            color: AuraColors.getTextMuted(isDark),
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
      {'icon': Icons.cleaning_services_outlined, 'title': 'Organizar', 'desc': 'Planes de orden'},
      {'icon': Icons.restaurant_outlined, 'title': 'Recetas', 'desc': 'Con lo que tengas'},
      {'icon': Icons.checkroom_outlined, 'title': 'Outfits', 'desc': 'Combinaciones de ropa'},
      {'icon': Icons.auto_fix_high_outlined, 'title': 'Edición', 'desc': 'Mejora estética'},
      {'icon': Icons.lightbulb_outlined, 'title': 'Ideas', 'desc': 'Sugerencias rápidas'},
      {'icon': Icons.checklist_outlined, 'title': 'Tareas', 'desc': 'Listas inteligentes'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          isDark,
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['desc'] as String,
          index,
        );
      },
    );
  }

  Widget _buildFeatureCard(bool isDark, IconData icon, String title, String desc, int index) {
    return GestureDetector(
      onTap: () {
        _sendMessage(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AuraColors.getSurfaceColor(isDark),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AuraColors.getTextPrimary(isDark), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AuraColors.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                color: AuraColors.getTextMuted(isDark),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        return _buildMessageBubble(_messages[index], isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.image != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(message.image!, fit: BoxFit.cover),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AuraColors.getTextPrimary(isDark)
                  : AuraColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? AuraColors.getBackgroundColor(isDark)
                    : AuraColors.getTextPrimary(isDark),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          // Botones de feedback y retry para respuestas de IA
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón Like
                  _buildFeedbackButton(
                    icon: Icons.thumb_up_outlined,
                    activeIcon: Icons.thumb_up,
                    isActive: message.feedbackState == 1,
                    onTap: () {
                      setState(() {
                        message.feedbackState = message.feedbackState == 1 ? 0 : 1;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  // Botón Dislike
                  _buildFeedbackButton(
                    icon: Icons.thumb_down_outlined,
                    activeIcon: Icons.thumb_down,
                    isActive: message.feedbackState == -1,
                    onTap: () {
                      setState(() {
                        message.feedbackState = message.feedbackState == -1 ? 0 : -1;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  // Botón Retry
                  if (message.originalQuery != null)
                    _buildFeedbackButton(
                      icon: Icons.refresh_rounded,
                      activeIcon: Icons.refresh_rounded,
                      isActive: false,
                      onTap: () => _retryMessage(message),
                      isDark: isDark,
                    ),
                  const SizedBox(width: 4),
                  // Botón Copiar
                  _buildFeedbackButton(
                    icon: Icons.copy_outlined,
                    activeIcon: Icons.copy,
                    isActive: false,
                    onTap: () {
                      // Copiar al clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Respuesta copiada'),
                          backgroundColor: AuraColors.getSurfaceColor(isDark),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          if (message.suggestions != null && message.suggestions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions!.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _sendMessage(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AuraColors.getSurfaceColor(isDark)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: AuraColors.getTextSecondary(isDark),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: message.isUser ? 0.05 : -0.05);
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive 
              ? AuraColors.primaryPurple.withValues(alpha: 0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 16,
          color: isActive 
              ? AuraColors.primaryPurple 
              : AuraColors.getTextMuted(isDark),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AuraColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(isDark, 0),
            const SizedBox(width: 4),
            _buildDot(isDark, 1),
            const SizedBox(width: 4),
            _buildDot(isDark, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isDark, int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AuraColors.getTextMuted(isDark),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
      .fadeIn(delay: (index * 200).ms)
      .then()
      .fadeOut(delay: 400.ms);
  }

  Widget _buildImagePreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AuraColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _attachedImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imagen adjunta',
              style: TextStyle(color: AuraColors.getTextSecondary(isDark)),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _attachedImage = null),
            icon: Icon(Icons.close, color: AuraColors.getTextMuted(isDark)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildQuickActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionChip(isDark, Icons.camera_alt, 'Vista en vivo', _openLiveView),
            _buildQuickActionChip(isDark, Icons.photo_library, 'Subir foto', _pickImage),
            _buildQuickActionChip(isDark, Icons.lightbulb_outline, 'Ideas rápidas', () => _sendMessage('Ideas rápidas')),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildQuickActionChip(bool isDark, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AuraColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AuraColors.getTextSecondary(isDark)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AuraColors.getTextSecondary(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.getBackgroundColor(isDark),
        border: Border(
          top: BorderSide(
            color: AuraColors.getSurfaceColor(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón Vista en vivo (cámara)
          GestureDetector(
            onTap: _openLiveView,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: AuraColors.getTextSecondary(isDark),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón subir foto
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: AuraColors.getTextSecondary(isDark),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: TextStyle(
                color: AuraColors.getTextPrimary(isDark),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Pídele algo a Aura...',
                hintStyle: TextStyle(color: AuraColors.getTextMuted(isDark)),
                filled: true,
                fillColor: AuraColors.getInputBackground(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuraColors.getTextPrimary(isDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: AuraColors.getBackgroundColor(isDark),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;
  final List<String>? suggestions;
  final String? originalQuery; // Para retry
  final File? originalImage; // Para retry con imagen
  int feedbackState; // 0: none, 1: liked, -1: disliked

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.suggestions,
    this.originalQuery,
    this.originalImage,
    this.feedbackState = 0,
  });
}
