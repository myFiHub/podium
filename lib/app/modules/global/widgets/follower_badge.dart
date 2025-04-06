import 'package:flutter/material.dart';
import 'package:podium/utils/styles.dart';

class FollowerBadge extends StatelessWidget {
  const FollowerBadge({
    super.key,
    required this.followerCount,
  });

  final int followerCount;

  Color get _badgeColor => followerCount >= 1000
      ? Colors.purple
      : followerCount >= 100
          ? Colors.blue
          : followerCount >= 10
              ? Colors.green
              : Colors.grey;

  String get _badgeText => followerCount >= 1000
      ? 'Elite'
      : followerCount >= 100
          ? 'Popular'
          : followerCount >= 10
              ? 'Rising'
              : 'Emerging';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            color: _badgeColor,
            size: 16,
          ),
          space5,
          Text(
            '$followerCount followers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _badgeColor,
            ),
          ),
          space5,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _badgeText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
