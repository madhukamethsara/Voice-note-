import 'package:flutter/material.dart';
import '../../Theme/theme_helper.dart';

// Screens
import 'LecturerHome.dart';
import 'LecturerModulesScreen.dart';
import 'LecturerRecordScreen.dart';
import 'LecturerFilesScreen.dart';
import 'LecturerProfile.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LecturerHome(),
    LecturerModulesScreen(),
    LecturerRecordScreen(),
    LecturerFilesScreen(),
    LecturerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.bg2,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: colors.bg2,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.textTheme.bodySmall?.color?.withOpacity(
            0.65,
          ),
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Modules',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_rounded),
              label: 'Record',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_rounded),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
