import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/popUpsAndModals/outpostBanNotice.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/outpost_moderation.dart';
import 'package:podium/app/modules/global/widgets/img.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Lists who the hosts removed or blocked from [outpostId] and lets them
/// back in. Hosts only.
Future<void> openOutpostBansSheet({
  required String outpostId,
  required String creatorUuid,
}) {
  return showAppSheet<void>(
    OutpostBansSheet(outpostId: outpostId, creatorUuid: creatorUuid),
  );
}

class OutpostBansSheet extends StatefulWidget {
  final String outpostId;
  final String creatorUuid;
  const OutpostBansSheet({
    super.key,
    required this.outpostId,
    required this.creatorUuid,
  });

  @override
  State<OutpostBansSheet> createState() => _OutpostBansSheetState();
}

class _OutpostBansSheetState extends State<OutpostBansSheet> {
  static const _pageSize = 50;

  final _items = <OutpostBanItem>[];
  final _lifting = <String>{};
  int _nextPage = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _items.clear();
        _nextPage = 0;
        _hasMore = true;
      }
    });
    try {
      final page = await Get.find<OutpostRepository>().getOutpostBans(
        outpostId: widget.outpostId,
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        final known = _items.map((i) => i.user_uuid).toSet();
        _items.addAll(page.where((i) => !known.contains(i.user_uuid)));
        _nextPage++;
        _hasMore = page.length == _pageSize;
      });
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _lift(OutpostBanItem item) async {
    final name = item.name ?? 'this user';
    final isBlock = item.banKind == OutpostBanKind.ban;
    final confirmed = await showAppConfirm(
      title: isBlock ? 'Unblock $name?' : 'Let $name back in?',
      message: isBlock
          ? 'They can join this outpost again. They need to join it again '
              'to become a member.'
          : 'They can rejoin this outpost right away.',
      confirmLabel: isBlock ? 'Unblock' : 'Allow back',
    );
    if (!confirmed || !mounted) return;
    setState(() => _lifting.add(item.user_uuid));
    final done = await unbanFromOutpost(
      outpostId: widget.outpostId,
      userId: item.user_uuid,
    );
    if (!mounted) return;
    setState(() {
      _lifting.remove(item.user_uuid);
      if (done) _items.removeWhere((i) => i.user_uuid == item.user_uuid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: AppSheet.maxHeight(context, 0.8)),
      child: AppSheet(
        title: 'Removed & blocked',
        subtitle: 'People the hosts took out of this outpost',
        icon: Icons.block_rounded,
        iconColor: AppColors.danger,
        trailing: AppRefreshButton(
          loading: _loading,
          onTap: () => _load(refresh: true),
        ),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(heightFactor: 1, child: CircularProgressIndicator()),
        );
      }
      if (_error != null) {
        return AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: "Couldn't load the list",
          message: _error,
          actionLabel: 'Try again',
          onAction: () => _load(refresh: true),
          compact: true,
        );
      }
      return const AppEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'Nobody is blocked',
        message: 'People you remove or block from this outpost show up here.',
        compact: true,
      );
    }
    final amICreator = widget.creatorUuid == myId;
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return Center(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: _load,
                    child: const Text('Load more'),
                  ),
          );
        }
        final item = _items[index];
        final creatorOnly =
            !amICreator && item.banned_by_user_uuid == widget.creatorUuid;
        return _BanRow(
          item: item,
          lifting: _lifting.contains(item.user_uuid),
          creatorOnly: creatorOnly,
          onLift: () => _lift(item),
        );
      },
    );
  }
}

class _BanRow extends StatelessWidget {
  final OutpostBanItem item;
  final bool lifting;

  /// The creator set this block, so only they can lift it.
  final bool creatorOnly;
  final VoidCallback onLift;
  const _BanRow({
    required this.item,
    required this.lifting,
    required this.creatorOnly,
    required this.onLift,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.name ?? 'User';
    final isBlock = item.banKind == OutpostBanKind.ban;
    final until = item.expiresAt;
    final by = item.banned_by_user_uuid == myId
        ? 'you'
        : (item.banned_by_user_name ?? 'a host');
    final status = isBlock || until == null
        ? 'Blocked by $by'
        : 'Removed by $by · back in ${formatTimeUntil(until)}';
    final reason = item.reason;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Img(
            src: item.image ?? '',
            alt: name,
            size: 40,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: ColorName.greyText),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '“$reason”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: ColorName.white.withAlpha(200),
                    ),
                  ),
                ],
                if (creatorOnly) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only the creator can unblock',
                    style: TextStyle(fontSize: 11, color: ColorName.greyText),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (lifting)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!creatorOnly)
            TextButton(
              onPressed: onLift,
              child: Text(isBlock ? 'Unblock' : 'Allow back'),
            ),
        ],
      ),
    );
  }
}
