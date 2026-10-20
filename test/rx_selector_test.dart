import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:podium/widgets/rx_selector.dart';

void main() {
  testWidgets('rebuilds only when the selected value changes', (tester) async {
    final online = Rx<Map<String, int>>({'a': 1});
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RxSelector<int>(
          sources: [online],
          select: () => online.value['a'] ?? 0,
          builder: (context, count, _) {
            builds++;
            return Text('$count');
          },
        ),
      ),
    );
    expect(builds, 1);

    online.value = {'a': 1, 'b': 5};
    await tester.pump();
    expect(builds, 1);

    online.value = {'a': 2};
    await tester.pump();
    expect(builds, 2);
    expect(find.text('2'), findsOneWidget);
  });
}
