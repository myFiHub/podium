/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $EnvGen {
  const $EnvGen();

  /// File path: env/development.env
  String get development => 'env/development.env';

  /// File path: env/production.env
  String get production => 'env/production.env';

  /// List of all assets
  List<String> get values => [development, production];
}

class $AssetsAudioGen {
  const $AssetsAudioGen();

  /// File path: assets/audio/blip.mp3
  String get blip => 'assets/audio/blip.mp3';

  /// List of all assets
  List<String> get values => [blip];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/ageRestricted.png
  AssetGenImage get ageRestricted =>
      const AssetGenImage('assets/images/ageRestricted.png');

  /// File path: assets/images/apple.png
  AssetGenImage get apple => const AssetGenImage('assets/images/apple.png');

  /// File path: assets/images/bell.png
  AssetGenImage get bell => const AssetGenImage('assets/images/bell.png');

  /// File path: assets/images/boo.png
  AssetGenImage get boo => const AssetGenImage('assets/images/boo.png');

  /// File path: assets/images/browse.png
  AssetGenImage get browse => const AssetGenImage('assets/images/browse.png');

  /// File path: assets/images/cheer.png
  AssetGenImage get cheer => const AssetGenImage('assets/images/cheer.png');

  /// File path: assets/images/email.png
  AssetGenImage get email => const AssetGenImage('assets/images/email.png');

  /// File path: assets/images/explore.png
  AssetGenImage get explore => const AssetGenImage('assets/images/explore.png');

  /// File path: assets/images/facebook.png
  AssetGenImage get facebook =>
      const AssetGenImage('assets/images/facebook.png');

  /// File path: assets/images/g_icon.png
  AssetGenImage get gIcon => const AssetGenImage('assets/images/g_icon.png');

  /// File path: assets/images/github.png
  AssetGenImage get github => const AssetGenImage('assets/images/github.png');

  /// File path: assets/images/gold_pot.svg
  SvgGenImage get goldPot => const SvgGenImage('assets/images/gold_pot.svg');

  /// File path: assets/images/linkedin.png
  AssetGenImage get linkedin =>
      const AssetGenImage('assets/images/linkedin.png');

  /// File path: assets/images/logo.png
  AssetGenImage get logo => const AssetGenImage('assets/images/logo.png');

  /// File path: assets/images/luma.svg
  SvgGenImage get luma => const SvgGenImage('assets/images/luma.svg');

  /// File path: assets/images/lumaPng.png
  AssetGenImage get lumaPng => const AssetGenImage('assets/images/lumaPng.png');

  /// File path: assets/images/movement_logo.svg
  SvgGenImage get movementLogo =>
      const SvgGenImage('assets/images/movement_logo.svg');

  /// File path: assets/images/particle_icon.png
  AssetGenImage get particleIcon =>
      const AssetGenImage('assets/images/particle_icon.png');

  /// File path: assets/images/x_platform.png
  AssetGenImage get xPlatform =>
      const AssetGenImage('assets/images/x_platform.png');

  /// List of all assets
  List<dynamic> get values => [
        ageRestricted,
        apple,
        bell,
        boo,
        browse,
        cheer,
        email,
        explore,
        facebook,
        gIcon,
        github,
        goldPot,
        linkedin,
        logo,
        luma,
        lumaPng,
        movementLogo,
        particleIcon,
        xPlatform
      ];
}

class Assets {
  Assets._();

  static const $AssetsAudioGen audio = $AssetsAudioGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $EnvGen env = $EnvGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class SvgGenImage {
  const SvgGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = false;

  const SvgGenImage.vec(
    this._assetName, {
    this.size,
    this.flavors = const {},
  }) : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
