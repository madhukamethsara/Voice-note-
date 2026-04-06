import 'package:flutter/material.dart';
import '../../Models/Module.dart';
import '../../Services/File/ModuleService.dart';
import '../../Services/File/NoteFile.dart';
import '../../Theme/theme_helper.dart';
import '../Common/ModuleChatScreen.dart';
import 'ModuleFileScreen.dart';

class Notes extends StatefulWidget {
  final String senderName;
  final String senderRole;

  const Notes({
    super.key,
    required this.senderName,
    required this.senderRole,
  });

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final ModuleService _moduleService = ModuleService();
  final NoteFileService _noteFileService = NoteFileService();

  String _formatUpdatedText(DateTime? dateTime) {
    if (dateTime == null) return 'No updates';

    final accentColors = [
      colors.teal,
      colors.purple,
      colors.blue,
      colors.amber,
      colors.coral,
    ];

    if (difference.inMinutes < 1) return 'Updated just now';
    if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return 'Updated ${difference.inHours} hr ago';
    }
    if (difference.inDays == 1) return 'Updated yesterday';
    if (difference.inDays < 7) return 'Updated ${difference.inDays} days ago';
    return 'Updated ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _openModuleFiles(BuildContext context, Module module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleFilesScreen(module: module),
      ),
    );
  }

  void _openModuleChat(BuildContext context, Module module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleChatScreen(
          moduleCode: module.moduleCode,
          moduleName: module.moduleName.isNotEmpty
              ? module.moduleName
              : module.moduleCode,
          senderName: widget.senderName,
          senderRole: widget.senderRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final accentColors = [
      colors.teal,
      colors.purple,
      colors.blue,
      colors.amber,
      colors.coral,
    ];

    Color getAccentColor(int index) {
      return accentColors[index % accentColors.length];
    }

    return Scaffold(
      backgroundColor: colors.bg,
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
                      context,
                      'Your Modules',
                      'Open files or chat by module',
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
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: colors.teal,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildErrorState(
                        context,
                        snapshot.error.toString(),
                      ),
                    ),
                  );
                }

                final modules = snapshot.data ?? [];

                if (modules.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return _buildModuleCard(
                        context,
                        module,
                        index,
                        getAccentColor,
                      );
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

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.text2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    Module module,
    int index,
    Color Function(int) getAccentColor,
  ) {
    final colors = context.colors;
    final accentColor = getAccentColor(index);

    final displayName = module.moduleName.isNotEmpty
        ? module.moduleName
        : module.moduleCode;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openModuleFiles(context, module),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bg2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.bg4),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bg3,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.folder_rounded, color: accentColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.moduleCode,
                    style: TextStyle(
                      color: colors.text2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StreamBuilder<ModuleFileStats>(
                    stream: _noteFileService.getModuleFileStats(
                      module.moduleCode,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Checking files...',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          '0 files • No updates',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      final stats = snapshot.data ??
                          ModuleFileStats(
                            fileCount: 0,
                            latestUpdatedAt: null,
                          );

                      return Text(
                        '${stats.fileCount} file${stats.fileCount == 1 ? '' : 's'} • ${_formatUpdatedText(stats.latestUpdatedAt)}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Open module chat',
                  onPressed: () => _openModuleChat(context, module),
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.teal,
                    size: 22,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.text3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_off_rounded, size: 42, color: colors.text3),
          const SizedBox(height: 10),
          Text(
            'No modules yet',
            style: TextStyle(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your module files will appear here.',
            style: TextStyle(
              color: colors.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.bg4),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: colors.coral,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load modules',
            style: TextStyle(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: colors.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
