import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';

/// Shows a dialog to score the outpost call quality and returns the selected score (1-5)
/// Returns null if user cancels or closes the dialog
Future<int?> showScoreOutpostPrompt() async {
  // Emoji to score mapping (1-5 scale)
  const emojiScoreMap = {
    '😢': 1, // Very Poor
    '😕': 2, // Poor
    '😐': 3, // Average
    '😊': 4, // Good
    '😍': 5, // Excellent
  };

  final emojis = emojiScoreMap.keys.toList();

  final int? selectedScore = await Get.dialog<int>(
    AlertDialog(
      backgroundColor: ColorName.pageBackground,
      title: const Text(
        'Rate Call Quality',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How was your outpost call experience?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Emoji Selection
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(Get.context!, emojiScoreMap[emoji]);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(Get.context!, null);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return selectedScore;
}

/// Helper function to get score description based on the score value
String getScoreDescription(int score) {
  switch (score) {
    case 1:
      return 'Very Poor';
    case 2:
      return 'Poor';
    case 3:
      return 'Average';
    case 4:
      return 'Good';
    case 5:
      return 'Excellent';
    default:
      return 'Unknown';
  }
}
