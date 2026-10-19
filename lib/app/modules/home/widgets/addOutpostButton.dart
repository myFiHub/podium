import 'package:flutter/material.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class AddOutpostButton extends StatefulWidget {
  const AddOutpostButton({super.key});

  @override
  State<AddOutpostButton> createState() => _AddOutpostButtonState();
}

class _AddOutpostButtonState extends State<AddOutpostButton> {
  bool _showText = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showText = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Start new outpost',
      child: Material(
        color: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigate.to(
              type: NavigationTypes.toNamed,
              route: Routes.CREATE_OUTPOST,
            );
          },
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    if (_showText) ...[
                      const SizedBox(width: 6),
                      const Text(
                        "Start new outpost",
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
