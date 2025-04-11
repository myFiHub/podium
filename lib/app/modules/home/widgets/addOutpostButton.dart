import 'package:flutter/material.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/utils/styles.dart';
import 'package:shimmer/shimmer.dart';

class AddOutpostButton extends StatefulWidget {
  const AddOutpostButton({super.key});

  @override
  State<AddOutpostButton> createState() => _AddOutpostButtonState();
}

class _AddOutpostButtonState extends State<AddOutpostButton>
    with SingleTickerProviderStateMixin {
  bool _showText = true;
  bool _showShimmer = true;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Start shrinking animation after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _controller.forward().then((_) {
        if (!mounted) return;
        setState(() {
          _showText = false;
        });
      });
    });

    // Stop shimmer effect after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _showShimmer = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon() {
    return _showShimmer
        ? Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: Colors.blueAccent,
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          )
        : const Icon(Icons.add, color: Colors.white, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigate.to(
          type: NavigationTypes.toNamed,
          route: Routes.CREATE_OUTPOST,
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 32, // Fixed height to prevent size changes
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [
                  ColorName.systemTrayBackground,
                  ColorName.pageBgGradientStart
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _opacityAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _widthAnimation.value * 120,
                    child: _showText
                        ? Shimmer.fromColors(
                            baseColor: Colors.white,
                            highlightColor: Colors.blueAccent,
                            child: const Text(
                              "Start new outpost",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )
                        : emptySpace,
                  ),
                ),
                if (_showText) const SizedBox(width: 8),
                _buildIcon(),
              ],
            ),
          );
        },
      ),
    );
  }
}
