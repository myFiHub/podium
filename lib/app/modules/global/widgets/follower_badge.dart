import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

class FollowerBadge extends StatelessWidget {
  const FollowerBadge({
    super.key,
    required this.followerCount,
  });

  final int followerCount;

  Color get _badgeColor => followerCount >= 1000
      ? const Color(0xFFFFC857)
      : followerCount >= 100
          ? ColorName.primaryBlue
          : followerCount >= 10
              ? const Color(0xFF3DDC97)
              : ColorName.greyText;

  String get _badgeText => followerCount >= 1000
      ? 'Elite'
      : followerCount >= 100
          ? 'Popular'
          : followerCount >= 10
              ? 'Rising'
              : 'Emerging';

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_alt_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            '$followerCount followers',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(46),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _badgeText.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
