import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:podium/gen/colors.gen.dart';

/// [ButtonType] is used to change the type of widgets
enum ButtonType {
  /// Default type is [ButtonType.solid], used to fill with color for widget
  solid,

  /// Type [ButtonType.outline], used for widget with outline border and fill color with Colors.transparent
  outline,

  /// Type [ButtonType.outline2x], used for widget with outline2x border and border.width = 2.0 and fill color with Colors.transparent
  outline2x,

  /// Type [ButtonType.transparent], used for widget with fill color with Colors.transparent
  transparent,

  /// Type [ButtonType.gradient], used for widget with fill color with Colors.transparent
  gradient,
}

/// [ButtonShape] is used to shape the Button widget.
enum ButtonShape {
  /// [ButtonShape.pills], used for pills shaped button with rounded corners
  pills,

  /// Default shape is [ButtonShape.standard], used for standard rectangle button with rounded corners
  standard,

  /// [ButtonShape.square], used for square button
  square,
}

/// [Position] is used to position the icon, badges to start or end of the button
/// See Button and ButtonBadge
enum Position {
  /// [Position.start] is used to place icon, badges to start of the Button and ButtonBadge
  start,

  /// [Position.end] is used to place icon, badges to end of the Button and ButtonBadge
  end,
}

/// [ButtonSize] is used to change the size of the widget.
class ButtonSize {
  /// [ButtonSize.SMALL] is used for small size widget
  static const double SMALL = 30;

  /// Default size if [ButtonSize.MEDIUM] is used for medium size widget
  static const double MEDIUM = 35;

  /// [ButtonSize.LARGE] is used for large size widget
  static const double LARGE = 50;
}

class ButtonColors {
  static const Color PRIMARY = ColorName.primaryBlue;
  static const Color SECONDARY = Color(0xffAA66CC);
  static const Color SUCCESS = Color(0xff10DC60);
  static const Color INFO = Color(0xff33B5E5);
  static const Color WARNING = Color(0xffFFBB33);
  static const Color DANGER = Color(0xffF04141);
  static const Color LIGHT = Color(0xffE0E0E0);
  static const Color DARK = Color(0xff222428);
  static const Color WHITE = Color(0xffffffff);
  static const Color FOCUS = Color(0xff434054);
  static const Color ALT = Color(0xff794c8a);
  static const Color TRANSPARENT = Colors.transparent;
}

class Button extends StatefulWidget {
  /// Create buttons of all types. check out [GFIconButton] for icon buttons, and [GFBadge] for badges
  const Button({
    Key? key,
    required this.onPressed,
    this.loading = false,
    this.onHighlightChanged,
    this.textStyle,
    this.boxShadow,
    this.buttonBoxShadow,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.elevation = 0.0,
    this.focusElevation = 4.0,
    this.hoverElevation = 4.0,
    this.highlightElevation = 1.0,
    this.disabledElevation = 0.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.constraints,
    this.borderShape,
    this.animationDuration = kThemeChangeDuration,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    this.child,
    this.type = ButtonType.solid,
    this.shape = ButtonShape.standard,
    this.color = ColorName.buttonOutlineBorder,
    this.textColor,
    this.position = Position.start,
    this.size = ButtonSize.LARGE,
    this.borderSide,
    this.text,
    this.icon,
    this.blockButton,
    this.fullWidthButton,
    this.colorScheme,
    this.enableFeedback,
    this.onLongPress,
    this.disabledColor,
    this.disabledTextColor,
  })  : materialTapTargetSize =
            materialTapTargetSize ?? MaterialTapTargetSize.padded,
        // assert(elevation != null && elevation >= 0.0),
        assert(focusElevation >= 0.0),
        assert(hoverElevation >= 0.0),
        assert(highlightElevation >= 0.0),
        assert(disabledElevation >= 0.0),
        super(key: key);

  /// Called when the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  /// Called by the underlying [InkWell] widget's InkWell.onHighlightChanged callback.
  final ValueChanged<bool>? onHighlightChanged;

  final bool loading;

  /// Defines the default text style, with [Material.textStyle], for the button's [child].
  final TextStyle? textStyle;

  /// The border side for the button's [Material].
  final BorderSide? borderSide;

  /// The box shadow for the button's [Material], if ButtonType is solid
  final BoxShadow? boxShadow;

  /// Pass [ButtonColors] or [Color]. The color for the button's [Material] when it has the input focus.
  final Color? focusColor;

