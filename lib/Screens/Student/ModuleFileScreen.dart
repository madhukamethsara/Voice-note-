import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Models/Module.dart';
import '../../Models/NoteFileItem.dart';
import '../../Services/NoteFile.dart';
import '../../Theme/theme.dart';
import 'RecordingDetailScreen.dart';

class ModuleFilesScreen extends StatelessWidget {
  final Module module;

  const ModuleFilesScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final NoteFileService _noteFileService = NoteFileService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text),
        ),
        title: Text(
          module.moduleName.isNotEmpty
              ? module.moduleName
              : module.moduleCode,
          style: GoogleFonts.syne(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<List<NoteFileItem>>(
        stream: _noteFileService.getFilesByModule(module.moduleCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading files",
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return Center(
              child: Text(
                "No files yet",
                style: TextStyle(color: AppColors.text2),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];

              return InkWell(
                onTap: () {
                  if (file.type == "recording") {
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.bg4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded,
                          color: AppColors.teal),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.title,
                              style: GoogleFonts.dmSans(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              file.summary ??
                                  file.transcript ??
                                  "No preview",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: AppColors.text2,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.chevron_right,
                          color: AppColors.text3),
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