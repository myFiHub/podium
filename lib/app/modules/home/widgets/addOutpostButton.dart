import 'package:flutter/material.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class AddOutpostButton extends StatelessWidget {
  const AddOutpostButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Start an outpost',
      child: AppPressScale(
        scale: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withAlpha(70),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigate.to(
                  type: NavigationTypes.toNamed,
                  route: Routes.CREATE_OUTPOST,
                );
              },
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
