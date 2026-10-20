import 'package:flutter/widgets.dart';

/// Rebuilds only when [select] returns a different value. Unlike Obx, which
/// rebuilds whenever anything it reads changes, so a shared map update would
/// rebuild every row of a list instead of just the rows it affects.
///
/// [sources] are the observables [select] reads; GetX Rx values are
/// [Listenable]s. Use records to select several values at once.
class RxSelector<T> extends StatefulWidget {
  final List<Listenable> sources;
  final T Function() select;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const RxSelector({
    super.key,
    required this.sources,
    required this.select,
    required this.builder,
    this.child,
  });

  @override
  State<RxSelector<T>> createState() => _RxSelectorState<T>();
}

class _RxSelectorState<T> extends State<RxSelector<T>> {
  late Listenable _listenable;
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select();
    _listenable = Listenable.merge(widget.sources)..addListener(_onChange);
  }

  @override
  void didUpdateWidget(RxSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.select();
    if (!_sameSources(oldWidget.sources, widget.sources)) {
      _listenable.removeListener(_onChange);
      _listenable = Listenable.merge(widget.sources)..addListener(_onChange);
    }
  }

  static bool _sameSources(List<Listenable> a, List<Listenable> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  void _onChange() {
    final next = widget.select();
    if (next != _value && mounted) setState(() => _value = next);
  }

  @override
  void dispose() {
    _listenable.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, widget.child);
}
