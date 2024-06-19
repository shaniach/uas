import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final bool obscureText;
  final bool suffixIcon;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  const CustomInputField({
    Key? key,
    required this.labelText,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon = false,
    this.validator,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: suffixIcon ? Icon(Icons.visibility_off) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
