import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:efeflascard/screen/login_page.dart';
import 'dart:ui'; // For BackdropFilter

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _screenGlowAnimation;
  late Animation<double> _vibrateAnimation;
  late Animation<double> _pulseAnimation;
  final Random _random = Random();
  final List<Offset> _initialPositions = [];
  final List<Offset> _finalPositions = [];
  final List<double> _initialRotations = [];
  final List<IconData> _pieceIcons = [
    Icons.calculate,
    Icons.language,
    Icons.science,
    Icons.history_edu,
    Icons.book,
    Icons.computer,
    Icons.lightbulb,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4500,
      ), // Extended for dramatic glow
    );

    // Fade animation for logo and text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOutQuad),
      ),
    );

    // Glow animation for the final card
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Flip animation for the final card
    _flipAnimation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Gradient animation for background
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // Screen glow animation for "divine light" effect
    _screenGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Vibrate animation for final card
    _vibrateAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeInOutSine),
      ),
    );

    // Pulse animation for final card
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeInOutSine),
      ),
    );

    // Generate random initial and final positions for puzzle pieces
    for (int i = 0; i < 8; i++) {
      _initialPositions.add(
        Offset(
          _random.nextDouble() * 600 - 300,
          _random.nextDouble() * 800 - 400,
        ),
      );
      _finalPositions.add(Offset((i % 4) * 70.0 - 105, (i ~/ 4) * 100.0 - 50));
      _initialRotations.add(_random.nextDouble() * 0.8 - 0.4);
    }

    // Start animation
    _controller.forward();

    // Navigate to LoginPage after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(
              milliseconds: 1000,
            ), // Extended for smooth transition
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutQuad,
                  ),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient with golden tones
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        Color(0xFF0D0B3B),
                        Color(0xFFFFF7E6),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        Color(0xFF1A2257),
                        Color(0xFFD8D8D8),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        Color(0xFF3A497A),
                        Color(0xFFFFE4B5),
                        _gradientAnimation.value,
                      )!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    transform: GradientRotation(
                      _gradientAnimation.value * pi / 2,
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Particle loading indicator
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Stack(
                                children: List.generate(16, (index) {
                                  final angle =
                                      (index / 16) * 2 * pi +
                                      _controller.value * 2 * pi;
                                  final distance =
                                      120 +
                                      sin(_controller.value * pi * 2 + index) *
                                          20;
                                  return Positioned(
                                    left:
                                        constraints.maxWidth / 2 +
                                        cos(angle) * distance,
                                    top:
                                        constraints.maxHeight / 2 +
                                        sin(angle) * distance,
                                    child: Opacity(
                                      opacity:
                                          _fadeAnimation.value *
                                          (0.5 +
                                              0.5 *
                                                  sin(
                                                    index +
                                                        _controller.value * pi,
                                                  )),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                            0xFFFFF7E6,
                                          ).withOpacity(0.9), // Golden white
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(
                                                0xFFFFD700,
                                              ).withOpacity(0.5), // Gold glow
                                              blurRadius: 8,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          // Puzzle pieces
                          ...List.generate(8, (index) {
                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final progress = _controller.value;
                                final curve = Curves.easeOutBack.transform(
                                  progress,
                                );
                                final position =
                                    Offset.lerp(
                                      _initialPositions[index],
                                      _finalPositions[index],
                                      curve,
                                    )!;
                                final rotation =
                                    (1 - curve) * _initialRotations[index];
                                final scale =
                                    progress < 0.7
                                        ? 1.0 + sin(curve * pi) * 0.3
                                        : 0.0;
                                return Positioned(
                                  left: constraints.maxWidth / 2 + position.dx,
                                  top: constraints.maxHeight / 2 + position.dy,
                                  child: Transform.rotate(
                                    angle: rotation,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Opacity(
                                        opacity:
                                            progress < 0.7 ? progress : 0.0,
                                        child: Container(
                                          width: 70,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(
                                                  0xFFFFD700,
                                                ).withOpacity(0.5), // Gold glow
                                                blurRadius: 8,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _pieceIcons[index],
                                              size: 28,
                                              color: Color(
                                                0xFFFFF7E6,
                                              ).withOpacity(
                                                0.9,
                                              ), // Golden white
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),

                          // Final card with flip, vibrate, and pulse animation
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform(
                                transform:
                                    Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(_flipAnimation.value)
                                      ..translate(
                                        sin(_vibrateAnimation.value * pi * 10) *
                                            5,
                                        cos(_vibrateAnimation.value * pi * 10) *
                                            5,
                                      ),
                                alignment: Alignment.center,
                                child: Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Container(
                                      width: 260,
                                      height: 380,
                                      decoration: BoxDecoration(
                                        color:
                                            _flipAnimation.value < pi / 2
                                                ? Color(0xFFFFE4B5).withOpacity(
                                                  0.9,
                                                ) // Light gold
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFFFFD700,
                                            ).withOpacity(0.7), // Gold glow
                                            blurRadius: _glowAnimation.value,
                                            spreadRadius:
                                                _glowAnimation.value / 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child:
                                            _flipAnimation.value < pi / 2
                                                ? Text(
                                                  'Learn?',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                                : Image.asset(
                                                  'assets/flashgo_upgrade.png',
                                                  width: 200,
                                                  fit: BoxFit.contain,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Sparkle particles around final card
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Stack(
                                children: List.generate(12, (index) {
                                  final angle =
                                      (index / 12) * 2 * pi +
                                      _controller.value * pi;
                                  final distance =
                                      80 + _random.nextDouble() * 50;
                                  return Positioned(
                                    left:
                                        constraints.maxWidth / 2 +
                                        cos(angle) * distance,
                                    top:
                                        constraints.maxHeight / 2 +
                                        sin(angle) * distance,
                                    child: Opacity(
                                      opacity:
                                          _fadeAnimation.value *
                                          (0.5 +
                                              0.5 *
                                                  sin(
                                                    index +
                                                        _controller.value * pi,
                                                  )),
                                      child: Transform.scale(
                                        scale: 0.5 + _random.nextDouble() * 0.7,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(
                                              0xFFFFF7E6,
                                            ).withOpacity(0.9), // Golden white
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(
                                                  0xFFFFD700,
                                                ).withOpacity(0.6), // Gold glow
                                                blurRadius: 8,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          // Tagline with scale-up effect
                          Positioned(
                            bottom: constraints.maxHeight * 0.12,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  ScaleAnimatedText(
                                    'Piece by Piece, Master Your Skills',
                                    textStyle: GoogleFonts.poppins(
                                      fontSize: constraints.maxWidth * 0.05,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                      shadows: [
                                        Shadow(
                                          color: Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.4), // Gold shadow
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                  ),
                                ],
                                totalRepeatCount: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Screen glow effect with divine light
              AnimatedBuilder(
                animation: _screenGlowAnimation,
                builder: (context, child) {
                  return Container(
                    color: Color(0xFFFFF7E6).withOpacity(
                      _screenGlowAnimation.value * 0.6,
                    ), // Golden white
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _screenGlowAnimation.value * 12,
                        sigmaY: _screenGlowAnimation.value * 12,
                      ),
                      child: Container(
                        color: Color(0xFFD8D8D8).withOpacity(
                          _screenGlowAnimation.value * 0.4,
                        ), // Silver overlay
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
