// lib/widgets/custom_textfield.dart
import 'package:flutter/material.dart';
import 'package:p1/theme.dart'; // Assuming your AppColors are defined here

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final bool isDense; // For more compact text fields

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? AppColors.dark : AppColors.dark.withOpacity(0.6),
        fontSize: isDense ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: AppColors.dark.withOpacity(0.7),
          fontSize: isDense ? 14 : 16,
        ),
        hintStyle: TextStyle(
          color: AppColors.gray.withOpacity(0.8),
          fontSize: isDense ? 13 : 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.secondary, size: isDense ? 18 : 22)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.gray.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.gray.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder( // Style for disabled state
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.gray.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: enabled ? AppColors.white.withOpacity(0.9) : AppColors.light.withOpacity(0.5),
        contentPadding: EdgeInsets.symmetric(
          vertical: isDense ? 12.0 : 16.0,
          horizontal: 16.0,
        ),
        isDense: isDense,
      ),
    );
  }
}
