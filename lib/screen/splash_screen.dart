import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:efeflascard/screen/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<Color?> _gradientAnimation;
  final List<String> motivationalTexts = [
    "Let's Get Started!",
    "Master Any Subject!",
  ];
  int currentMotivationalIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3000,
      ), // Further shortened for snappy feel
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xFF0D0B3B),
      end: const Color(0xFF3A497A),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );

    _scaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOutQuad),
      ),
    );

    _textScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          currentMotivationalIndex =
              (currentMotivationalIndex + 1) % motivationalTexts.length;
        });
      } else {
        timer.cancel();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
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
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
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
        animation: _gradientAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientAnimation.value!,
                  const Color(0xFF1A2257),
                  const Color(0xFF3A497A),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Enhanced particles with smoother motion
                            ...List.generate(
                              20,
                              (index) => Positioned(
                                left:
                                    _random.nextDouble() * constraints.maxWidth,
                                top:
                                    _random.nextDouble() *
                                    constraints.maxHeight,
                                child: Transform.translate(
                                  offset: Offset(
                                    sin(_controller.value * pi * 1.2 + index) *
                                        15,
                                    cos(_controller.value * pi * 1.2 + index) *
                                        15,
                                  ),
                                  child: Opacity(
                                    opacity: 0.7 + _controller.value * 0.2,
                                    child: Container(
                                      width: 3 + _random.nextDouble() * 3,
                                      height: 3 + _random.nextDouble() * 3,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.cyanAccent.withOpacity(
                                          0.9,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.cyanAccent
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Main content
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Main title
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth * 0.05,
                                  ),
                                  child: Transform.scale(
                                    scale: _textScaleAnimation.value,
                                    child: Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.cyanAccent.withOpacity(
                                                0.9,
                                              ),
                                              Colors.blueAccent.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                            stops: const [0.2, 0.6, 1.0],
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          'FlashGo',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                constraints.maxWidth * 0.12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.cyanAccent
                                                    .withOpacity(0.5),
                                                offset: const Offset(0, 0),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: constraints.maxHeight * 0.04),

                                // Motivational text
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.1),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutQuad,
                                          ),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    motivationalTexts[currentMotivationalIndex],
                                    key: ValueKey<String>(
                                      motivationalTexts[currentMotivationalIndex],
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: constraints.maxWidth * 0.05,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),

                                SizedBox(height: constraints.maxHeight * 0.06),

                                // Loading indicator
                                Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          value: _controller.value,
                                          strokeWidth: 2,
                                          color: Colors.cyanAccent.withOpacity(
                                            0.9,
                                          ),
                                          backgroundColor: Colors.white
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                      Transform.rotate(
                                        angle: _controller.value * pi * 2,
                                        child: Icon(
                                          Icons.star,
                                          size: 20,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
