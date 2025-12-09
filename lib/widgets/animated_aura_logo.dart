import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/aura_theme.dart';

/// Widget animado que alterna entre el texto "Aura" y el logo de la app
class AnimatedAuraLogo extends StatefulWidget {
  final double height;
  final Duration interval;

  const AnimatedAuraLogo({
    super.key,
    this.height = 36,
    this.interval = const Duration(seconds: 5),
  });

  @override
  State<AnimatedAuraLogo> createState() => _AnimatedAuraLogoState();
}

class _AnimatedAuraLogoState extends State<AnimatedAuraLogo>
    with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      await Future.delayed(widget.interval);
      if (!mounted) return;

      // Animar hacia el logo
      setState(() => _showLogo = true);
      _controller.forward();

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      // Animar de vuelta al texto
      _controller.reverse();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _showLogo = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      child: _showLogo ? _buildLogo() : _buildText(),
    );
  }

  Widget _buildText() {
    return ShaderMask(
      key: const ValueKey('text'),
      shaderCallback: (bounds) => AuraColors.auraGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        'Aura',
        style: TextStyle(
          fontSize: widget.height * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
          key: const ValueKey('logo'),
          height: widget.height,
          width: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height * 0.25),
            child: Image.asset('assets/icons/aura_logo.png', fit: BoxFit.cover),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}
