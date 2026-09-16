import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/core/widgets/user_avatar.dart';
import 'package:glam/src/features/auth/domain/user.dart';

/// Overlapping avatars for assignees/reviewers, capped at [max] with a
/// `+N` overflow bubble.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.users,
    this.radius = 11,
    this.max = 4,
    super.key,
  });

  final List<GitLabUser> users;
  final double radius;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    final shown = users.take(max).toList();
    final overflow = users.length - shown.length;
    final step = radius * 1.4;
    final width =
        (shown.length + (overflow > 0 ? 1 : 0) - 1) * step + radius * 2;
    return SizedBox(
      width: width,
      height: radius * 2,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: UserAvatar(
                  name: shown[i].name,
                  avatarUrl: shown[i].avatarUrl,
                  radius: radius,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * step,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: colors.surfaceMuted,
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: radius * 0.62,
                    color: colors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
