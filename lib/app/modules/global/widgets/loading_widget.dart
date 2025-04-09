import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// A reusable loading indicator widget using SpinKitWave.
class LoadingWidget extends StatelessWidget {
  /// The size of the loading indicator. Defaults to 24.0.
  final double size;

  /// The color of the loading indicator. Defaults to Colors.white.
  final Color color;

  /// The type of wave animation. Defaults to SpinKitWaveType.start
  final SpinKitWaveType type;

  const LoadingWidget({
    Key? key,
    this.size = 24.0,
    this.color = Colors.white,
    this.type = SpinKitWaveType
        .center, // Changed default to center for a more typical wave
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(
      color: color,
      size: size,
      type: type,
      // You can adjust itemCount and duration if needed
      // itemCount: 5,
      // duration: Duration(milliseconds: 1200),
    );
  }
}
