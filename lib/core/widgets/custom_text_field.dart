import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<String>? autofillHints;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.focusNode,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: widget.autocorrect,
      enableSuggestions: !widget.isPassword,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textoOscuro,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: TextStyle(color: AppColors.textoGris.withOpacity(0.6)),
        prefixIcon:
            Icon(widget.prefixIcon, color: AppColors.primario, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                // Área táctil mínima para móvil
                padding: const EdgeInsets.all(12),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textoGris,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        labelStyle:
            const TextStyle(color: AppColors.textoGris, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primario, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
