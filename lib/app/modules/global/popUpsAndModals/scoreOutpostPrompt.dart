import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/widgets/ui/app_ui.dart';

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
    AppDialog(
      icon: Icons.star_rounded,
      iconColor: AppColors.accent,
      title: 'Rate Call Quality',
      message: 'How was your outpost call experience?',
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: emojis.map((emoji) {
          return Material(
            color: AppColors.fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.pop(Get.context!, emojiScoreMap[emoji]);
              },
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () {
            Navigator.pop(Get.context!, null);
          },
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
