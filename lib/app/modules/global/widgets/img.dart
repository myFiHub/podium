import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/utils/palette.dart';

/// The name encoded in a ui-avatars.com placeholder URL, which is drawn
/// locally with [InitialsAvatar] instead of downloading a picture of it.
String? placeholderAvatarName(String url) {
  if (!url.startsWith('https://ui-avatars.com/api/')) return null;
  final name = Uri.tryParse(url)?.queryParameters['name'] ?? '';
  return name.endsWith('.png') ? name.substring(0, name.length - 4) : name;
}

class Img extends StatelessWidget {
  final String src;
  final double? size;
  final double? width;
  final double? height;
  final String? alt;
  final String? ifEmpty;
  final BorderRadius? borderRadius;
  const Img({
    super.key,
    required this.src,
    this.size,
    this.width,
    this.height,
    this.alt,
    this.ifEmpty,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final isUrl = Uri.tryParse(src)?.isAbsolute ?? false;
    final isEmptyAndHasIfEmpty = src.isEmpty && ifEmpty != null;
    final assetPath = src.startsWith('assets/')
        ? src
        : isEmptyAndHasIfEmpty
            ? ifEmpty
            : null;
    final boxSize = max(size ?? width ?? 70, size ?? height ?? 70);
    // Decode near display size; 1.5x leaves room for non-square sources.
    final cacheSize =
        (boxSize * MediaQuery.devicePixelRatioOf(context) * 1.5).round();
    final placeholderName = isUrl ? placeholderAvatarName(src) : (alt ?? 'OO');
    return SizedBox(
      width: size ?? width ?? 70,
      height: size ?? height ?? 70,
      child: assetPath != null
          ? ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              child: Image.asset(
                assetPath,
                width: size ?? width ?? 70,
                height: size ?? height ?? 70,
                fit: BoxFit.cover,
              ),
            )
          : placeholderName != null
              ? InitialsAvatar(
                  name: placeholderName, borderRadius: borderRadius)
              : CachedNetworkImage(
                  imageUrl: src,
                  memCacheWidth: cacheSize,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) => GFShimmer(
                    secondaryColor: ColorName.cardBackground,
                    mainColor: ColorName.cardBorder,
                    child: Container(
                      width: size ?? width ?? 70,
                      height: size ?? height ?? 70,
                      decoration: BoxDecoration(
                        color: ColorName.cardBorder,
                        borderRadius: borderRadius,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => InitialsAvatar(
                    name: alt ?? 'OO',
                    borderRadius: borderRadius,
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    width: size ?? width ?? 70,
                    height: size ?? height ?? 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: borderRadius,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
    );
  }
}

/// Same look as the ui-avatars.com placeholders it replaces: up to two
/// initials, dark on light grey. Fills its parent.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final BorderRadius? borderRadius;
  const InitialsAvatar({super.key, required this.name, this.borderRadius});

  static String initialsOf(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'OO';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return (words.first.characters.first + words.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) => Text(
          initialsOf(name),
          maxLines: 1,
          style: TextStyle(
            color: const Color(0xFF222222),
            fontSize: constraints.biggest.shortestSide * 0.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}
