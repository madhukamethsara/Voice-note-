import 'package:flutter/material.dart';
import '../theme/theme.dart';

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
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          child: Text(label, style: syneStyle(size: 15, color: Colors.black)),
        ),
      ),
    );
  }
}

// button outline
class OutlineButton2 extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OutlineButton2({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text2,
          side: const BorderSide(color: AppColors.bg4, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: syneStyle(size: 13, color: AppColors.text2),
        ),
        child: Text(label,
            style: syneStyle(size: 13, color: AppColors.text2)),
      ),
    );
  }
}

// labels text
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final Function(String)? onChanged; 
  final String? errorText; 

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged, 
    this.errorText, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: dmStyle(size: 11, weight: FontWeight.w500, color: AppColors.text2)),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged, 
          style: dmStyle(size: 13),
          decoration: InputDecoration(
            hintText: hint,
            
            errorText: errorText, 
          ),
        ),
      ],
    );
  }
}

// Section labels
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: dmStyle(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.text3,
        ).copyWith(letterSpacing: 1.1),
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
                  decoration: const BoxDecoration(
                    color: AppColors.bg3,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left,
                      color: AppColors.text2, size: 20),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: syneStyle(size: 17, weight: FontWeight.w700)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}