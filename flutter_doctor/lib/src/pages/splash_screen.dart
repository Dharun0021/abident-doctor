import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class SplashScreen extends StatefulWidget {
  final Future<bool> authCheckFuture;

  const SplashScreen({
    super.key,
    required this.authCheckFuture,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      body: Stack(
        children: [
          // Background Gradient with Animated Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5 + (_controller.value * 0.2),
                      colors: const [
                        Color(0xFF161B33),
                        Color(0xFF060912),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle Floating Particles Effect
          ...List.generate(5, (index) {
            return Positioned(
              top: 100.0 * (index + 1),
              left: 50.0 * (index * 2),
              child: FadeIn(
                delay: Duration(milliseconds: 500 * index),
                duration: const Duration(seconds: 3),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6CC042).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with sophisticated animation
                ElasticIn(
                  duration: const Duration(milliseconds: 2000),
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6CC042).withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 180,
                          color: const Color(0xFF6CC042),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Branding with animated letter-spacing
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 800),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 12.0, end: 8.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Text(
                        'ABIDENT DOCTOR',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Animated Divider
                FadeIn(
                  delay: const Duration(milliseconds: 1500),
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6CC042), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline with Slide effect
                FadeInUp(
                  delay: const Duration(milliseconds: 1800),
                  child: Text(
                    'DOCTOR PANEL',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6CC042).withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeIn(
              delay: const Duration(seconds: 2),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6CC042)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CONNECTING TO SYSTEM',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}