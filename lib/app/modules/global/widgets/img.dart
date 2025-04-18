import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/constants.dart';

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
    final isUrl = Uri.parse(src).isAbsolute;
    final isEmptyAndHasIfEmpty = src.isEmpty && ifEmpty != null;
    return Container(
      width: size ?? width ?? 70,
      height: size ?? height ?? 70,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: isEmptyAndHasIfEmpty
          ? Image.asset(
              ifEmpty!,
              width: size ?? width ?? 70,
              height: size ?? height ?? 70,
              fit: BoxFit.cover,
            )
          : CachedNetworkImage(
              imageUrl: isUrl ? src : avatarPlaceHolder(alt ?? "OO"),
              placeholder: (context, url) => GFShimmer(
                secondaryColor: ColorName.pageBackground,
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
              errorWidget: (context, url, error) => Container(
                width: size ?? width ?? 70,
                height: size ?? height ?? 70,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  shape: BoxShape.rectangle,
                  image: DecorationImage(
                    image: NetworkImage(
                      avatarPlaceHolder(alt ?? "OO"),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
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
