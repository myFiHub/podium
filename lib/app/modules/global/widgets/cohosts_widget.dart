import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/truncate.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class CohostsWidget extends StatelessWidget {
  final List<String> cohostUserUuids;
  final bool isCreator;
  final VoidCallback? onTap;
  final String? outpostUuid;
  final bool isLoading;

  const CohostsWidget({
    super.key,
    required this.cohostUserUuids,
    required this.isCreator,
    this.onTap,
    this.outpostUuid,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cohostUserUuids.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    final count = cohostUserUuids.length;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Loading cohosts...'
                      : '$count cohost${count > 1 ? 's' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  isCreator ? 'Tap to manage cohosts' : 'Tap to see who',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          if (!isLoading)
            Icon(
              isCreator ? Icons.edit_rounded : Icons.chevron_right_rounded,
              color: ColorName.greyText,
              size: isCreator ? 18 : 24,
            ),
        ],
      ),
    );
  }
}

class CohostsSearchBottomSheet extends StatefulWidget {
  final List<String> initialCohostUuids;
  final String? outpostUuid;
  final Function(List<String>)? onConfirm;
  final bool isCreator;

  const CohostsSearchBottomSheet({
    super.key,
    required this.initialCohostUuids,
    this.outpostUuid,
    this.onConfirm,
    this.isCreator = true,
  });

  @override
  State<CohostsSearchBottomSheet> createState() =>
      _CohostsSearchBottomSheetState();
}

class _CohostsSearchBottomSheetState extends State<CohostsSearchBottomSheet> {
  final _userRepository = Get.find<UserRepository>();
  final TextEditingController _searchController = TextEditingController();
  final RxList<UserModel> _searchedUsers = <UserModel>[].obs;
  final RxList<UserModel> _selectedCohosts = <UserModel>[].obs;
  final RxBool _isSearching = false.obs;
  final RxBool _isLoadingInitialCohosts = false.obs;

  static const _searchDelay = Duration(milliseconds: 350);
  Timer? _searchDebounce;

