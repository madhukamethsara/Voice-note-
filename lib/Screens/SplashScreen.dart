import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Theme/theme_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 1. Scale-in + overshoot (spring feel)
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // 2. Fade in
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 3. Gentle float (looping)
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // 4. Glow pulse (looping)
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // 5. Buttons slide up after logo settles
  late AnimationController _buttonsController;
  late Animation<double> _buttonsSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;

  @override
  void initState() {
    super.initState();

    // --- Scale controller: logo pops in with overshoot ---
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_scaleController);

    // --- Fade controller: logo fades in ---
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // --- Float controller: gentle up/down loop ---
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // --- Glow controller: opacity pulse ---
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // --- Buttons controller: slide up + fade after logo settles ---
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonsSlideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );
    _buttonsFadeAnimation = CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeIn,
    );

    // --- Sequence: start scale + fade together, then start buttons ---
    _scaleController.forward();
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated Logo ──────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleAnimation,
                  _fadeAnimation,
                  _floatAnimation,
                  _glowAnimation,
                ]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow halo behind logo
                            Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.black
                                        .withOpacity(_glowAnimation.value),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Logo image
                            Image.asset(
                              'lib/Assets/logo.png',
                              width: 340,
                              height: 340,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

         
              AnimatedBuilder(
                animation: _buttonsController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _buttonsSlideAnimation.value),
                    child: Opacity(
                      opacity: _buttonsFadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Get Started
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/roleselect');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.black,
                          foregroundColor: colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("Get started"),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/Login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.white,
                          foregroundColor: colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("Already have an account"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
