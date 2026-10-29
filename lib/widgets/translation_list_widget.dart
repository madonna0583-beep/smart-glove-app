import 'package:flutter/material.dart';

class TranslationListWidget extends StatelessWidget {
  final List<MapEntry<String, String>> entries;
  final Map<String, String> languageCodes;
  final Function(String text, String langCode) onSpeak;
  final Function(String text, String lang) onSave;

  const TranslationListWidget({
    Key? key,
    required this.entries,
    required this.languageCodes,
    required this.onSpeak,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF660643),
                ),
              ),
              subtitle: Text(
                entry.value,
                style: const TextStyle(fontSize: 18),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      color: Color(0xFF660643),
                    ),
                    onPressed: () {
                      final langCode = languageCodes[entry.key] ?? 'en';
                      onSpeak(entry.value, langCode);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.bookmark_add,
                      color: Color(0xFF660643),
                    ),
                    onPressed: () => onSave(entry.value, entry.key),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }
}