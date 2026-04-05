import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Models/Module.dart';
import '../../Models/NoteFileItem.dart';
import 'package:voicenote/Services/File/NoteFile.dart';
import '../../Theme/theme_helper.dart';
import 'RecordingDetailScreen.dart';

class ModuleFilesScreen extends StatelessWidget {
  final Module module;

  const ModuleFilesScreen({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    final NoteFileService noteFileService = NoteFileService();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.chevron_left_rounded,
            color: colors.text,
          ),
        ),
        title: Text(
          module.moduleName.isNotEmpty
              ? module.moduleName
              : module.moduleCode,
          style: GoogleFonts.syne(
            color: colors.text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<List<NoteFileItem>>(
        stream: noteFileService.getFilesByModule(module.moduleCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colors.teal,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Failed to load module files",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 54,
                      color: colors.text3,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No files yet for this module",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                        color: colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "When recordings, summaries, or transcripts are saved to this module, they will appear here.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: colors.text2,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final file = files[index];

              final previewText = (file.summary != null &&
                      file.summary!.trim().isNotEmpty)
                  ? file.summary!
                  : (file.transcript != null && file.transcript!.trim().isNotEmpty)
                      ? file.transcript!
                      : "No preview available";

              final isRecording = file.type.toLowerCase() == "recording";

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (isRecording) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordingDetailScreen(
                          recording: file.toRecordingItem(),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bg2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.bg4),
                    boxShadow: [
                      BoxShadow(
                        color: colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.bg3,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isRecording
                              ? Icons.mic_rounded
                              : Icons.insert_drive_file_rounded,
                          color: colors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.title.isNotEmpty ? file.title : "Untitled File",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              previewText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: colors.text2,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bg3,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                file.type,
                                style: GoogleFonts.dmSans(
                                  color: colors.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.text3,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}