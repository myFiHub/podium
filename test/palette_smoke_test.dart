import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/myProfile/widgets/color_theme_sheet.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/theme.dart';
import 'package:podium/widgets/ui/app_ui.dart';

void main() {
  for (final palette in AppPalette.all) {
    testWidgets('renders with ${palette.name}', (tester) async {
      AppPalette.debugSet(palette);
      await tester.pumpWidget(MaterialApp(
        theme: buildThemeData(),
        home: Scaffold(
          body: AuroraBackground(
            child: Column(children: [
              const ColorThemeSheet(),
              AppCard(child: Text('card', style: AppText.title)),
            ]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(palette.name), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
