import 'package:flutter/material.dart';
import 'Home.dart';
import 'Profile.dart';
import 'TimeTable.dart';
import 'RecordScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<Dashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    TimetableScreen(),
    RecordScreen(),
    StudentNotesScreen(),
    ProfileScreen(),
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

class StudentTimetableScreen extends StatelessWidget {
  const StudentTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Timetable Screen", style: TextStyle(color: Colors.white)),
    );
  }
}

class StudentRecordScreen extends StatelessWidget {
  const StudentRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Record Screen", style: TextStyle(color: Colors.white)),
    );
  }
}

class StudentNotesScreen extends StatelessWidget {
  const StudentNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Notes Screen", style: TextStyle(color: Colors.white)),
    );
  }
}
