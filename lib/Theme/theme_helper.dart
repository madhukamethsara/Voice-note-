import 'package:flutter/material.dart';
import 'theme.dart';

extension ThemeHelper on BuildContext {
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light;
}
