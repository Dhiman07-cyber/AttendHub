import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'shimmer_skeleton.dart';

class LandscapeHeaderWidget extends StatelessWidget {
  final String greeting;
  final String userName;
  final String semesterInfo;
  final String avatarInitial;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onMenuTap;
  final bool showArtwork;
  final bool showActions;
  final bool showMenuButton;
  final bool isLoading;
  final double? topOffset;

  const LandscapeHeaderWidget({
    super.key,
    this.greeting = 'Good morning,',
    required this.userName,
    required this.semesterInfo,
    this.avatarInitial = 'D',
    this.onNotificationTap,
    this.onAvatarTap,
    this.onMenuTap,
    this.showArtwork = true,
    this.showActions = false,
    this.showMenuButton = false,
    this.isLoading = false,
    this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final effectiveTop = topPadding + (topOffset ?? 76.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background illustration with crystal clarity and expanded height
        if (showArtwork)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 220 + (topOffset ?? 76.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Panoramic mountain sunrise with crisp clarity so the artwork is vividly visible
                Image.asset(
                  'assets/images/dashboard_hero.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.12, -0.30),
                  cacheWidth: 800,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFBECE2),
                            Color(0xFFF5E3D8),
                            AppColors.background,
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Smooth gradient fade into AppColors.background only towards the bottom edge
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.55, 0.85, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color.fromRGBO(247, 241, 236, 0.60),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Header content
        Padding(
          padding: EdgeInsets.fromLTRB(20, effectiveTop, 20, 10),
          child: Row(

            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Greeting & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 16,
                        color: const Color(0xFF4A342B),
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Colors.white70,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 6),
                      const SkeletonBox.text(width: 140, height: 26),
                      const SizedBox(height: 6),
                      const SkeletonBox.text(width: 100, height: 12),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C1E18),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (semesterInfo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          semesterInfo,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 13.5,
                            color: const Color(0xFF5A443A),
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(
                                color: Colors.white70,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Action buttons (Bell notification & Avatar)
              if (showActions || onAvatarTap != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notification bell with red badge dot
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.divider, width: 1.1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: AppColors.ink,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDE6854),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Avatar Circle matching the reference design
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(
                              0xFF4A2421), // Deep brown circle from reference
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(74, 36, 33, 0.25),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
