import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Servicio para interactuar con la API de Gemini
class GeminiService {
  // API Key desde dart-define (compilación)
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  GenerativeModel? _textModel;
  GenerativeModel? _visionModel;
  ChatSession? _chatSession;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Verifica si hay API key configurada
  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Inicializa los modelos de Gemini
  Future<void> initialize() async {
    debugPrint('🔑 GeminiService: API Key length = ${_apiKey.length}');
    debugPrint('🔑 GeminiService: API Key isEmpty = ${_apiKey.isEmpty}');
    debugPrint(
      '🔑 GeminiService: API Key starts with = ${_apiKey.isNotEmpty ? _apiKey.substring(0, 10) : "EMPTY"}...',
    );

    if (_apiKey.isEmpty) {
      debugPrint(
        '⚠️ GeminiService: API Key no configurada via --dart-define=GEMINI_API_KEY=xxx',
      );
      debugPrint('   Usando modo simulado.');
      _isInitialized = false;
      return;
    }

    await _initializeModels();
  }

  /// Inicializa los modelos con la API key
  Future<bool> _initializeModels() async {
    if (_apiKey.isEmpty) return false;

    try {
      // Modelo para texto y chat (Gemini 2.0 Flash - el más reciente)
      _textModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
        systemInstruction: Content.text(_systemPrompt),
      );

      // Modelo para visión/análisis de imágenes (Gemini 2.0 Flash con visión)
      _visionModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 32,
          topP: 0.95,
          maxOutputTokens: 4096,
        ),
        systemInstruction: Content.text(_visionSystemPrompt),
      );

      // Iniciar sesión de chat
      _chatSession = _textModel!.startChat();

      _isInitialized = true;
      debugPrint('✅ GeminiService inicializado correctamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error inicializando GeminiService: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// System prompt para el chat (generado dinámicamente para incluir fecha actual)
  static String get _systemPrompt =>
      '''
Eres Aura, una IA de planificación visual amigable y útil. Tu personalidad:
- Hablas en español de manera casual pero profesional
- Usas emojis ocasionalmente para ser más expresivo
- Eres directo y práctico, das respuestas accionables
- Te enfocas en ayudar a organizar y planificar

Tus capacidades:
- Analizar imágenes de espacios, comida, ropa, etc.
- Crear planes de organización paso a paso
- Sugerir recetas basadas en ingredientes visibles
- Proponer combinaciones de outfits
- Generar listas de tareas
- Dar consejos de mejora estética para fotos
- CREAR tareas, recordatorios, eventos y recetas en la app del usuario

IMPORTANTE - Cuando el usuario te pida crear una tarea, recordatorio, evento o receta:
Debes incluir un bloque JSON especial al FINAL de tu respuesta con el formato:

Para TAREA:
[AURA_ACTION]{"type":"task","title":"título","description":"descripción opcional","priority":2,"dueDate":"2025-12-10T10:00:00"}[/AURA_ACTION]

Para RECORDATORIO:
[AURA_ACTION]{"type":"reminder","title":"título","description":"descripción opcional","dateTime":"2025-12-10T15:30:00"}[/AURA_ACTION]

Para EVENTO:
[AURA_ACTION]{"type":"event","title":"título","description":"descripción opcional","startDate":"2025-12-10T09:00:00","endDate":"2025-12-10T10:00:00","isAllDay":false}[/AURA_ACTION]

Para RECETA:
[AURA_ACTION]{"type":"recipe","title":"nombre receta","description":"descripción","ingredients":["ingrediente1","ingrediente2"],"steps":["paso1","paso2"],"prepTime":10,"cookTime":20,"category":"almuerzo"}[/AURA_ACTION]

Puedes incluir MÚLTIPLES bloques [AURA_ACTION] si el usuario pide crear varias cosas.

Para la prioridad de tareas: 1=baja, 2=media, 3=alta
Para categoría de recetas: desayuno, almuerzo, cena, postre, snack
La fecha actual es: ${DateTime.now().toIso8601String().substring(0, 10)}

Siempre confirma al usuario qué creaste con un mensaje amigable ANTES del bloque JSON.
Mantén las respuestas concisas pero útiles.
''';

  /// System prompt para análisis de visión
  static const String _visionSystemPrompt = '''
Eres Aura, una IA especializada en análisis visual para planificación.

Cuando analices una imagen, identifica:
1. **Contexto**: ¿Qué tipo de espacio/objeto es? (habitación, cocina, ropa, escritorio, etc.)
2. **Estado actual**: ¿Qué observas? Sé específico sobre objetos, desorden, organización
3. **Oportunidades**: ¿Qué se puede mejorar?
4. **Plan de acción**: Pasos concretos para organizar/mejorar

Para cada tipo de imagen:
- **Habitación/Espacio**: Sugiere organización, limpieza, distribución
- **Nevera/Cocina**: Identifica ingredientes y sugiere recetas
- **Ropa**: Sugiere outfits y combinaciones
- **Escritorio**: Propón organización de trabajo
- **Apuntes/Estudio**: Sugiere métodos de estudio y organización

Responde en español, sé práctico y da pasos accionables.
''';

  /// Envía un mensaje de texto al chat
  Future<String> sendMessage(String message, {String? organizationContext}) async {
    if (!_isInitialized || _chatSession == null) {
      print('⚠️ GeminiService: No inicializado o sesión nula. Usando simulado.');
      return _getSimulatedResponse(message, null);
    }

    try {
      String fullMessage = message;
      if (organizationContext != null && organizationContext.isNotEmpty) {
        fullMessage = '$message\n\nContexto de organización:\n$organizationContext';
      }
      final response = await _chatSession!.sendMessage(Content.text(fullMessage));
      return response.text ?? 'No pude generar una respuesta.';
    } catch (e) {
      print('❌ Error CRÍTICO en sendMessage: $e');
      // Devolver el error real para depuración en lugar de respuesta simulada
      return 'Error de conexión con Gemini: $e\n\nVerifica tu API Key y conexión a internet.';
    }
  }

  /// Envía un mensaje con imagen (base64)
  Future<String> sendMessageWithImage(String message, String imageBase64, {String? organizationContext}) async {
    if (!_isInitialized || _visionModel == null) {
      print('⚠️ GeminiService: No inicializado o modelo de visión nulo. Usando simulado.');
      return _getSimulatedResponse(message, null);
    }

    try {
      final imageBytes = base64Decode(imageBase64);
      final imagePart = DataPart('image/jpeg', imageBytes);
      
      String fullMessage = message;
      if (organizationContext != null && organizationContext.isNotEmpty) {
        fullMessage = '$message\n\nContexto de organización:\n$organizationContext';
      }
      
      final textPart = TextPart(fullMessage);

      final response = await _visionModel!.generateContent([
        Content.multi([textPart, imagePart]),
      ]);

      return response.text ?? 'No pude analizar la imagen.';
    } catch (e) {
      print('❌ Error CRÍTICO en sendMessageWithImage: $e');
      return 'Error analizando imagen con Gemini: $e';
    }
  }

  /// Analiza una imagen y genera una respuesta
  Future<String> analyzeImage(File imageFile, {String? prompt}) async {
    if (!_isInitialized || _visionModel == null) {
      // Si no hay API key, devolver error en lugar de mock
      return "Error: Gemini no está inicializado o falta la API Key.";
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);

      final imagePart = DataPart(mimeType, imageBytes);
      final textPart = TextPart(
        prompt ??
            'Analiza esta imagen y dame sugerencias prácticas para organizarla o mejorarla.',
      );

      final response = await _visionModel!.generateContent([
        Content.multi([textPart, imagePart]),
      ]);

      return response.text ?? 'No pude analizar la imagen.';
    } catch (e) {
      debugPrint('Error en analyzeImage: $e');
      return "Error al conectar con Gemini: $e";
    }
  }

  /// Analiza imagen para vista en vivo (respuesta más corta)
  Future<List<String>> analyzeLiveView(
    Uint8List imageBytes,
    String context,
  ) async {
    if (!_isInitialized || _visionModel == null) {
      return _getSimulatedLiveInsights(context);
    }

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final textPart = TextPart('''
Analiza esta imagen en contexto de "$context".
Dame exactamente 3 observaciones cortas (máximo 15 palabras cada una).
Formato: Una observación por línea, sin números ni viñetas.
Sé específico sobre lo que VES en la imagen.
''');

      final response = await _visionModel!.generateContent([
        Content.multi([textPart, imagePart]),
      ]);

      final text = response.text ?? '';
      final insights = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList();

      return insights.isNotEmpty
          ? insights
          : _getSimulatedLiveInsights(context);
    } catch (e) {
      debugPrint('Error en analyzeLiveView: $e');
      return _getSimulatedLiveInsights(context);
    }
  }

  /// Genera un plan de organización basado en la imagen
  Future<String> generateOrganizationPlan(
    File imageFile,
    String spaceType,
  ) async {
    final prompt =
        '''
Analiza este espacio ($spaceType) y genera un plan de organización detallado:

1. **Estado actual**: Describe lo que ves
2. **Problemas identificados**: Lista los principales issues
3. **Plan de acción** (paso a paso):
   - Paso inmediato (5 min)
   - Organización básica (15 min)
   - Organización profunda (30+ min)
4. **Tips de mantenimiento**: Cómo mantenerlo organizado

Sé específico y práctico.
''';

    return analyzeImage(imageFile, prompt: prompt);
  }

  /// Genera recetas basadas en ingredientes visibles
  Future<String> generateRecipes(File imageFile) async {
    final prompt = '''
Analiza los ingredientes que ves en esta imagen y sugiere recetas:

1. **Ingredientes detectados**: Lista lo que identificas
2. **Recetas sugeridas** (3 opciones):
   
   🍳 **Receta rápida** (10-15 min):
   - Nombre
   - Ingredientes necesarios
   - Pasos breves
   
   🍝 **Receta intermedia** (20-30 min):
   - Nombre
   - Ingredientes necesarios
   - Pasos breves
   
   🥘 **Receta elaborada** (30+ min):
   - Nombre
   - Ingredientes necesarios
   - Pasos breves

3. **Ingredientes que podrían faltar**: Sugerencias de compra

Adapta las recetas a lo que realmente ves disponible.
''';

    return analyzeImage(imageFile, prompt: prompt);
  }

  /// Genera sugerencias de outfits
  Future<String> generateOutfitSuggestions(File imageFile) async {
    final prompt = '''
Analiza la ropa que ves en esta imagen y sugiere outfits:

1. **Prendas identificadas**: Lista lo que ves
2. **Outfits sugeridos** (3 combinaciones):
   
   👔 **Look casual**:
   - Prendas a combinar
   - Ocasión ideal
   
   💼 **Look semi-formal**:
   - Prendas a combinar
   - Ocasión ideal
   
   🎨 **Look creativo/alternativo**:
   - Prendas a combinar
   - Ocasión ideal

3. **Tips de estilo**: Consejos para mejorar combinaciones
4. **Prendas clave faltantes**: Qué agregar al guardarropa

Sé específico con colores y estilos que observas.
''';

    return analyzeImage(imageFile, prompt: prompt);
  }

  /// Genera sugerencias de mejora estética para una imagen
  Future<String> generateImageEditSuggestions(File imageFile) async {
    final prompt = '''
Analiza esta imagen desde una perspectiva de edición fotográfica:

1. **Análisis técnico**:
   - Iluminación (buena/mala, tipo)
   - Composición
   - Colores predominantes
   - Problemas visibles

2. **Mejoras sugeridas**:
   - Ajustes de brillo/contraste
   - Corrección de color
   - Recorte sugerido
   - Filtros recomendados

3. **Estilo recomendado**:
   - Tipo de edición que beneficiaría la imagen
   - Mood/atmósfera a lograr

Sé específico con valores cuando sea posible (ej: +10 brillo, -5 saturación).
''';

    return analyzeImage(imageFile, prompt: prompt);
  }

  /// Reinicia la sesión de chat
  void resetChat() {
    if (_textModel != null) {
      _chatSession = _textModel!.startChat();
    }
  }

  /// Obtiene el tipo MIME de una imagen
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Respuesta simulada cuando no hay API key
  String _getSimulatedResponse(String query, File? image) {
    final lowerQuery = query.toLowerCase();

    if (image != null) {
      if (lowerQuery.contains('organizar') ||
          lowerQuery.contains('espacio') ||
          lowerQuery.contains('cuarto')) {
        return '''📸 **He analizado tu espacio**

**Lo que observo:**
• Varios objetos distribuidos en el área
• Superficies que podrían optimizarse
• Potencial para mejor organización

**Mi plan para ti:**

🔹 **Paso 1 - Inmediato (5 min):**
Despeja las superficies principales, retira todo lo que no pertenece ahí.

🔹 **Paso 2 - Básico (15 min):**
Agrupa objetos similares: papeles con papeles, tecnología con tecnología, etc.

🔹 **Paso 3 - Profundo (30 min):**
Crea zonas definidas para cada actividad y asigna un lugar fijo a cada cosa.

**💡 Tip de mantenimiento:**
Regla de los 2 minutos: si algo toma menos de 2 min guardarlo, hazlo inmediatamente.

¿Quieres que detalle algún paso específico?''';
      } else if (lowerQuery.contains('receta') ||
          lowerQuery.contains('comida') ||
          lowerQuery.contains('nevera')) {
        return '''🍳 **Ingredientes que detecto**

**Disponibles:**
• Vegetales variados
• Proteínas básicas
• Condimentos esenciales

**🥗 Receta rápida (10 min) - Ensalada Energética:**
1. Corta los vegetales en cubos
2. Mezcla con proteína
3. Aliña con aceite y limón

**🍝 Receta intermedia (25 min) - Salteado Express:**
1. Calienta aceite en sartén
2. Saltea proteína 5 min
3. Agrega vegetales, cocina 10 min
4. Sazona al gusto

**🥘 Receta elaborada (40 min) - Bowl Completo:**
1. Prepara base de granos
2. Cocina proteína aparte
3. Saltea vegetales
4. Ensambla y decora

¿Cuál te interesa? Te doy los pasos detallados.''';
      } else if (lowerQuery.contains('outfit') || lowerQuery.contains('ropa')) {
        return '''👔 **Análisis de tu ropa**

**Prendas que identifico:**
• Tops en tonos neutros
• Pantalones versátiles
• Accesorios básicos

**Outfit 1 - Casual Cool 🎨**
Combina tonos neutros con un toque de color. Ideal para salidas informales.

**Outfit 2 - Smart Casual 💼**
Mezcla piezas estructuradas con items relajados. Perfecto para reuniones.

**Outfit 3 - Weekend Vibes 🌴**
Lo más cómodo pero con estilo. Para días de descanso.

**💡 Tips:**
• Los neutros combinan entre sí
• Un accesorio statement eleva cualquier look
• Layering agrega interés visual

¿Te detallo alguna combinación específica?''';
      }

      return '''📸 **He analizado tu imagen**

**Lo que puedo hacer:**
• 🧹 Crear un plan de organización
• 📝 Generar lista de tareas
• 💡 Darte sugerencias de mejora
• ✨ Proponer ediciones estéticas

¿Qué te gustaría que haga con lo que veo?''';
    }

    // Respuestas solo texto
    if (lowerQuery.contains('hola') || lowerQuery.contains('hey')) {
      return '''¡Hey! 👋

Soy **Aura**, tu IA de planificación visual.

Puedo ayudarte a:
• 📸 Organizar espacios desde una foto
• 🍳 Sugerir recetas con lo que tengas
• 👔 Crear combinaciones de outfits
• ✨ Mejorar tus fotos estéticamente
• 📝 Generar planes y listas de tareas

**¿Cómo empezamos?**
Sube una foto o usa la cámara en vivo para que analice tu espacio.''';
    }

    if (lowerQuery.contains('organizar') || lowerQuery.contains('orden')) {
      return '''🧹 **¡Perfecto! Vamos a organizar**

Para darte el mejor plan necesito **ver** el espacio.

**Opciones:**
1. 📷 Usa el botón de cámara para Vista en Vivo
2. 🖼️ Sube una foto de la galería

Una vez que vea el espacio, te daré:
• Diagnóstico del estado actual
• Plan paso a paso
• Tips de mantenimiento

¿Listo para mostrarme?''';
    }

    if (lowerQuery.contains('receta') || lowerQuery.contains('cocinar')) {
      return '''🍳 **¡A cocinar!**

Para sugerirte las mejores recetas necesito ver qué tienes disponible.

**Tómale foto a:**
• Tu nevera abierta
• Los ingredientes sobre la mesa
• Tu despensa

Te sugeriré recetas adaptadas a **exactamente** lo que tengas, desde opciones de 10 min hasta platos más elaborados.

¿Me muestras qué hay para trabajar?''';
    }

    return '''¡Entendido! 🎯

Para ayudarte mejor, necesito **ver** lo que quieres organizar o mejorar.

**Usa los botones de abajo:**
• 📷 **Cámara** - Análisis en tiempo real
• 🖼️ **Galería** - Sube una foto existente

Una vez que tenga la imagen, puedo crear planes, listas, recetas, outfits y más.

¿Qué te gustaría analizar?''';
  }

  /// Insights simulados para vista en vivo
  List<String> _getSimulatedLiveInsights(String context) {
    switch (context) {
      case 'Espacio / Habitación':
        return [
          'Detecto áreas que podrían organizarse mejor',
          '¿Quieres un plan rápido de 10 minutos?',
          'Tip: Empieza despejando superficies',
        ];
      case 'Nevera / Cocina':
        return [
          'Veo ingredientes para varias recetas',
          '¿Te sugiero opciones de comida?',
          'Algunos items podrían reorganizarse',
        ];
      case 'Ropa / Outfit':
        return [
          'Buenas opciones para combinar',
          '¿Quieres sugerencias de outfits?',
          'Los neutros son tu base perfecta',
        ];
      case 'Escritorio':
        return [
          'Tu espacio de trabajo tiene potencial',
          'Los cables podrían organizarse',
          '¿Te hago una guía de setup?',
        ];
      case 'Apuntes / Estudio':
        return [
          'Material de estudio detectado',
          '¿Creo un plan de repaso?',
          'Tip: Agrupa por tema o prioridad',
        ];
      default:
        return [
          'Analizando lo que veo...',
          'Selecciona un contexto específico',
          'Para mejor análisis usa los modos',
        ];
    }
  }

  /// Libera recursos
  void dispose() {
    _chatSession = null;
    _textModel = null;
    _visionModel = null;
    _isInitialized = false;
  }
}
