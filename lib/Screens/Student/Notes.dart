import 'package:flutter/material.dart';
import '../../Models/Module.dart';
import '../../Services/ModuleService.dart';
import '../../Theme/theme.dart';
import 'ModuleFileScreen.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final ModuleService _moduleService = ModuleService();

  final List<Color> _accentColors = const [
    AppColors.teal,
    AppColors.purple,
    AppColors.blue,
    AppColors.amber,
    AppColors.coral,
  ];

  String _formatUpdatedText(DateTime? dateTime) {
    if (dateTime == null) return 'Updated recently';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Updated just now';
    } else if (difference.inHours < 1) {
      return 'Updated ${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return 'Updated today';
    } else if (difference.inDays == 1) {
      return 'Updated yesterday';
    } else if (difference.inDays < 7) {
      return 'Updated ${difference.inDays} days ago';
    } else {
      return 'Updated this month';
    }
  }

  Color _getAccentColor(int index) {
    return _accentColors[index % _accentColors.length];
  }

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
            StreamBuilder<List<Module>>(
              stream: _moduleService.getUserModulesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildErrorState(snapshot.error.toString()),
                    ),
                  );
                }

                final modules = snapshot.data ?? [];

                if (modules.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return _buildModuleCard(module, index);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                  ),
                );
              },
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

  Widget _buildModuleCard(Module module, int index) {
    final accentColor = _getAccentColor(index);
    final displayName = module.moduleName.isNotEmpty
        ? module.moduleName
        : module.moduleCode;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModuleFilesScreen(module: module),
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
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
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
                    '${module.totalFiles} files • ${_formatUpdatedText(module.updatedAt)}',
                    style: TextStyle(
                      color: accentColor,
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

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.bg4),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.coral,
          ),
          const SizedBox(height: 10),
          const Text(
            'Failed to load modules',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}