import 'package:flutter/material.dart';

class InputTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const InputTextFieldWidget({
    Key? key,
    required this.controller,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Detected Text / Input',
        hintText: 'Type here or wait for Glove data...',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: onClear,
        ),
      ),
    );
  }
}