import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/core/utils/extensions.dart';

/// Round user/project avatar with an initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.avatarUrl,
    this.radius = 18,
    super.key,
  });

  final String name;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: colors.accentSoft,
      child: Text(
        name.initials,
        style: TextStyle(
          color: colors.accent,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final url = avatarUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (_, provider) => CircleAvatar(
        radius: radius,
        backgroundImage: provider,
        backgroundColor: colors.surfaceMuted,
      ),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
