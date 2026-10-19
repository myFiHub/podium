import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/home/widgets/addOutpostButton.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/home_controller.dart';

const _homeListPadding = EdgeInsets.fromLTRB(0, 4, 0, 28);

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
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
        const _HomeSection(),
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
      final name =
          _firstName(Get.find<GlobalController>().myUserInfo.value?.name);
      final loading = outposts.isGettingMyOutposts.value;
      final items = outposts.myOutposts.value.values;
      final count = items.length;
      final hasMore = !outposts.lastPageReachedForMyOutposts.value;
      final online = outposts.mapOfOnlineUsersInOutposts.value;
      var live = 0;
      for (final outpost in items) {
        final listeners =
            online[outpost.uuid] ?? outpost.online_users_count ?? 0;
        if (listeners > 0) live++;
      }
      return AppPageHeader(
        title: _greeting(),
        subtitle: _homeSubtitle(
          name: name,
          loading: loading,
          count: count,
          hasMore: hasMore,
          live: live,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
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

class _HomeSection extends GetView<OutpostsController> {
  const _HomeSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.myOutposts.value.length;
      final loading = controller.isGettingMyOutposts.value;
      if (count == 0 && !loading) return const SizedBox(height: 8);
      return const AppSectionHeader(
        title: 'Your outposts',
        actionLabel: 'Explore',
        onAction: _openExplore,
        padding: EdgeInsets.fromLTRB(20, 6, 8, 2),
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
            padding: _homeListPadding,
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
            padding: _homeListPadding,
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
    final name =
        _firstName(Get.find<GlobalController>().myUserInfo.value?.name);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: AppEntrance(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBreathing(
                period: const Duration(milliseconds: 2600),
                builder: (context, value) => Transform.translate(
                  offset: Offset(0, 4 - 8 * value),
                  child: Container(
                    width: 168,
                    height: 168,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withAlpha(36),
                          AppColors.violet.withAlpha(14),
                          AppColors.violet.withAlpha(0),
                        ],
                      ),
                    ),
                    child: SizedBox(
                      height: 132,
                      child: Assets.images.explore.image(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.isEmpty ? 'No outposts yet' : 'Hi $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.title,
              ),
              const SizedBox(height: 8),
              Text(
                "You haven't joined a conversation yet. Explore what's live, or start one of your own.",
                textAlign: TextAlign.center,
                style: AppText.muted.copyWith(height: 1.45),
              ),
              const SizedBox(height: 22),
              const AppPrimaryButton(
                label: 'Explore outposts',
                icon: Icons.explore_rounded,
                onPressed: _openExplore,
              ),
              const SizedBox(height: 10),
              const AppSecondaryButton(
                label: 'Start an outpost',
                icon: Icons.add_rounded,
                onPressed: _openCreate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _firstName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _homeSubtitle({
  required String name,
  required bool loading,
  required int count,
  required bool hasMore,
  required int live,
}) {
  if (loading && count == 0) return 'Loading your outposts…';
  if (loading) return 'Refreshing…';
  if (count == 0) {
    return name.isEmpty
        ? 'Your conversations will show up here'
        : 'Welcome back, $name';
  }
  final noun = count == 1 && !hasMore ? 'outpost' : 'outposts';
  final rooms = '$count${hasMore ? '+' : ''} $noun';
  if (live == 0) return rooms;
  final liveLabel = live == 1 ? '1 live' : '$live live';
  return '$rooms · $liveLabel';
}

void _openExplore() {
  Navigate.to(
    type: NavigationTypes.offAllNamed,
    route: Routes.ALL_OUTPOSTS,
  );
}

void _openCreate() {
  Navigate.to(
    type: NavigationTypes.toNamed,
    route: Routes.CREATE_OUTPOST,
  );
}
