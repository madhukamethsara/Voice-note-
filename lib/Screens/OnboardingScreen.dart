import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicenote/Models/Onboardingitem.dart';
import 'package:voicenote/Services/onboardingservice.dart';
import 'package:voicenote/Theme/theme_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();

  int _currentIndex = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: "Record Your Learning",
      subtitle:
          "Capture lectures, discussions, and your own study ideas in one place.",
      image: "lib/Assets/recording.png",
    ),
    OnboardingItem(
      title: "Showing deadlines and lectures",
      subtitle:
          "Add your university timetable we will automatically show the upcoming lectures and deadlines in the app.",
      image: "lib/Assets/Timetable.png",
    ),
    OnboardingItem(
      title: "Organize by Module",
      subtitle:
          "Keep notes, files, and recordings connected to the correct subject.",
      image: "lib/Assets/filehandling.png",
    ),
    OnboardingItem(
      title: "Practice with MCQs",
      subtitle:
          "Turn your saved learning content into multiple-choice questions for quick self-testing.",
      image: "lib/Assets/mcq.png",
    ),
    OnboardingItem(
      title: "Study Smarter",
      subtitle:
          "Use your saved content later for exam focus, revision, flashcards, and better preparation.",
      image: "lib/Assets/flashcards.png",
    ),
  ];

  Future<void> _finishOnboarding() async {
    await _onboardingService.setOnboardingSeen();

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      context.go('/Login');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = (doc.data()?['role'] ?? 'student')
          .toString()
          .trim()
          .toLowerCase();

      if (!mounted) return;

      if (role == 'student') {
        context.go('/dashboard');
      } else if (role == 'lecturer') {
        context.go('/lecturer-home');
      } else {
        context.go('/Login');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/Login');
    }
  }

  void _nextPage() {
    if (_currentIndex == _items.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required OnboardingItem item,
  }) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.text3.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: colors.teal.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: colors.teal,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text2,
              fontSize: 15.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: colors.text2,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              item.image,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colors.bg2,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.mobile_friendly_rounded,
                                      size: 90,
                                      color: colors.teal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureCard(
                          context: context,
                          item: item,
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: _currentIndex == index ? 24 : 10,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? colors.teal
                          : colors.text3.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.teal,
                    foregroundColor: colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _items.length - 1 ? "Get Started" : "Next",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
