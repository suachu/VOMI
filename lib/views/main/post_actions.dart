import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/post_card.dart';

class PostActionsRow extends StatelessWidget {
  final Post post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenFacility;

  const PostActionsRow({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onOpenFacility,
  });

  static const TextStyle _countStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 354),
      child: Row(
        children: [
          _ActionCount(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            isActive: isLiked,
            count: post.likeCount + (isLiked ? 1 : 0),
            onCountTap: () => _openSocialSheet(context, post, _SheetType.like),
            onIconTap: onToggleLike,
          ),
          const SizedBox(width: 14),
          _ActionCount(
            icon: Icons.mode_comment_outlined,
            count: post.commentCount,
            onCountTap: () =>
                _openSocialSheet(context, post, _SheetType.comment),
            onIconTap: () =>
                _openSocialSheet(context, post, _SheetType.comment),
          ),
          const SizedBox(width: 14),
          _ActionCount(
            icon: Icons.bookmark_border,
            activeIcon: Icons.bookmark,
            isActive: isSaved,
            count: post.shareCount + (isSaved ? 1 : 0),
            onCountTap: () => _openSocialSheet(context, post, _SheetType.share),
            onIconTap: onToggleSave,
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onOpenFacility,
              child: const Text(
                '이 봉사 구경가기',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCount extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final bool isActive;
  final int count;
  final VoidCallback onCountTap;
  final VoidCallback? onIconTap;

  const _ActionCount({
    required this.icon,
    this.activeIcon,
    this.isActive = false,
    required this.count,
    required this.onCountTap,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFACD7E6);

    return Row(
      children: [
        GestureDetector(
          onTap: onIconTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              size: 18,
              color: isActive ? activeColor : AppColors.textDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: onCountTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, left: 2, top: 6, bottom: 6),
            child: Text('$count', style: PostActionsRow._countStyle),
          ),
        ),
      ],
    );
  }
}

enum _SheetType { like, comment, share }

void _openSocialSheet(BuildContext context, Post post, _SheetType type) {
  final title = switch (type) {
    _SheetType.like => '좋아요',
    _SheetType.comment => '댓글',
    _SheetType.share => '공유',
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox.expand(),
          ),
          DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 14,
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return const SizedBox(height: 8);
                    }
                    if (index == 1) {
                      return Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }
                    if (index == 2) {
                      return const SizedBox(height: 10);
                    }
                    if (index == 3) {
                      return Center(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    if (index == 4) {
                      return const SizedBox(height: 12);
                    }

                    final listIndex = index - 5;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          '${listIndex + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(
                        '$title 사용자 ${listIndex + 1}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: type == _SheetType.comment
                          ? const Text(
                              '너무 따뜻한 봉사였어요!',
                              style: TextStyle(fontSize: 12),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