  /// Responses can arrive out of order; only the latest search may apply.
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialCohosts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialCohosts() async {
    if (widget.initialCohostUuids.isEmpty) return;
    _isLoadingInitialCohosts.value = true;
    try {
      final users =
          await _userRepository.getUsersByIds(widget.initialCohostUuids);
      _selectedCohosts.value = users;
    } catch (e) {
      l.e('Failed to load cohosts: $e');
    } finally {
      _isLoadingInitialCohosts.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSheet.maxHeight(context, 0.9),
      child: AppSheet(
        title: widget.isCreator ? 'Manage Cohosts' : 'Cohosts',
        trailing: AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          size: 36,
          onTap: () => Get.close(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar - only for creators
            if (widget.isCreator) ...[
              TextField(
                controller: _searchController,
                style: TextStyle(color: ColorName.white),
                decoration: InputDecoration(
                  hintText: 'Search users by name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Obx(() {
                    if (_isSearching.value) {
                      return const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    } else if (_searchController.text.isNotEmpty) {
                      return IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),
                onChanged: _searchUsers,
              ),
              const SizedBox(height: 16),
            ],
            // Selected cohosts section - only for creators
            if (widget.isCreator) ...[
              Obx(() {
                if (_isLoadingInitialCohosts.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        title: 'Selected cohosts',
                        count: widget.initialCohostUuids.length,
                      ),
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.initialCohostUuids.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Tooltip(
                                message: 'Loading...',
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.fill,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ColorName.greyText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                if (_selectedCohosts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      title: 'Selected cohosts',
                      count: _selectedCohosts.length,
                    ),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedCohosts.length,
                        itemBuilder: (context, index) {
                          final cohost = _selectedCohosts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Tooltip(
                              message: cohost.name ?? 'Unknown User',
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                        child: _Avatar(
                                          image: cohost.image,
                                          radius: 24,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _selectedCohosts.removeAt(index),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: AppColors.danger,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: ColorName.cardBackground,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: ColorName.white,
                                            size: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
            // Search results - only for creators
            if (widget.isCreator) ...[
              Expanded(
                child: Obx(() {
                  if (_searchedUsers.isEmpty &&
                      _searchController.text.isEmpty) {
                    return const SingleChildScrollView(
                      child: AppEmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'Find cohosts',
                        message: 'Search for users to add as cohosts',
                        compact: true,
                      ),
                    );
                  }
                  if (_searchedUsers.isEmpty &&
                      _searchController.text.isNotEmpty) {
                    return const SingleChildScrollView(
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No users found',
                        compact: true,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: _searchedUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _searchedUsers[index];
                      return Obx(() {
                        final isSelected =
                            _selectedCohosts.any((c) => c.uuid == user.uuid);
                        return _UserRow(
                          image: user.image,
                          name: user.name ?? 'Unknown',
                          subtitle: truncate(user.aptos_address ?? ''),
                          selected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              _selectedCohosts
                                  .removeWhere((c) => c.uuid == user.uuid);
                            } else {
                              _selectedCohosts.add(user);
                            }
                          },
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              if (value == true) {
                                if (!isSelected) {
                                  _selectedCohosts.add(user);
                                }
                              } else {
                                _selectedCohosts
                                    .removeWhere((c) => c.uuid == user.uuid);
                              }
                            },
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Action buttons - only for creators
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Get.close(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Confirm',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        final cohostUuids =
                            _selectedCohosts.map((u) => u.uuid).toList();
                        widget.onConfirm?.call(cohostUuids);
                        Get.close();
                      },
                    ),
                  ),
                ],
              ),
            ],
            // View-only section for non-creators
            if (!widget.isCreator) ...[
              Expanded(
                child: Obx(() {
                  if (_isLoadingInitialCohosts.value) {
                    return ListView.separated(
                      itemCount: widget.initialCohostUuids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return const Tooltip(
                          message: 'Loading...',
                          child: _UserRowSkeleton(),
                        );
                      },
                    );
                  }
                  if (_selectedCohosts.isEmpty) {
                    return const SingleChildScrollView(
                      child: AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No cohosts assigned',
                        compact: true,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: _selectedCohosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cohost = _selectedCohosts[index];
                      return Tooltip(
                        message: cohost.name ?? 'Unknown User',
                        child: _UserRow(
                          image: cohost.image,
                          name: cohost.name ?? 'Unknown',
                          subtitle:
                              truncate(cohost.aptos_address ?? '', length: 14),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Close button for non-creators
              AppSecondaryButton(
                label: 'Close',
                onPressed: () => Get.close(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _searchUsers(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      _searchSeq++;
      _isSearching.value = false;
      _searchedUsers.clear();
      return;
    }
    _isSearching.value = true;
    _searchDebounce = Timer(_searchDelay, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    try {
      final users = await _userRepository.searchUserByName(name: query);
      if (seq != _searchSeq || !mounted) return;
      _searchedUsers.value = users.values.toList();
    } catch (e) {
      if (seq != _searchSeq || !mounted) return;
      _searchedUsers.clear();
    } finally {
      if (seq == _searchSeq && mounted) _isSearching.value = false;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;
  const _SectionLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppText.label),
          const SizedBox(width: 6),
          Text('$count', style: AppText.caption),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? image;
  final double radius;
  const _Avatar({required this.image, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.isNotEmpty;
    final placeholderName = hasImage ? placeholderAvatarName(image!) : null;
    if (placeholderName != null) {
      return SizedBox.square(
        dimension: radius * 2,
        child: InitialsAvatar(
          name: placeholderName,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: ColorName.cardBorder,
      foregroundColor: ColorName.greyText,
      backgroundImage:
          hasImage ? CachedNetworkImageProvider(image!, maxWidth: 160) : null,
      child: hasImage ? null : const Icon(Icons.person_rounded),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String? image;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _UserRow({
    required this.image,
    required this.name,
    required this.subtitle,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.md,
      padding: EdgeInsets.fromLTRB(12, 10, trailing == null ? 12 : 4, 10),
      color: selected ? AppColors.primary.withAlpha(26) : AppColors.fill,
      borderColor: selected ? AppColors.primary.withAlpha(110) : null,
      onTap: onTap,
      child: Row(
        children: [
          _Avatar(image: image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorName.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _UserRowSkeleton extends StatelessWidget {
  const _UserRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.fill,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorName.white.withAlpha(14),
            ),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: ColorName.greyText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: ColorName.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 80,
                decoration: BoxDecoration(
                  color: ColorName.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
