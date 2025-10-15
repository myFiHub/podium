import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/widgets/button/button.dart';

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

    return GestureDetector(
      onTap: isCreator ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey[600] : Colors.blue[600],
          borderRadius: BorderRadius.circular(12),
          border:
              isCreator ? Border.all(color: Colors.blue[400]!, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(
                Icons.people,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 4),
            Text(
              isLoading
                  ? 'Loading cohosts...'
                  : '${cohostUserUuids.length} cohost${cohostUserUuids.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isCreator && !isLoading) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                color: Colors.white,
                size: 14,
              ),
            ],
          ],
        ),
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
  final TextEditingController _searchController = TextEditingController();
  final RxList<UserModel> _searchedUsers = <UserModel>[].obs;
  final RxList<UserModel> _selectedCohosts = <UserModel>[].obs;
  final RxBool _isSearching = false.obs;
  final RxBool _isLoadingInitialCohosts = false.obs;

  @override
  void initState() {
    super.initState();
    // Initialize with current cohosts - we need to fetch user data for the UUIDs
    _loadInitialCohosts();
  }

  void _loadInitialCohosts() async {
    if (widget.initialCohostUuids.isNotEmpty) {
      _isLoadingInitialCohosts.value = true;
      try {
        final users =
            await HttpApis.podium.getUsersByIds(widget.initialCohostUuids);
        _selectedCohosts.value = users;
      } catch (e) {
        // Handle error silently
      } finally {
        _isLoadingInitialCohosts.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.9,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isCreator ? 'Manage Cohosts' : 'Cohosts',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Get.close(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar - only for creators
          if (widget.isCreator) ...[
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(() {
                  if (_isSearching.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  } else if (_searchController.text.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _searchedUsers.clear();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 20),
          ],
          // Selected cohosts section - only for creators
          if (widget.isCreator) ...[
            Obx(() {
              if (_isLoadingInitialCohosts.value) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Cohosts (${widget.initialCohostUuids.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.initialCohostUuids.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: 'Loading...',
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[700],
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
              if (_selectedCohosts.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Cohosts (${_selectedCohosts.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedCohosts.length,
                      itemBuilder: (context, index) {
                        final cohost = _selectedCohosts[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: cohost.name ?? 'Unknown User',
                            child: Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.blue, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: cohost.image != null &&
                                            cohost.image!.isNotEmpty
                                        ? NetworkImage(cohost.image!)
                                        : null,
                                    child: cohost.image == null ||
                                            cohost.image!.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
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
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
          // Search results - only for creators
          if (widget.isCreator) ...[
            Expanded(
              child: Obx(() {
                if (_searchedUsers.isEmpty && _searchController.text.isEmpty) {
                  return const Center(
                    child: Text(
                      'Search for users to add as cohosts',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                if (_searchedUsers.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _searchedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _searchedUsers[index];
                    return Obx(() {
                      final isSelected =
                          _selectedCohosts.any((c) => c.uuid == user.uuid);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              user.image != null && user.image!.isNotEmpty
                                  ? NetworkImage(user.image!)
                                  : null,
                          child: user.image == null || user.image!.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          user.name ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          user.email ?? '',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
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
                        onTap: () {
                          if (isSelected) {
                            _selectedCohosts
                                .removeWhere((c) => c.uuid == user.uuid);
                          } else {
                            _selectedCohosts.add(user);
                          }
                        },
                      );
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            // Action buttons - only for creators
            Row(
              children: [
                Expanded(
                  child: Button(
                    type: ButtonType.outline,
                    onPressed: () => Get.close(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Button(
                    type: ButtonType.gradient,
                    onPressed: () {
                      final cohostUuids =
                          _selectedCohosts.map((u) => u.uuid).toList();
                      widget.onConfirm?.call(cohostUuids);
                      Get.close();
                    },
                    child: const Text('Confirm'),
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
                  return Column(
                    children: [
                      Text(
                        'Cohosts (${widget.initialCohostUuids.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.initialCohostUuids.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Tooltip(
                              message: 'Loading...',
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[700],
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Container(
                                  height: 16,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                subtitle: Container(
                                  height: 12,
                                  width: 80,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                if (_selectedCohosts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No cohosts assigned',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _selectedCohosts.length,
                  itemBuilder: (context, index) {
                    final cohost = _selectedCohosts[index];
                    return Tooltip(
                      message: cohost.name ?? 'Unknown User',
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              cohost.image != null && cohost.image!.isNotEmpty
                                  ? NetworkImage(cohost.image!)
                                  : null,
                          child: cohost.image == null || cohost.image!.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          cohost.name ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          cohost.email ?? '',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            // Close button for non-creators
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.close(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      _searchedUsers.clear();
      return;
    }

    _isSearching.value = true;
    try {
      final users = await HttpApis.podium.searchUserByName(name: query);
      _searchedUsers.value = users.values.toList();
    } catch (e) {
      _searchedUsers.clear();
    } finally {
      _isSearching.value = false;
    }
  }
}
