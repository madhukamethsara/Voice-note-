import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Theme/theme_helper.dart';

// normal button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.teal,
            foregroundColor: colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.black,
            ),
          ),
        ),
      ),
    );
  }

// outline button
class OutlineButton2 extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OutlineButton2({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text2,
          side: BorderSide(color: colors.bg4, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.text2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.text2,
          ),
        ),
      ),
    );
  }
}

// labeled text field
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.text2,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: colors.text3,
            ),
            filled: true,
            fillColor: colors.bg2,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.bg4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.teal),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

// section labels
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.text3,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// top bar
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            if (showBack)
              GestureDetector(
                onTap: onBack ?? () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.bg3,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: colors.text2,
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
