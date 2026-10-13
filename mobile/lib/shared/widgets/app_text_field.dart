import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(PointerDownEvent)? onTapOutside;
  final FocusNode? focusNode;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onTapOutside,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTypography.labelMedium.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onTapOutside: onTapOutside,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTypography.bodyMedium.copyWith(color: AppColors.inkLight),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusMd,
              borderSide: BorderSide(color: AppColors.divider, width: 1.2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusMd,
              borderSide: BorderSide(color: AppColors.terracotta, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusMd,
              borderSide: BorderSide(color: AppColors.coral, width: 1.2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.radiusMd,
              borderSide: BorderSide(color: AppColors.coral, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
