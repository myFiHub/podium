import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// A reusable loading indicator widget using SpinKitWave.
class LoadingWidget extends StatelessWidget {
  /// The size of the loading indicator. Defaults to 24.0.
  final double size;

  /// The _color of the loading indicator. Defaults to ColorName.white.
  final Color? color;
  Color get _color => color ?? ColorName.white;

  /// The type of wave animation. Defaults to SpinKitWaveType.start
  final SpinKitWaveType type;

  const LoadingWidget({
    super.key,
    this.size = 24.0,
    this.color,
    this.type = SpinKitWaveType
        .center, // Changed default to center for a more typical wave
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(
      color: _color,
      size: size,
      type: type,
      // You can adjust itemCount and duration if needed
      // itemCount: 5,
      // duration: Duration(milliseconds: 1200),
    );
  }
}