  /// Pass [ButtonColors] or [Color]. The color for the button's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  /// Pass [ButtonColors] or [Color]. The highlight color for the button's [InkWell].
  final Color? highlightColor;

  /// Pass [ButtonColors] or [Color]. The splash color for the button's [InkWell].
  final Color? splashColor;

  /// The elevation for the button's [Material] when the button is [enabled] but not pressed.
  final double elevation;

  /// The elevation for the button's [Material] when the button is [enabled] and a pointer is hovering over it.
  final double hoverElevation;

  /// The elevation for the button's [Material] when the button is [enabled] and has the input focus.
  final double focusElevation;

  /// The elevation for the button's [Material] when the button is [enabled] and pressed.
  final double highlightElevation;

  /// The elevation for the button's [Material] when the button is not [enabled].
  final double disabledElevation;

  /// The internal padding for the button's [child].
  final EdgeInsetsGeometry padding;

  /// Defines the button's size.
  final BoxConstraints? constraints;

  /// The shape of the button's [Material].
  final ShapeBorder? borderShape;

  /// Defines the duration of animated changes for [shape] and [elevation].
  final Duration animationDuration;

  /// Typically the button's label.
  final Widget? child;

  /// Whether the button is enabled or disabled.
  bool get enabled => onPressed != null;

