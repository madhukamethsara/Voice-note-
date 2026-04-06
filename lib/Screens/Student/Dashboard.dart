import 'package:flutter/material.dart';
import '../../Theme/theme_helper.dart';

import 'Home.dart';
import 'Profile.dart';
import 'TimeTable.dart';
import 'RecordScreen.dart';
import 'Notes.dart';

class Dashboard extends StatefulWidget {
  final String senderName;
  final String senderRole;

  const Dashboard({
    super.key,
    required this.senderName,
    required this.senderRole,
  });

  @override
  State<Dashboard> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<Dashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const Home(),
      const TimetableScreen(),
      const RecordScreen(),
      Notes(
        senderName: widget.senderName,
        senderRole: widget.senderRole,
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: colors.bg2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.teal,
        unselectedItemColor: colors.text2,
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
    final colors = context.colors;

    return Center(
      child: Text(
        "Timetable Screen",
        style: TextStyle(color: colors.text),
      ),
    );
  }
}

class StudentRecordScreen extends StatelessWidget {
  const StudentRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Text(
        "Record Screen",
        style: TextStyle(color: colors.text),
      ),
    );
  }
}

class StudentNotesScreen extends StatelessWidget {
  const StudentNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Text(
        "Notes Screen",
        style: TextStyle(color: colors.text),
      ),
    );
  }
}