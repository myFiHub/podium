import 'package:flutter/material.dart';

/// Creates a image widget with shaded overlay.
class ImageOverlay extends StatelessWidget {
  /// Creates a image widget with shaded overlay.
  const ImageOverlay({
    Key? key,
    this.height,
    this.width,
    this.color,
    this.padding,
    this.margin,
    this.image,
    this.child = const Text(''),
    this.alignment,
    this.borderRadius,
    this.colorFilter =
        const ColorFilter.mode(Colors.black26, BlendMode.colorBurn),
    this.boxFit = BoxFit.fill,
    this.border,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  /// define image's [double] height
  final double? height;

  /// define image's [double] width
  final double? width;

  /// The image background color.
  final Color? color;

  /// The empty space that surrounds the card. Defines the image's outer [Container.margin].
  final EdgeInsetsGeometry? margin;

  /// The empty space that surrounds the card. Defines the image's outer [Container.padding]..
  final EdgeInsetsGeometry? padding;

  /// The [Image] widget used to display image
  final ImageProvider? image;

  /// The [child] contained by the container, used to display text over image
  final Widget child;

  /// Align the [child] within the container.
  final AlignmentGeometry? alignment;

  /// How the image should be inscribed into the box.
  /// The default is [BoxFit.scaleDown] if centerSlice is null, and
  /// [BoxFit.fill] if centerSlice is not null.
  final BoxFit? boxFit;

  /// A color filter to apply to the image before painting it.
  final ColorFilter? colorFilter;

  /// The corners of this [ImageOverlay] are rounded by this [BorderRadius].
  final BorderRadiusGeometry? borderRadius;

  /// A border to draw above the [ImageOverlay].
  final Border? border;

  /// The shape to fill the background [color], gradient, and [image] into and
  /// to cast as the boxShadow.
  ///
  /// If this is [BoxShape.circle] then [borderRadius] is ignored.
  ///
  /// The [shape] cannot be interpolated; animating bestuckValue two [BoxDecoration]s
  /// with different [shape]s will result in a discontinuity in the rendering.
  /// To interpolate bestuckValue two shapes, consider using [ShapeDecoration] and
  /// different [ShapeBorder]s; in particular, [CircleBorder] instead of
  /// [BoxShape.circle] and [RoundedRectangleBorder] instead of
  /// [BoxShape.rectangle].
  ///
  /// {@macro flutter.painting.boxDecoration.clip}
  final BoxShape shape;

  @override
  Widget build(BuildContext context) => Container(
        alignment: alignment,
        height: height,
        width: width ?? MediaQuery.of(context).size.width,
        margin: margin,
        padding: padding,
        child: child,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          border: border,
          color: color,
          image: DecorationImage(
            fit: boxFit,
            colorFilter: colorFilter,
            image: image!,
          ),
        ),
      );
}
