import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/home/widgets/addOutpostButton.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PageWrapper(child: _HomeBody()),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _scrollController = ScrollController();
  final _scrolled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrolled.value =
          _scrollController.hasClients && _scrollController.offset > 4;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HomeHeader(),
        ValueListenableBuilder<bool>(
          valueListenable: _scrolled,
          builder: (context, scrolled, child) => AnimatedOpacity(
            opacity: scrolled ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: child,
          ),
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(0),
                  AppColors.primary.withAlpha(90),
                  AppColors.violet.withAlpha(90),
                  AppColors.violet.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _MyOutpostsList(scrollController: _scrollController),
        ),
      ],
    );
  }
}

class _HomeHeader extends GetView<HomeController> {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final outposts = controller.outpostsController;
    return Obx(() {
      final loading = outposts.isGettingMyOutposts.value;
      final count = outposts.myOutposts.value.length;
      final hasMore = !outposts.lastPageReachedForMyOutposts.value;
      final String subtitle;
      if (loading) {
        subtitle = count == 0 ? 'Loading your outposts…' : 'Refreshing…';
      } else if (count == 0) {
        subtitle = 'No outposts yet';
      } else {
        subtitle = 'My outposts · $count${hasMore ? '+' : ''}';
      }
      return AppPageHeader(
        title: "Home",
        subtitle: subtitle,
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 10),
        actions: [
          AppRefreshButton(
            loading: loading,
            onTap: controller.refreshOutposts,
          ),
          const SizedBox(width: 8),
          const AddOutpostButton(),
        ],
      );
    });
  }
}

class _MyOutpostsList extends GetView<OutpostsController> {
  const _MyOutpostsList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isEmpty = controller.myOutposts.value.isEmpty;
        final isGettingMyOutposts = controller.isGettingMyOutposts.value;
        final Widget child;
        if (isEmpty && isGettingMyOutposts) {
          child = ListView.builder(
            key: const ValueKey('skeleton'),
            padding: const EdgeInsets.only(top: 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => const OutpostCardSkeleton(),
          );
        } else if (isEmpty) {
          child = const _MyOutpostsEmpty(key: ValueKey('empty'));
        } else {
          child = OutpostsList(
            key: const ValueKey('list'),
            scrollController: scrollController,
            listPage: ListPage.my,
          );
        }
        return AnimatedSwitcher(
          duration: reduceMotion(context)
              ? Duration.zero
              : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          child: child,
        );
      },
    );
  }
}

class _MyOutpostsEmpty extends StatelessWidget {
  const _MyOutpostsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: AppEntrance(
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBreathing(
                  period: const Duration(milliseconds: 2600),
                  builder: (context, value) => Transform.translate(
                    offset: Offset(0, 4 - 8 * value),
                    child: SizedBox(
                      height: 150,
                      child: Assets.images.explore.image(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Hi ${myUser.name},",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.title,
                ),
                const SizedBox(height: 6),
                Text(
                  "You haven't joined any outposts yet. Find a live conversation or start your own.",
                  textAlign: TextAlign.center,
                  style: AppText.muted.copyWith(height: 1.45),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: "Explore Outposts",
                  icon: Icons.explore_rounded,
                  onPressed: () {
                    Navigate.to(
                      type: NavigationTypes.offAllNamed,
                      route: Routes.ALL_OUTPOSTS,
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: "Start an outpost",
                  icon: Icons.add_rounded,
                  onPressed: () {
                    Navigate.to(
                      type: NavigationTypes.toNamed,
                      route: Routes.CREATE_OUTPOST,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
