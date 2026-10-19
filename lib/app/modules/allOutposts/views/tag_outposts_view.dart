import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/widgets/outpostsList.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/root.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/ui/app_ui.dart';

abstract class TagOutpostsParams {
  static const id = 'id';
  static const name = 'name';
}

void openTagOutposts({required int id, required String name}) {
  Navigate.to(
    type: NavigationTypes.toNamed,
    route: Routes.TAG_OUTPOSTS,
    parameters: {TagOutpostsParams.id: '$id', TagOutpostsParams.name: name},
  );
}

/// Every outpost with one tag, loaded a page at a time.
class TagOutpostsView extends StatefulWidget {
  const TagOutpostsView({super.key});

  @override
  State<TagOutpostsView> createState() => _TagOutpostsViewState();
}

class _TagOutpostsViewState extends State<TagOutpostsView> {
  final _repo = Get.find<OutpostRepository>();
  late final int? _tagId =
      int.tryParse(Get.parameters[TagOutpostsParams.id] ?? '');
  late final String _tagName = Get.parameters[TagOutpostsParams.name] ?? '';

  final _items = <OutpostModel>[];
  final _seen = <String>{};
  int _nextPage = 0;
  bool _loading = false;
  bool _reachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _reload() async {
    _items.clear();
    _seen.clear();
    _nextPage = 0;
    _reachedEnd = false;
    _error = null;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    final id = _tagId;
    if (id == null || _loading || _reachedEnd) return;
    setState(() => _loading = true);
    try {
      final page = await _repo.fetchOutpostsByTagId(
        id: id,
        page: _nextPage,
        page_size: numberOfOutpostsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _nextPage++;
        _reachedEnd = page.length < numberOfOutpostsPerPage;
        // A new outpost shifts the pages, so the next page may repeat one.
        for (final outpost in page) {
          if (_seen.add(outpost.uuid)) _items.add(outpost);
        }
        _error = null;
      });
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageWrapper(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: '#$_tagName',
                subtitle: 'Outposts tagged $_tagName',
                showBack: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty) {
      if (_loading) {
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => const OutpostCardSkeleton(),
        );
      }
      if (_error != null || _tagId == null) {
        return AppEmptyState(
          icon: Icons.wifi_off_rounded,
          title: "Couldn't load outposts",
          message: _error,
          onAction: _reload,
        );
      }
      return const AppEmptyState(
        icon: Icons.tag_rounded,
        title: 'No outposts yet',
        message: 'Nobody has used this tag yet.',
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: OutpostsList(
        outpostsList: List.unmodifiable(_items),
        listPage: ListPage.search,
        onNearEnd: _loadMore,
      ),
    );
  }
}
