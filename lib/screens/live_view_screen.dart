import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../providers/aura_provider.dart';
import '../providers/organization_provider.dart';
import '../core/theme/aura_theme.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({super.key});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final StorageService _storageService = StorageService();
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isLiveMode = false;
  String? _analysisResult;
  String? _liveComment;
  XFile? _capturedImage;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveMode(notify: false);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _toggleCamera() async {
    await _cameraService.switchCamera();
    setState(() {});
  }

  void _toggleLiveMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
      if (_isLiveMode) {
        _startLiveMode();
      } else {
        _stopLiveMode();
      }
    });
  }

  void _startLiveMode() {
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || !_isLiveMode || _isAnalyzing) return;
      await _analyzeLiveFrame();
    });
    // Trigger first analysis immediately
    _analyzeLiveFrame();
  }

  void _stopLiveMode({bool notify = true}) {
    _liveTimer?.cancel();
    _liveTimer = null;
    if (notify && mounted) {
      setState(() {
        _liveComment = null;
      });
    }
  }

  Future<void> _analyzeLiveFrame() async {
    if (_isAnalyzing) return;
    
    try {
      final xFile = await _cameraService.takePicture();
      if (xFile != null && mounted) {
        final provider = context.read<AuraProvider>();
        final File imageFile = File(xFile.path);
        
        // Short prompt for live mode
        const prompt = "En una frase muy corta (max 10 palabras), describe lo más importante que ves o da un consejo rápido.";
        
        final result = await provider.gemini.analyzeImage(imageFile, prompt: prompt);
        
        if (mounted && _isLiveMode) {
          // Ignorar errores de conexión en modo vivo para no interrumpir la experiencia
          if (!result.startsWith("Error") && !result.contains("Exception")) {
            setState(() {
              _liveComment = result;
            });
          }
        }
        
        // Clean up temp file
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
    } catch (e) {
      debugPrint("Live analysis error: $e");
    }
  }

  Future<void> _analyzeView() async {
    if (_isAnalyzing) return;
    _stopLiveMode(); // Stop live mode if manual capture

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final xFile = await _cameraService.takePicture();
      if (xFile != null && mounted) {
        setState(() {
          _capturedImage = xFile;
        });

        final provider = context.read<AuraProvider>();
        final File imageFile = File(xFile.path);
        
        // Prompt específico para "Live View"
        const prompt = """
Analiza lo que ves en esta imagen y actúa como un asistente personal proactivo.
- Si ves desorden o una habitación: Dame un plan paso a paso para organizarlo.
- Si ves comida o ingredientes: Sugiere una receta rápida o qué puedo cocinar.
- Si ves ropa: Sugiere un outfit o cómo organizarla.
- Si ves texto/apuntes: Resume los puntos clave o crea un plan de estudio.
- Si ves un objeto: Dime qué es y para qué sirve o cómo cuidarlo.

Sé directo, usa bullet points y emojis. Mantén la respuesta breve pero útil.
""";

        final result = await provider.gemini.analyzeImage(imageFile, prompt: prompt);
        
        if (mounted) {
          setState(() {
            _analysisResult = result;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al analizar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _resetView() {
    setState(() {
      _analysisResult = null;
      _capturedImage = null;
      _isLiveMode = false; // Reset live mode state
    });
  }

  Future<void> _saveAndExit() async {
    if (_capturedImage != null) {
      final auraImage = await _storageService.saveImage(_capturedImage!);
      if (mounted) {
        context.read<AuraProvider>().addImage(auraImage);
        context.read<AuraProvider>().selectImage(auraImage);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _processAutoOrganization() async {
    if (_analysisResult == null) return;

    // Detener modo live si está activo
    _stopLiveMode(notify: false);

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AuraColors.accentWhite),
      ),
    );

    try {
      final auraProvider = Provider.of<AuraProvider>(context, listen: false);
      final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
      
      // Construir prompt para extraer datos estructurados
      final prompt = """
      Basado en el siguiente análisis, crea una acción estructurada JSON para mi sistema de organización.
      
      Análisis previo:
      $_analysisResult
      
      Determina si esto debe ser una Tarea (Task), Receta (Recipe) o Recordatorio (Reminder).
      
      Formato JSON requerido (responde SOLO con el JSON válido, sin bloques de código markdown):
      {
        "type": "task" | "recipe" | "reminder",
        "title": "Título corto y descriptivo",
        "description": "Descripción detallada basada en el análisis",
        "category": "Categoría sugerida",
        "ingredients": ["ingrediente 1", "ingrediente 2"], // Solo si es recipe
        "steps": ["paso 1", "paso 2"], // Solo si es recipe
        "prepTime": 15, // Solo si es recipe (minutos)
        "priority": 2, // Solo si es task (1=baja, 2=media, 3=alta)
        "dateTime": "YYYY-MM-DDTHH:mm:ss" // Solo si es reminder
      }
      """;

      final jsonResponse = await auraProvider.gemini.sendMessage(prompt);
      
      // Limpiar respuesta (eliminar bloques de código markdown si existen)
      String cleanJson = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Intentar encontrar el JSON si hay texto extra
      final jsonStartIndex = cleanJson.indexOf('{');
      final jsonEndIndex = cleanJson.lastIndexOf('}');
      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        cleanJson = cleanJson.substring(jsonStartIndex, jsonEndIndex + 1);
      }
      
      final data = jsonDecode(cleanJson);
      final type = data['type'];
      
      if (type == 'task') {
        await organizationProvider.createTaskFromAI(
          title: data['title'],
          description: data['description'],
          category: data['category'],
          priority: data['priority'] ?? 2,
        );
      } else if (type == 'recipe') {
        await organizationProvider.createRecipeFromAI(
          title: data['title'],
          description: data['description'],
          ingredients: List<String>.from(data['ingredients'] ?? []),
          steps: List<String>.from(data['steps'] ?? []),
          prepTime: data['prepTime'],
          category: data['category'],
        );
      } else if (type == 'reminder') {
        await organizationProvider.createReminderFromAI(
          title: data['title'],
          description: data['description'],
          dateTime: data['dateTime'] != null 
              ? DateTime.parse(data['dateTime']) 
              : DateTime.now().add(const Duration(hours: 1)),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo
        Navigator.pop(context); // Cerrar LiveViewScreen
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡${data['title']} añadido a ${type == 'recipe' ? 'Recetas' : type == 'task' ? 'Tareas' : 'Recordatorios'}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-organizing: $e');
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al organizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraService.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: _capturedImage != null 
              ? Image.file(File(_capturedImage!.path))
              : CameraPreview(_cameraService.controller!),
          ),
          
          // Live Comment Overlay (Glassmorphism at bottom)
          if (_isLiveMode && _liveComment != null)
            Positioned(
              bottom: 140, // Above the controls
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AuraColors.accentWhite.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: AuraColors.accentWhite, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _liveComment!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ),

          // Analysis Overlay (Manual Capture)
          if (_analysisResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AuraColors.accentWhite, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Análisis de Aura',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: _resetView,
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: MarkdownBody(
                          data: _analysisResult!,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            listBullet: const TextStyle(color: AuraColors.accentWhite),
                            strong: const TextStyle(color: AuraColors.accentWhite, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resetView,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Nueva captura'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveAndExit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AuraColors.accentWhite,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Usar en Chat'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processAutoOrganization,
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Agregar a Organización (Auto)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slide(begin: const Offset(0, 1), end: Offset.zero, duration: 300.ms),
            ),

          // Loading Overlay
          if (_isAnalyzing && !_isLiveMode)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AuraColors.accentWhite),
                    const SizedBox(height: 16),
                    Text(
                      'Analizando entorno...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn().shimmer(),
                  ],
                ),
              ),
            ),

          // Controls (Only visible when not analyzing manually and no result)
          if ((!_isAnalyzing || _isLiveMode) && _analysisResult == null)
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Live Mode Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Switch(
                                value: _isLiveMode,
                                onChanged: (_) => _toggleLiveMode(),
                                activeThumbColor: AuraColors.accentWhite,
                                activeTrackColor: AuraColors.accentWhite.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      children: [
                        if (!_isLiveMode)
                          Text(
                            'Apunta y escanea para recibir consejos',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Switch Camera Button
                            IconButton(
                              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                              onPressed: _toggleCamera,
                            ),

                            // Capture Button
                            GestureDetector(
                              onTap: _analyzeView,
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isLiveMode ? AuraColors.accentWhite : Colors.white, 
                                    width: 4
                                  ),
                                  color: Colors.white24,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isLiveMode ? AuraColors.accentWhite : Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.black,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Placeholder for balance
                            const SizedBox(width: 50),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
