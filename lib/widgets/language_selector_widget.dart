import 'package:flutter/material.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final Map<String, String> languageCodes;
  final List<String> selectedLanguages;
  final Function(String lang, bool selected) onLanguageSelected;

  const LanguageSelectorWidget({
    Key? key,
    required this.languageCodes,
    required this.selectedLanguages,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Translate to:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: languageCodes.keys.map((lang) {
            final isSelected = selectedLanguages.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSelected,
              selectedColor: const Color(0xFF660643).withOpacity(0.2),
              checkmarkColor: const Color(0xFF660643),
              onSelected: (bool selected) {
                onLanguageSelected(lang, selected);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}