  /// Configures the minimum size of the tap target.
  final MaterialTapTargetSize materialTapTargetSize;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.Clip}
  final Clip clipBehavior;

  /// Button type of [ButtonType] i.e, solid, outline, outline2x, transparent
  final ButtonType type;

  /// Button type of [ButtonShape] i.e, standard, pills, square, shadow, icons
  final ButtonShape shape;

  /// Pass [ButtonColors] or [Color]
  final Color color;

  /// The fill color of the button when the button is disabled.
  ///
  /// The default value of this color is the theme's disabled color,
  /// [ThemeData.disabledColor].
  ///
  /// See also:
  ///
  ///  * [color] - the fill color of the button when the button is [enabled].
  final Color? disabledColor;

  /// Pass [ButtonColors] or [Color]
  final Color? textColor;

  /// The color to use for this button's text when the button is disabled.
  ///
  /// The button's [Material.textStyle] will be the current theme's button
  /// text style, [ThemeData.textTheme.button], configured with this color.
  ///
  /// The default value is the theme's disabled color,
  /// [ThemeData.disabledColor].
  ///
  /// If [textColor] is a [WidgetStateProperty<Color>], [disabledTextColor]
  /// will be ignored.
  ///
  /// See also:
  ///
  ///  * [textColor] - The color to use for this button's text when the button is [enabled].
  final Color? disabledTextColor;

  /// size of [double] or [ButtonSize] i.e, 1.2, small, medium, large etc.
  final double size;

  /// text of type [String] is alternative to child. text will get priority over child
  final String? text;

  /// icon of type [Widget]
  final Widget? icon;

  /// icon type of [Position] i.e, start, end
  final Position position;

  /// on true state blockButton gives block size button
  final bool? blockButton;

  /// on true state full width Button gives full width button
  final bool? fullWidthButton;

  /// on true state default box shadow appears around button, if ButtonType is solid
  final bool? buttonBoxShadow;

  /// A set of thirteen colors that can be used to derive the button theme's
  /// colors.
  ///
  /// This property was added much later than the theme's set of highly
  /// specific colors, like [ThemeData.highlightColor],
  /// [ThemeData.splashColor] etc.
  ///
  /// The colors for new button classes can be defined exclusively in terms
  /// of [colorScheme]. When it's possible, the existing buttons will
  /// (continue to) gradually migrate to it.
  final ColorScheme? colorScheme;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// Called when the button is long-pressed.
  ///
  /// If this callback and [onPressed] are null, then the button will be disabled.
  ///
  /// See also:
  ///
  ///  * [enabled], which is true if the button is enabled.
  final VoidCallback? onLongPress;

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  late Color color;
  Color? textColor;
  Color? disabledColor;
  Color? disabledTextColor;
  Widget? child;
  Widget? icon;
  Function? onPressed;
  late ButtonType type;
  late ButtonShape shape;
  late double size;
  late Position position;
  late BoxShadow boxShadow;

  final Set<WidgetState> _states = <WidgetState>{};

  @override
  void initState() {
    color = widget.color;
    textColor = widget.textColor;
    child = (widget.text != null && widget.loading == false)
        ? Text(widget.text!)
        : widget.loading == true
            ? _loader20
            : widget.child;
    icon = widget.icon;
    onPressed = widget.onPressed;
    type = widget.type;
    shape = widget.shape;
    size = widget.size;
    position = widget.position;
    disabledColor = widget.disabledColor;
    disabledTextColor = widget.disabledTextColor;
    _updateState(
      WidgetState.disabled,
      !widget.enabled,
    );
    super.initState();
  }

  bool get _hovered => _states.contains(WidgetState.hovered);
  bool get _focused => _states.contains(WidgetState.focused);
  bool get _pressed => _states.contains(WidgetState.pressed);
  bool get _disabled => _states.contains(WidgetState.disabled);

  double? buttonWidth() {
    double? buttonWidth = 0;
    if (widget.blockButton == true) {
      buttonWidth = MediaQuery.of(context).size.width * 0.96;
    } else if (widget.fullWidthButton == true) {
      buttonWidth = MediaQuery.of(context).size.width;
    } else {
      buttonWidth = null;
    }
    return buttonWidth;
  }

  void _updateState(WidgetState state, bool value) {
    value ? _states.add(state) : _states.remove(state);
  }

  void _handleHighlightChanged(bool value) {
    if (_pressed != value) {
      setState(() {
        _updateState(WidgetState.pressed, value);
        if (widget.onHighlightChanged != null) {
          widget.onHighlightChanged!(value);
        }
      });
    }
  }

  void _handleHoveredChanged(bool value) {
    if (_hovered != value) {
      setState(() {
        _updateState(WidgetState.hovered, value);
      });
    }
  }

  void _handleFocusedChanged(bool value) {
    if (_focused != value) {
      setState(() {
        _updateState(WidgetState.focused, value);
      });
    }
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    _updateState(WidgetState.disabled, !widget.enabled);
    // If the button is disabled while a press gesture is currently ongoing,
    // InkWell makes a call to handleHighlightChanged. This causes an exception
    // because it calls setState in the middle of a build. To preempt this, we
    // manually update pressed to false when this situation occurs.
    if (_disabled && _pressed) {
      _handleHighlightChanged(false);
    }
    color = widget.color;
    textColor = widget.textColor;
    child = (widget.text != null && widget.loading == false)
        ? Text(widget.text!)
        : widget.loading == true
            ? _loader20
            : widget.child;
    icon = widget.icon;
    onPressed = widget.onPressed;
    type = widget.type;
    shape = widget.shape;
    size = widget.size;
    position = widget.position;
    disabledColor = widget.disabledColor;
    disabledTextColor = widget.disabledTextColor;
    _updateState(
      WidgetState.disabled,
      !widget.enabled,
    );
    super.didUpdateWidget(oldWidget);
  }

  double get _effectiveElevation {
    // These conditionals are in order of precedence, so be careful about
    // reorganizing them.
    if (_disabled) {
      return widget.disabledElevation;
    }
    if (_pressed) {
      return widget.highlightElevation;
    }
    if (_hovered) {
      return widget.hoverElevation;
    }
    if (_focused) {
      return widget.focusElevation;
    }
    return widget.elevation;
  }

  @override
  Widget build(BuildContext context) {
    ShapeBorder shapeBorderType;

    Color getBorderColor() {
      if (widget.enabled) {
        final Color fillColor = color;
        if (widget.color != ColorName.buttonOutlineBorder) {
          return widget.color;
        }
        if (widget.type == ButtonType.outline ||
            widget.type == ButtonType.outline2x) {
          return ColorName.buttonOutlineBorder;
        }
        return fillColor;
      } else {
        if (disabledColor != null) {
          return disabledColor!;
        } else {
          return color.withOpacity(0.48);
        }
      }
    }

    Color getDisabledFillColor() {
      if (widget.type == ButtonType.transparent ||
          widget.type == ButtonType.outline ||
          widget.type == ButtonType.outline2x) {
        return Colors.transparent;
      }
      if (disabledColor != null) {
        return disabledColor!;
      } else {
        return color.withOpacity(0.48);
      }
    }

    Color getColor() {
      if (widget.type == ButtonType.transparent ||
          widget.type == ButtonType.outline ||
          widget.type == ButtonType.outline2x) {
        return Colors.transparent;
      }
      if (widget.type == ButtonType.gradient) {
        return Colors.transparent;
      }
      final Color fillColor = color;
      return fillColor;
    }

    Color getDisabledTextColor() {
      if (disabledTextColor != null) {
        return disabledTextColor!;
      } else if (widget.type == ButtonType.outline ||
          widget.type == ButtonType.outline2x ||
          widget.type == ButtonType.transparent) {
        return color;
      } else {
        return ButtonColors.DARK;
      }
    }

    Color getTextColor() {
      if (widget.type == ButtonType.outline ||
          widget.type == ButtonType.outline2x ||
          widget.type == ButtonType.transparent) {
        return widget.enabled
            ? textColor == null
                ? color == ButtonColors.TRANSPARENT
                    ? ButtonColors.DARK
                    : ColorName.white
                : textColor!
            : getDisabledTextColor();
      }
      if (textColor == null) {
        if (color == ButtonColors.TRANSPARENT) {
          return ButtonColors.DARK;
        } else {
          return ButtonColors.WHITE;
        }
      } else {
        return textColor!;
      }
    }

    final Color? effectiveTextColor =
        WidgetStateProperty.resolveAs<Color?>(widget.textStyle?.color, _states);
    final Color themeColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);
    final BorderSide outlineBorder = BorderSide(
      color: widget.borderSide == null
          ? getBorderColor()
          : widget.borderSide!.color,
      width: (widget.borderSide?.width == null
          ? widget.type == ButtonType.outline2x
              ? 2.0
              : 1.0
          : widget.borderSide?.width)!,
    );

    Size minSize;
    switch (widget.materialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        minSize = const Size(48, 48);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        minSize = Size.zero;
        break;
      default:
        minSize = Size.zero;
        break;
    }

    final BorderSide shapeBorder =
        widget.type == ButtonType.outline || widget.type == ButtonType.outline2x
            ? outlineBorder
            : widget.type == ButtonType.gradient
                ? BorderSide.none
                : widget.borderSide ??
                    BorderSide(
                      color: getBorderColor(),
                      width: 0,
                    );

    if (shape == ButtonShape.pills) {
      shapeBorderType = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          50,
        ),
        side: shapeBorder,
      );
    } else if (shape == ButtonShape.square) {
      shapeBorderType = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: shapeBorder,
      );
    } else if (shape == ButtonShape.standard) {
      shapeBorderType = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: shapeBorder,
      );
    } else {
      shapeBorderType = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: shapeBorder,
      );
    }

    BoxDecoration? getBoxShadow() {
      if (widget.type != ButtonType.transparent) {
        if (widget.boxShadow == null && widget.buttonBoxShadow != true) {
          return null;
        } else {
          return BoxDecoration(
            color: widget.type == ButtonType.transparent ||
                    widget.type == ButtonType.outline ||
                    widget.type == ButtonType.outline2x
                ? Colors.transparent
                : color,
            borderRadius: widget.shape == ButtonShape.pills
                ? BorderRadius.circular(50)
                : widget.shape == ButtonShape.standard
                    ? BorderRadius.circular(8)
                    : BorderRadius.zero,
            boxShadow: [
              widget.boxShadow == null && widget.buttonBoxShadow == true
                  ? BoxShadow(
                      color: themeColor,
                      blurRadius: 1.5,
                      spreadRadius: 2,
                      offset: Offset.zero,
                    )
                  : widget.boxShadow != null
                      ? widget.boxShadow!
                      : BoxShadow(
                          color: Theme.of(context).canvasColor,
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: Offset.zero,
                        ),
            ],
          );
        }
      }
      return null;
    }

    TextStyle getTextStyle() {
      if (widget.size == ButtonSize.SMALL) {
        return TextStyle(
          color: widget.enabled ? getTextColor() : getDisabledTextColor(),
          fontSize: 12,
        );
      } else if (widget.size == ButtonSize.MEDIUM) {
        return TextStyle(
          color: widget.enabled ? getTextColor() : getDisabledTextColor(),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        );
      } else if (widget.size == ButtonSize.LARGE) {
        return TextStyle(
          color: widget.enabled ? getTextColor() : getDisabledTextColor(),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );
      }
      return TextStyle(
        color: widget.enabled ? getTextColor() : getDisabledTextColor(),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      );
    }

    _gradientBoxDecoration(bool disabled) => BoxDecoration(
          gradient: LinearGradient(
            colors: [
              disabled
                  ? ColorName.primaryBlue.withOpacity(0.3)
                  : ColorName.primaryBlue,
              disabled
                  ? ColorName.secondaryBlue.withOpacity(0.3)
                  : ColorName.secondaryBlue,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: widget.shape == ButtonShape.pills
              ? BorderRadius.circular(50)
              : widget.shape == ButtonShape.standard
                  ? BorderRadius.circular(8)
                  : BorderRadius.zero,
        );
    final Widget result = Container(
      constraints: icon == null
          ? const BoxConstraints(minWidth: 80)
          : const BoxConstraints(minWidth: 90),
      decoration: widget.type == ButtonType.solid
          ? getBoxShadow()
          : type == ButtonType.gradient
              ? widget.onPressed == null
                  ? _gradientBoxDecoration(true)
                  : _gradientBoxDecoration(false)
              : null,
      child: Material(
        elevation: _effectiveElevation,
        textStyle: widget.textStyle == null ? getTextStyle() : widget.textStyle,
        shape: widget.type == ButtonType.transparent
            ? null
            : widget.borderShape ?? shapeBorderType,
        color: widget.enabled ? getColor() : getDisabledFillColor(),
        type: MaterialType.button,
        animationDuration: widget.animationDuration,
        clipBehavior: widget.clipBehavior,
        child: InkWell(
          borderRadius: widget.type == ButtonType.transparent
              ? BorderRadius.circular(8)
              : BorderRadius.circular(0),
          focusNode: widget.focusNode,
          canRequestFocus: widget.enabled,
          onFocusChange: _handleFocusedChanged,
          autofocus: widget.autofocus,
          onHighlightChanged: _handleHighlightChanged,
          onHover: _handleHoveredChanged,
          onTap: widget.loading ? () {} : widget.onPressed,
          onLongPress: widget.onLongPress,
          enableFeedback: widget.enableFeedback ?? true,
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          customBorder: widget.type == ButtonType.transparent
              ? null
              : widget.borderShape ?? shapeBorderType,
          child: IconTheme.merge(
            data: IconThemeData(color: effectiveTextColor),
            child: Container(
              height: size,
              width: buttonWidth(),
              padding: widget.padding,
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: icon != null &&
                        child != null &&
                        (position == Position.start)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          icon!,
                          const SizedBox(width: 8),
                          child!
                        ],
                      )
                    : icon != null &&
                            child != null &&
                            (position == Position.end)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              child!,
                              const SizedBox(width: 8),
                              icon!
                            ],
                          )
                        : child,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: widget.enabled,
      child: _InputPadding(
        minSize: minSize,
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: _handleFocusedChanged,
          autofocus: widget.autofocus,
          child: result,
        ),
      ),
    );
  }
}

