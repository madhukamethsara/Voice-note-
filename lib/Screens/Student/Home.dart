import 'package:flutter/material.dart';
import 'package:voicenote/Model/AppUser.dart';
import 'package:voicenote/Services/AuthService.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  static const Color bg = Color(0xFF0D0F14);
  static const Color card = Color(0xFF141720);
  static const Color cardBorder = Color(0xFF232840);
  static const Color teal = Color(0xFF00E5B0);
  static const Color amber = Color(0xFFFFC145);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFFA78BFA);
  static const Color text = Color(0xFFF0F2FF);
  static const Color subText = Color(0xFF8B92B8);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();

  AppUser? _appUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentAppUser();

      if (!mounted) return;

      setState(() {
        _appUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _isLoading
        ? '...'
        : (_appUser?.fullName.isNotEmpty == true
              ? _appUser!.fullName
              : 'Student');

    return Container(
      color: Home.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Text(
              "Good morning 👋",
              style: TextStyle(color: Home.subText, fontSize: 13),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Home.text,
                ),
                children: [
                  const TextSpan(text: "Hey, "),
                  TextSpan(
                    text: displayName,
                    style: const TextStyle(color: Home.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    value: "6",
                    label: "Modules active",
                    valueColor: Home.teal,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: "3",
                    label: "Exams coming",
                    valueColor: Home.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "TODAY'S SCHEDULE",
              style: TextStyle(
                color: Home.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            const _ScheduleTile(
              time: "9:00",
              title: "Data Structures",
              subtitle: "Hall B · 2 hrs",
              lineColor: Home.teal,
            ),
            const SizedBox(height: 10),
            const _ScheduleTile(
              time: "13:00",
              title: "Software Engineering",
              subtitle: "Room 204 · 1.5 hrs",
              lineColor: Home.coral,
            ),
            const SizedBox(height: 20),
            const Text(
              "QUICK ACTIONS",
              style: TextStyle(
                color: Home.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ActionCard(
                  icon: Icons.mic_rounded,
                  title: "Record",
                  description: "Capture lectures easily",
                  iconColor: Home.teal,
                ),
                _ActionCard(
                  icon: Icons.note_alt_rounded,
                  title: "Notes",
                  description: "View and manage notes",
                  iconColor: Home.amber,
                ),
                _ActionCard(
                  icon: Icons.track_changes_rounded,
                  title: "Exam Focus",
                  description: "Track exam progress",
                  iconColor: Home.coral,
                ),
                _ActionCard(
                  icon: Icons.style_rounded,
                  title: "Flashcards",
                  description: "Quick revision cards",
                  iconColor: Home.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "LECTURE RECAP",
              style: TextStyle(
                color: Home.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Home.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Home.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Home.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Home.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Data Structures",
                          style: TextStyle(
                            color: Home.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Last week: Trees, BFS/DFS traversal",
                          style: TextStyle(color: Home.subText, fontSize: 12),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tap to review before today's lecture →",
                          style: TextStyle(color: Home.subText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232840)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8B92B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final Color lineColor;

  const _ScheduleTile({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            time,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF8B92B8), fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141720),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: lineColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF0F2FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8B92B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141720),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          Icon(icon, color: iconColor, size: 28),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center, // 👈 IMPORTANT
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            description,
            textAlign: TextAlign.center, 
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}