import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/modules/outpostDetail/widgets/usersList.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/search_controller.dart';

class SearchTextField extends GetView<SearchPageController> {
  const SearchTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textFieldController = controller.textFieldController;
    return TextField(
      controller: textFieldController,
      textInputAction: TextInputAction.search,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: "Search Outposts, Users or Tags",
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
        ),
        suffixIcon: Obx(() {
          final searchValue = controller.searchValue.value;
          final isSearching = controller.isSearching.value;
          if (isSearching) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          }
          if (searchValue.isEmpty) {
            return const SizedBox.shrink();
          }
          return IconButton(
            tooltip: 'Clear',
            onPressed: () {
              controller.setSeachValue("");
            },
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          );
        }),
      ),
      onChanged: (value) {
        controller.setSeachValue(value);
      },
    );
  }
}

class SearchView extends GetView<SearchPageController> {
  const SearchView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(
                title: "Search",
                padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SearchTextField(),
              ),
              const SizedBox(height: 14),
              const _SearchTabs(),
              Expanded(
                child: TabBarView(
                  children: [
                    Obx(() {
                      final searchedGroups = controller.searchedOutposts.value;
                      List<OutpostModel> outpostsList = [];
                      outpostsList = searchedGroups.values.toList();
                      if (outpostsList.isEmpty) {
                        return const _SearchEmpty(
                          icon: Icons.podcasts_rounded,
                          noResultsTitle: 'No outposts found',
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutpostsList(
                          outpostsList: outpostsList,
                          listPage: ListPage.search,
                        ),
                      );
                    }),
                    Obx(() {
                      final usersMap = controller.searchedUsers.value;
                      List<UserModel> usersList = [];
                      usersList = usersMap.values.toList();
                      if (usersList.isEmpty) {
                        return const _SearchEmpty(
                          icon: Icons.person_search_rounded,
                          noResultsTitle: 'No users found',
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: UserList(
                          userModelsList: usersList,
                          onRequestUpdate: (user) {
                            controller.updateUserFollow(user);
                          },
                        ),
                      );
                    }),
                    Obx(() {
                      final tagsMap = controller.searchedTags.value;
                      final loadingName = controller.loadingTag_name.value;
                      List<TagModel> tagsList = [];
                      tagsList = tagsMap.values.toList();

                      if (tagsList.isEmpty) {
                        return const _SearchEmpty(
                          icon: Icons.tag_rounded,
                          noResultsTitle: 'No tags found',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: tagsList.length,
                        itemBuilder: (context, index) {
                          final tag = tagsList[index];
                          return AppEntrance(
                            key: Key(tag.name),
                            index: index,
                            child: _TagTile(
                              tag: tag,
                              loading: loadingName == tag.name,
                              onTap: () {
                                controller.tagClicked(tag);
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchTabs extends GetView<SearchPageController> {
  const _SearchTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        splashBorderRadius: BorderRadius.circular(AppRadius.sm - 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: [
          Obx(() {
            final numberOfGroupsFound =
                controller.searchedOutposts.value.length;
            return _TabLabel(label: "Outposts", count: numberOfGroupsFound);
          }),
          Obx(() {
            final numberOfUsersFound = controller.searchedUsers.value.length;
            return _TabLabel(label: "Users", count: numberOfUsersFound);
          }),
          Obx(() {
            final numberOfTagsFound = controller.searchedTags.value.length;
            return _TabLabel(label: "Tags", count: numberOfTagsFound);
          }),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: AppRollingText(
        count == 0 ? label : '$label ($count)',
        alignment: Alignment.center,
      ),
    );
  }
}

class _SearchEmpty extends GetView<SearchPageController> {
  const _SearchEmpty({
    required this.icon,
    required this.noResultsTitle,
  });

  final IconData icon;
  final String noResultsTitle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasQuery = controller.searchValue.value.isNotEmpty;
      final isSearching = controller.isSearching.value;
      final Widget state;
      if (!hasQuery) {
        state = AppEmptyState(
          key: const ValueKey('idle'),
          icon: icon,
          title: 'Find your next conversation',
          message: 'Search outposts, people and tags across Podium.',
          compact: true,
        );
      } else if (isSearching) {
        state = const AppEmptyState(
          key: ValueKey('searching'),
          icon: Icons.manage_search_rounded,
          title: 'Searching…',
          compact: true,
        );
      } else {
        state = AppEmptyState(
          key: const ValueKey('none'),
          icon: icon,
          title: noResultsTitle,
          message: 'Try a different keyword.',
          compact: true,
        );
      }
      return ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 32),
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: state,
          ),
        ],
      );
    });
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.tag,
    required this.loading,
    required this.onTap,
  });

  final TagModel tag;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: AppRadius.md,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tag_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(fontSize: 14),
            ),
          ),
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