/// A widget to pad the area around a [MaterialButton]'s inner [Material].
///
/// Redirect taps that occur in the padded area around the child to the center
/// of the child. This increases the size of the button and the button's
/// "tap target", but not its material or its ink splashes.
class _InputPadding extends SingleChildRenderObjectWidget {
  const _InputPadding({
    Key? key,
    Widget? child,
    this.minSize,
  }) : super(
          key: key,
          child: child,
        );

  final Size? minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderInputPadding(minSize);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderInputPadding renderObject) {
    renderObject.minSize = minSize;
  }
}

class _RenderInputPadding extends RenderShiftedBox {
  _RenderInputPadding(this._minSize, [RenderBox? child]) : super(child);

  Size? get minSize => _minSize;
  Size? _minSize;

  set minSize(Size? value) {
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null && minSize != null) {
      return math.max(child!.getMinIntrinsicWidth(height), minSize!.width);
    }
    return 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null && minSize != null) {
      return math.max(child!.getMinIntrinsicHeight(width), minSize!.height);
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null && minSize != null) {
      return math.max(child!.getMaxIntrinsicWidth(height), minSize!.width);
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null && minSize != null) {
      return math.max(child!.getMaxIntrinsicHeight(width), minSize!.height);
    }
    return 0;
  }

  @override
  void performLayout() {
    if (child != null && minSize != null) {
      child!.layout(constraints, parentUsesSize: true);
      // ignore: avoid_as
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      final double height = math.max(child!.size.width, minSize!.width);
      final double width = math.max(child!.size.height, minSize!.height);
      size = constraints.constrain(Size(height, width));
      childParentData.offset =
          // ignore: avoid_as
          Alignment.center.alongOffset(size - child!.size as Offset);
    } else {
      size = Size.zero;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }

    if (child != null) {
      final Offset center = child!.size.center(Offset.zero);
      return result.addWithRawTransform(
        transform: MatrixUtils.forceToPoint(center),
        position: center,
        hitTest: (BoxHitTestResult result, Offset position) {
          assert(position == center);
          return child!.hitTest(
            result,
            position: center,
          );
        },
      );
    }

    throw Exception('child property cannot be null');
  }
}

final _loader20 = Container(
  height: 20,
  width: 20,
  child: const CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(
      ColorName.white,
    ),
  ),
);
