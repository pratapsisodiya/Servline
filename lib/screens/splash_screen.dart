import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Text animations
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _logoController.forward();

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Navigate to intro after animation
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go('/intro');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _logoSlide.value.dx * 100,
                    _logoSlide.value.dy * 100,
                  ),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value * 0.2,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3B82F6), // Blue-500
                              Color(0xFF2563EB), // Blue-600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 35,
                              color: Colors.white,
                            ),
                            Positioned(
                              bottom: 8,
                              child: Container(
                                width: 40,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 16),

            // Animated Text
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _textSlide.value.dx * 100,
                    _textSlide.value.dy * 100,
                  ),
                  child: Opacity(
                    opacity: _textFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Servline',
                          style: GoogleFonts.poppins(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Queue Management',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
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
      ),
    );
  }
}
