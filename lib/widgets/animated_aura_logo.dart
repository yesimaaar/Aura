import 'package:flutter/material.dart';
import '../core/theme/aura_theme.dart';

/// Widget que muestra "Aura" y se transforma en el logo cuando [showLogo] es true.
/// La transformación ocurre cuando el usuario envía un mensaje al chat.
class AnimatedAuraLogo extends StatefulWidget {
  final double height;
  final bool showLogo;
  
  const AnimatedAuraLogo({
    super.key,
    this.height = 40,
    this.showLogo = false,
  });

  @override
  State<AnimatedAuraLogo> createState() => _AnimatedAuraLogoState();
}

class _AnimatedAuraLogoState extends State<AnimatedAuraLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textOpacity;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  bool _hasAnimated = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // El texto se desvanece
    _textOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // El logo aparece
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // El logo crece ligeramente al aparecer
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // Si ya debe mostrar el logo, ir directo al final
    if (widget.showLogo) {
      _controller.value = 1.0;
      _hasAnimated = true;
    }
  }
  
  @override
  void didUpdateWidget(AnimatedAuraLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Cuando showLogo cambia de false a true, animar
    if (widget.showLogo && !oldWidget.showLogo && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AuraColors.getAccentColor(isDark);
    
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Texto "Aura" que se desvanece
              Opacity(
                opacity: _textOpacity.value,
                child: Text(
                  'Aura',
                  style: TextStyle(
                    fontSize: widget.height * 0.75,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              // Logo que aparece y se queda
              Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Image.asset(
                    'assets/icons/aura_logo_header.png',
                    height: widget.height,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
