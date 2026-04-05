import 'package:flutter/material.dart';
import 'LecturerHome.dart';
import 'LecturerProfile.dart';
//import 'LecturerTimetable.dart';
//import 'LecturerRecordScreen.dart';
//import 'LecturerNotes.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LecturerHome(),
    //LecturerTimetableScreen(),
    //LecturerRecordScreen(),
    //LecturerNotes(),
    LecturerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF141720),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00E5B0),
        unselectedItemColor: const Color(0xFF8B92B8),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: "Timetable",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_rounded),
            label: "Record",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_rounded),
            label: "Notes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}