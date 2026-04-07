import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Theme/theme_helper.dart';
import 'LecturerRecordScreen.dart';

class LecturerHome extends StatefulWidget {
  const LecturerHome({super.key});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  int _foldersCount = 0;
  int _itemsCount = 0;
  int _recordingsCount = 0;

  Future<void> _loadStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Count folders
      final foldersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lecture_folders')
          .get();
      
      // Count all items across folders
      int totalItems = 0;
      for (var folderDoc in foldersSnap.docs) {
        final itemsSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('lecture_folders')
            .doc(folderDoc.id)
            .collection('items')
            .get();
        totalItems += itemsSnap.docs.length;
      }

      if (mounted) {
        setState(() {
          _foldersCount = foldersSnap.docs.length;
          _itemsCount = totalItems;
          _recordingsCount = totalItems;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.white).withValues(alpha: 0.7);

    final currentUser = _auth.currentUser;
    final userName = currentUser?.displayName ?? 'Lecturer';

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section with real user name
              Text(
                'Welcome back, $userName 👋',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s your today\'s overview.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 22),

              // Highlight card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.bg2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Teaching Workspace',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your lectures and resources from one place.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Stats row with real data
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      icon: Icons.folder_rounded,
                      value: _foldersCount.toString(),
                      label: 'Folders',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      context,
                      icon: Icons.description_rounded,
                      value: _itemsCount.toString(),
                      label: 'Items',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      icon: Icons.graphic_eq_rounded,
                      value: _recordingsCount.toString(),
                      label: 'Recordings',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      context,
                      icon: Icons.assessment_rounded,
                      value: '0',
                      label: 'Pending',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick actions title
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Access your everyday tools.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subColor,
                ),
              ),

              const SizedBox(height: 14),

              // Action cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _actionCard(
                    context,
                    icon: Icons.mic_rounded,
                    title: 'Start Recording',
                    subtitle: 'Record a lecture session.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LecturerRecordScreen(),
                        ),
                      );
                    },
                  ),
                  _actionCard(
                    context,
                    icon: Icons.folder_open_rounded,
                    title: 'My Folders',
                    subtitle: 'View all folders.',
                    onTap: () {},
                  ),
                  _actionCard(
                    context,
                    icon: Icons.refresh_rounded,
                    title: 'Refresh Stats',
                    subtitle: 'Update statistics.',
                    onTap: () {
                      _loadStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Stats refreshed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _actionCard(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Manage preferences.',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent activity title
              Text(
                'Summary Stats',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your lecture management overview.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subColor,
                ),
              ),

              const SizedBox(height: 14),

              _statsInfoTile(
                context,
                icon: Icons.folder_rounded,
                title: 'Total Folders',
                value: '$_foldersCount',
              ),
              const SizedBox(height: 10),
              _statsInfoTile(
                context,
                icon: Icons.description_rounded,
                title: 'Total Items',
                value: '$_itemsCount',
              ),
              const SizedBox(height: 10),
              _statsInfoTile(
                context,
                icon: Icons.graphic_eq_rounded,
                title: 'Recordings',
                value: '$_recordingsCount',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.white).withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.white).withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.white).withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Count: $value',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
