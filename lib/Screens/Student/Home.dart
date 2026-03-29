import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:voicenote/Models/AppUser.dart';
import 'package:voicenote/Models/TimetableEntry.dart';
import 'package:voicenote/Services/AuthService.dart';
import 'package:voicenote/Services/TimetableService.dart';

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
  final TimetableService _timetableService = TimetableService();

  AppUser? _appUser;
  List<TimetableEntry> _todaySchedule = [];
  bool _isLoading = true;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning 👋";
    if (hour < 17) return "Good Afternoon ☀️";
    if (hour < 21) return "Good Evening 🌆 ";
    return "Good Night 🌙";
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = await _authService.getCurrentAppUser();
      
      if (user != null) {
        // UPDATED: Now calls getCurrentWeekEntries to filter by the current academic week
        final entries = await _timetableService.getCurrentWeekEntries(user.degree ?? "", user.uid);
        
        String todayName = DateFormat('EEEE').format(DateTime.now());

        if (!mounted) return;

        setState(() {
          _appUser = user;
          _todaySchedule = entries.where((e) => e.day == todayName).toList();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            Text(getGreeting(), style: const TextStyle(color: Home.subText, fontSize: 13)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Home.text),
                children: [
                  const TextSpan(text: "Hey, "),
                  TextSpan(text: displayName, style: const TextStyle(color: Home.teal)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: _isLoading ? "..." : "${_todaySchedule.length}",
                    label: "Modules today",
                    valueColor: Home.teal,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
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
              style: TextStyle(color: Home.subText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Home.teal))
            else if (_todaySchedule.isEmpty)
              _buildEmptyScheduleNotice()
            else
              ..._todaySchedule.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ScheduleTile(
                      time: entry.startTime.length >= 5 
                          ? entry.startTime.substring(0, 5) 
                          : entry.startTime,
                      title: entry.moduleCode == "SPECIAL" ? entry.rawText : entry.moduleCode,
                      subtitle: "Week ${entry.week} · ${entry.rawText}",
                      lineColor: Home.teal,
                    ),
                  )).toList(),

            const SizedBox(height: 20),
            const Text(
              "QUICK ACTIONS",
              style: TextStyle(color: Home.subText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ActionCard(icon: Icons.mic_rounded, title: "Record", description: "Capture lectures", iconColor: Home.teal),
                _ActionCard(icon: Icons.note_alt_rounded, title: "Notes", description: "View notes", iconColor: Home.amber),
                _ActionCard(icon: Icons.track_changes_rounded, title: "Exam Focus", description: "Track progress", iconColor: Home.coral),
                _ActionCard(icon: Icons.style_rounded, title: "Flashcards", description: "Quick revision", iconColor: Home.purple),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "LECTURE RECAP",
              style: TextStyle(color: Home.subText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            _buildRecapCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapCard() {
    return Container(
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
            height: 42, width: 42,
            decoration: BoxDecoration(
              color: Home.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Home.purple),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Data Structures", style: TextStyle(color: Home.text, fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text("Last week: Trees, BFS/DFS traversal", style: TextStyle(color: Home.subText, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Home.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Home.cardBorder),
      ),
      child: const Text(
        "No lectures scheduled for today. Upload a file or wait for the new week.",
        style: TextStyle(color: Home.subText, fontSize: 13),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _StatCard({required this.value, required this.label, required this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Home.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Home.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Home.subText, fontSize: 12)),
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
  const _ScheduleTile({required this.time, required this.title, required this.subtitle, required this.lineColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 52, child: Text(time, textAlign: TextAlign.right, style: const TextStyle(color: Home.subText, fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Home.card,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: lineColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Home.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Home.subText, fontSize: 12)),
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
  const _ActionCard({required this.icon, required this.title, required this.description, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Home.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}