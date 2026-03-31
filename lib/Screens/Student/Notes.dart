import 'package:flutter/material.dart';
import '../../Theme/theme.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final List<_ModuleFileItem> _modules = const [
    _ModuleFileItem(
      moduleName: 'Mobile Application Development',
      moduleCode: 'PUSL 2344',
      totalFiles: 12,
      accentColor: AppColors.teal,
      lastUpdated: 'Updated today',
    ),
    _ModuleFileItem(
      moduleName: 'Software Engineering',
      moduleCode: 'PUSL 2023',
      totalFiles: 9,
      accentColor: AppColors.purple,
      lastUpdated: 'Updated yesterday',
    ),
    _ModuleFileItem(
      moduleName: 'Introduction to IoT',
      moduleCode: 'PUSL 2032',
      totalFiles: 7,
      accentColor: AppColors.blue,
      lastUpdated: 'Updated 2 days ago',
    ),
    _ModuleFileItem(
      moduleName: 'Information Management',
      moduleCode: 'PUSL 2025',
      totalFiles: 10,
      accentColor: AppColors.amber,
      lastUpdated: 'Updated this week',
    ),
  ];

  final List<_RecentUpdateItem> _recentUpdates = const [
    _RecentUpdateItem(
      title: 'Week 05 Lecture Summary added',
      moduleName: 'Mobile Application Development',
      time: 'Today • 5:40 PM',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.teal,
    ),
    _RecentUpdateItem(
      title: 'Database Design Note updated',
      moduleName: 'Software Engineering',
      time: 'Yesterday • 8:10 PM',
      icon: Icons.sticky_note_2_rounded,
      color: AppColors.amber,
    ),
    _RecentUpdateItem(
      title: 'Lecture Transcript saved',
      moduleName: 'Introduction to IoT',
      time: 'Yesterday • 3:05 PM',
      icon: Icons.description_rounded,
      color: AppColors.blue,
    ),
    _RecentUpdateItem(
      title: 'New Recording uploaded',
      moduleName: 'Information Management',
      time: 'Mar 28 • 7:15 PM',
      icon: Icons.mic_rounded,
      color: AppColors.coral,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      title: 'Your Modules',
                      subtitle: 'Open files by module name',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _modules.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList.separated(
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return _buildModuleCard(module);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: _buildSectionTitle(
                  title: 'Recent Updates',
                  subtitle: 'Latest activity from your module files',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _recentUpdates.length,
                itemBuilder: (context, index) {
                  final item = _recentUpdates[index];
                  return _buildRecentUpdateCard(item);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.text2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(_ModuleFileItem module) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${module.moduleName} clicked'),
            backgroundColor: AppColors.bg2,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.bg4),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: module.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.moduleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.moduleCode,
                    style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${module.totalFiles} files • ${module.lastUpdated}',
                    style: TextStyle(
                      color: module.accentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.text3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUpdateCard(_RecentUpdateItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bg4),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.moduleName,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.bg4),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 42,
            color: AppColors.text3,
          ),
          SizedBox(height: 10),
          Text(
            'No modules yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your module files will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleFileItem {
  final String moduleName;
  final String moduleCode;
  final int totalFiles;
  final Color accentColor;
  final String lastUpdated;

  const _ModuleFileItem({
    required this.moduleName,
    required this.moduleCode,
    required this.totalFiles,
    required this.accentColor,
    required this.lastUpdated,
  });
}

class _RecentUpdateItem {
  final String title;
  final String moduleName;
  final String time;
  final IconData icon;
  final Color color;

  const _RecentUpdateItem({
    required this.title,
    required this.moduleName,
    required this.time,
    required this.icon,
    required this.color,
  });
}