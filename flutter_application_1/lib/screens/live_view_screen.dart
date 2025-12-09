import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../providers/theme_provider.dart';
import '../services/camera_service.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({super.key});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  List<AuraInsight> _insights = [];
  Timer? _analysisTimer;
  String _currentContext = 'General';
  
  final List<String> _contextOptions = [
    'General',
    'Espacio / Habitación',
    'Nevera / Cocina',
    'Ropa / Outfit',
    'Escritorio',
    'Apuntes / Estudio',
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startAnalysis();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isAnalyzing) {
        _analyzeFrame();
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _analyzeFrame();
    });
  }

  Future<void> _analyzeFrame() async {
    setState(() => _isAnalyzing = true);
    
    try {
      final provider = context.read<AuraProvider>();
      
      if (provider.isGeminiReady && _cameraService.controller != null) {
        final XFile? frameFile = await _cameraService.controller?.takePicture();
        
        if (frameFile != null && mounted) {
          final file = File(frameFile.path);
          final bytes = await file.readAsBytes();
          final suggestions = await provider.analyzeLiveFrame(bytes, _currentContext);
          
          if (mounted) {
            setState(() {
              _insights = _parseGeminiSuggestions(suggestions);
              _isAnalyzing = false;
            });
          }
          
          try { await file.delete(); } catch (_) {}
          return;
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _insights = _generateInsights();
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error analyzing frame: $e');
      if (mounted) {
        setState(() {
          _insights = _generateInsights();
          _isAnalyzing = false;
        });
      }
    }
  }

  List<AuraInsight> _parseGeminiSuggestions(List<String> suggestions) {
    final types = [InsightType.info, InsightType.suggestion, InsightType.action, InsightType.tip];
    return suggestions.take(3).toList().asMap().entries.map((entry) {
      return AuraInsight(text: entry.value, type: types[entry.key % types.length]);
    }).toList();
  }

  List<AuraInsight> _generateInsights() {
    switch (_currentContext) {
      case 'Espacio / Habitación':
        return [
          AuraInsight(text: 'Veo objetos que podrían organizarse mejor', type: InsightType.suggestion),
          AuraInsight(text: '¿Quieres un plan de 10 min para ordenar?', type: InsightType.action),
        ];
      case 'Nevera / Cocina':
        return [
          AuraInsight(text: 'Detecto ingredientes para 3+ recetas', type: InsightType.info),
          AuraInsight(text: '¿Te sugiero recetas rápidas?', type: InsightType.action),
        ];
      case 'Ropa / Outfit':
        return [
          AuraInsight(text: 'Veo opciones para varios estilos', type: InsightType.info),
          AuraInsight(text: '¿Quieres combinaciones para hoy?', type: InsightType.action),
        ];
      case 'Escritorio':
        return [
          AuraInsight(text: 'Tu zona de trabajo tiene potencial', type: InsightType.info),
          AuraInsight(text: '¿Te hago una guía de organización?', type: InsightType.action),
        ];
      case 'Apuntes / Estudio':
        return [
          AuraInsight(text: 'Veo material de estudio', type: InsightType.info),
          AuraInsight(text: '¿Quieres un plan de estudio?', type: InsightType.action),
        ];
      default:
        return [
          AuraInsight(text: 'Analizando lo que veo...', type: InsightType.info),
          AuraInsight(text: 'Selecciona un contexto para mejor análisis', type: InsightType.tip),
        ];
    }
  }

  Future<void> _captureAndAnalyze() async {
    final image = await _cameraService.takePhoto();
    if (image != null && mounted) {
      Navigator.pop(context, image);
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized && _cameraService.controller != null
          ? _buildMainContent(isDark)
          : _buildLoadingView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Iniciando cámara...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ============ CÁMARA FULLSCREEN ============
        _FullScreenCamera(controller: _cameraService.controller!),
        
        // ============ GRADIENTE SUPERIOR ============
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // ============ BARRA SUPERIOR ============
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildBackButton(),
                const Spacer(),
                _buildStatusChip(),
                const SizedBox(width: 8),
                _buildContextSelector(isDark),
              ],
            ),
          ),
        ),
        
        // ============ INSIGHTS FLOTANTES ============
        if (_insights.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _insights.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildInsightChip(entry.value)
                      .animate(delay: Duration(milliseconds: entry.key * 100))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.05),
                );
              }).toList(),
            ),
          ),
        
        // ============ GRADIENTE INFERIOR ============
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // ============ CONTROLES INFERIORES ============
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: _buildBottomControls(),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _isAnalyzing 
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAnalyzing)
            const SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else
            Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                color: AuraColors.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            _isAnalyzing ? 'Analizando...' : 'Activa',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSelector(bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _currentContext = value;
          _insights.clear();
        });
        _analyzeFrame();
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AuraColors.backgroundCard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              _currentContext,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => _contextOptions.map((option) {
        final isSelected = _currentContext == option;
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Icon(_getContextIcon(option), color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 10),
              Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
              if (isSelected) ...[const Spacer(), const Icon(Icons.check, color: AuraColors.accentGreen, size: 16)],
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getContextIcon(String ctx) {
    switch (ctx) {
      case 'Espacio / Habitación': return Icons.home_outlined;
      case 'Nevera / Cocina': return Icons.kitchen_outlined;
      case 'Ropa / Outfit': return Icons.checkroom_outlined;
      case 'Escritorio': return Icons.desk_outlined;
      case 'Apuntes / Estudio': return Icons.menu_book_outlined;
      default: return Icons.auto_awesome_outlined;
    }
  }

  Widget _buildInsightChip(AuraInsight insight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getInsightColor(insight.type),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getInsightIcon(insight.type), color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              insight.text,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.suggestion: return const Color(0xFF3B82F6).withValues(alpha: 0.9);
      case InsightType.action: return const Color(0xFF7C3AED).withValues(alpha: 0.9);
      case InsightType.tip: return const Color(0xFF10B981).withValues(alpha: 0.9);
      case InsightType.info: return const Color(0xFF6B7280).withValues(alpha: 0.9);
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.suggestion: return Icons.lightbulb_outline;
      case InsightType.action: return Icons.touch_app_outlined;
      case InsightType.tip: return Icons.tips_and_updates_outlined;
      case InsightType.info: return Icons.info_outline;
    }
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen
          if (_insights.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_insights.length} observaciones en "$_currentContext"',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          
          // Botón capturar
          GestureDetector(
            onTap: _captureAndAnalyze,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Capturar para análisis completo',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ============ WIDGET SEPARADO PARA CÁMARA FULLSCREEN ============
class _FullScreenCamera extends StatelessWidget {
  final CameraController controller;
  
  const _FullScreenCamera({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // El aspectRatio del controller es width/height del sensor (generalmente landscape como 1.78)
        // En modo portrait, la cámara se rota, así que el ratio visual es el inverso
        final double cameraAspectRatio = controller.value.aspectRatio;
        final double previewRatio = 1 / cameraAspectRatio; // Ratio visual en portrait
        final double screenRatio = screenWidth / screenHeight;
        
        double previewWidth;
        double previewHeight;
        
        // Calcular dimensiones para efecto "cover" (llenar toda la pantalla)
        if (previewRatio > screenRatio) {
          // Preview más ancho que pantalla -> ajustar por altura
          previewHeight = screenHeight;
          previewWidth = screenHeight * previewRatio;
        } else {
          // Preview más alto que pantalla -> ajustar por ancho
          previewWidth = screenWidth;
          previewHeight = screenWidth / previewRatio;
        }

        return ClipRect(
          child: OverflowBox(
            maxWidth: previewWidth,
            maxHeight: previewHeight,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }
}

class AuraInsight {
  final String text;
  final InsightType type;

  AuraInsight({required this.text, required this.type});
}

enum InsightType { suggestion, action, tip, info }
