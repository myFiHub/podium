import 'package:flutter/material.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:shimmer/shimmer.dart';

class AddOutpostButton extends StatefulWidget {
  @override
  _AddOutpostButtonState createState() => _AddOutpostButtonState();
}

class _AddOutpostButtonState extends State<AddOutpostButton>
    with SingleTickerProviderStateMixin {
  bool _showText = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // 2 seconds duration
      vsync: this,
    );

    // Start the animation after 1 second
    Future.delayed(const Duration(seconds: 3), () {
      _controller.forward().then((_) {
        setState(() {
          _showText = false; // Hide the text completely at the end
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigate.to(
          type: NavigationTypes.toNamed,
          route: Routes.CREATE_GROUP,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [
              ColorName.systemTrayBackground,
              ColorName.pageBgGradientStart
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(_controller.value * 100, 0),
                        child: _showText
                            ? Row(
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.white,
                                    highlightColor: Colors.blueAccent,
                                    child: const Text(
                                      "Start new outpost",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.white,
              highlightColor: Colors.blueAccent,
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}