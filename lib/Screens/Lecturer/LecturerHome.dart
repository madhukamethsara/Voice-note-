import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:voicenote/Models/AppUser.dart';
import 'package:voicenote/Models/TimetableEntry.dart';
import 'package:voicenote/Services/AuthService.dart';
import 'package:voicenote/Services/TimetableService.dart';

class LecturerHome extends StatefulWidget {
  const LecturerHome({super.key});

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
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
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
        final entries = await _timetableService.getCurrentWeekEntries();
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
              : 'Lecturer');

    return Container(
      color: LecturerHome.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Text(getGreeting(), style: const TextStyle(color: LecturerHome.subText, fontSize: 13)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LecturerHome.text),
                children: [
                  const TextSpan(text: "Hey, "),
                  TextSpan(text: displayName, style: const TextStyle(color: LecturerHome.teal)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "TODAY'S SCHEDULE",
              style: TextStyle(color: LecturerHome.subText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: LecturerHome.teal))
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
                      lineColor: LecturerHome.teal,
                    ),
                  )),

            const SizedBox(height: 24),
            const Text(
              "QUICK ACTIONS",
              style: TextStyle(color: LecturerHome.subText, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
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
                _ActionCard(icon: Icons.mic_rounded, title: "Record", description: "Capture lectures", iconColor: LecturerHome.teal),
                _ActionCard(icon: Icons.note_alt_rounded, title: "Notes", description: "View notes", iconColor: LecturerHome.amber),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: LecturerHome.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LecturerHome.cardBorder),
      ),
      child: const Text(
        "No lectures scheduled for today. Upload a file or wait for the new week.",
        style: TextStyle(color: LecturerHome.subText, fontSize: 13),
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
        SizedBox(width: 52, child: Text(time, textAlign: TextAlign.right, style: const TextStyle(color: LecturerHome.subText, fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LecturerHome.card,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: lineColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LecturerHome.text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LecturerHome.subText, fontSize: 12)),
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
      decoration: BoxDecoration(color: LecturerHome.card, borderRadius: BorderRadius.circular(16)),
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