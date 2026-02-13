import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/post_card.dart';

class PostActionsRow extends StatelessWidget {
  final Post post;
  final Future<void> Function() onRequireLogin;
  final VoidCallback onOpenFacility;

  const PostActionsRow({
    super.key,
    required this.post,
    required this.onRequireLogin,
    required this.onOpenFacility,
  });

  static const TextStyle _countStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  @override
  Widget build(BuildContext context) {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(post.id);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: postRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final likeCount = data?['likeCount'] as int? ?? post.likeCount;
        final commentCount = data?['commentCount'] as int? ?? post.commentCount;
        final saveCount = data?['saveCount'] as int? ??
            data?['shareCount'] as int? ??
            post.saveCount;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 354),
          child: Row(
            children: [
              _LikeAction(
                post: post,
                postRef: postRef,
                count: likeCount,
                onRequireLogin: onRequireLogin,
              ),
              const SizedBox(width: 14),
              _ActionCount(
                icon: Icons.mode_comment_outlined,
                iconAsset: 'assets/images/chat.png',
                count: commentCount,
                onCountTap: () => _openSocialSheet(context, post, _SheetType.comment),
                onIconTap: () => _openSocialSheet(context, post, _SheetType.comment),
              ),
              const SizedBox(width: 14),
              _SaveAction(
                post: post,
                postRef: postRef,
                count: saveCount,
                onRequireLogin: onRequireLogin,
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    fixedSize: const Size(138, 34),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onOpenFacility,
                  child: const Text(
                    '이 기관 구경가기',
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
      },
    );
  }
}

class _ActionCount extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String? iconAsset;
  final String? activeIconAsset;
  final double iconSize;
  final bool isActive;
  final int count;
  final VoidCallback onCountTap;
  final VoidCallback? onIconTap;

  const _ActionCount({
    required this.icon,
    this.activeIcon,
    this.iconAsset,
    this.activeIconAsset,
    this.iconSize = 18,
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
            child: _iconWidget(activeColor),
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

  Widget _iconWidget(Color activeColor) {
    final assetPath = isActive ? (activeIconAsset ?? iconAsset) : iconAsset;
    if (assetPath != null) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF000000),
          BlendMode.srcIn,
        ),
        child: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      );
    }
    return Icon(
      isActive && activeIcon != null ? activeIcon : icon,
      size: iconSize,
      color: isActive ? activeColor : AppColors.textDark,
    );
  }
}

enum _SheetType { like, comment, share }

void _openSocialSheet(BuildContext context, Post post, _SheetType type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SocialSheet(post: post, type: type),
  );
}

class _LikeAction extends StatelessWidget {
  const _LikeAction({
    required this.post,
    required this.postRef,
    required this.count,
    required this.onRequireLogin,
  });

  final Post post;
  final DocumentReference<Map<String, dynamic>> postRef;
  final int count;
  final Future<void> Function() onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ActionCount(
        icon: Icons.favorite_border,
        activeIcon: Icons.favorite,
        iconAsset: 'assets/images/volunteer/heart.png',
        activeIconAsset: 'assets/images/heart3.png',
        iconSize: 22,
        isActive: false,
        count: count,
        onCountTap: () => _openSocialSheet(context, post, _SheetType.like),
        onIconTap: () => onRequireLogin(),
      );
    }

    final likeRef = postRef.collection('likes').doc(user.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: likeRef.snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.data?.exists ?? false;
        return _ActionCount(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          iconAsset: 'assets/images/volunteer/heart.png',
          activeIconAsset: 'assets/images/heart3.png',
          iconSize: 22,
          isActive: isLiked,
          count: count,
          onCountTap: () => _openSocialSheet(context, post, _SheetType.like),
          onIconTap: () => _toggleReaction(
            context: context,
            postRef: postRef,
            user: user,
            isActive: isLiked,
            collection: 'likes',
            countField: 'likeCount',
          ),
        );
      },
    );
  }
}

class _SaveAction extends StatelessWidget {
  const _SaveAction({
    required this.post,
    required this.postRef,
    required this.count,
    required this.onRequireLogin,
  });

  final Post post;
  final DocumentReference<Map<String, dynamic>> postRef;
  final int count;
  final Future<void> Function() onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ActionCount(
        icon: Icons.bookmark_border,
        activeIcon: Icons.bookmark,
        iconAsset: 'assets/images/AA.png',
        activeIconAsset: 'assets/images/AA.png',
        isActive: false,
        count: count,
        onCountTap: () => _openSocialSheet(context, post, _SheetType.share),
        onIconTap: () => onRequireLogin(),
      );
    }

    final saveRef = postRef.collection('saves').doc(user.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: saveRef.snapshots(),
      builder: (context, snapshot) {
        final isSaved = snapshot.data?.exists ?? false;
        return _ActionCount(
          icon: Icons.bookmark_border,
          activeIcon: Icons.bookmark,
          iconAsset: 'assets/images/AA.png',
          activeIconAsset: 'assets/images/AA.png',
          isActive: isSaved,
          count: count,
          onCountTap: () => _openSocialSheet(context, post, _SheetType.share),
          onIconTap: () => _toggleReaction(
            context: context,
            postRef: postRef,
            user: user,
            isActive: isSaved,
            collection: 'saves',
            countField: 'saveCount',
          ),
        );
      },
    );
  }
}

Future<void> _toggleReaction({
  required BuildContext context,
  required DocumentReference<Map<String, dynamic>> postRef,
  required User user,
  required bool isActive,
  required String collection,
  required String countField,
}) async {
  final docRef = postRef.collection(collection).doc(user.uid);
  final batch = FirebaseFirestore.instance.batch();
  final displayName = user.displayName?.trim().isNotEmpty == true
      ? user.displayName!.trim()
      : '익명';

  if (isActive) {
    batch.delete(docRef);
    batch.update(postRef, {countField: FieldValue.increment(-1)});
  } else {
    batch.set(docRef, {
      'uid': user.uid,
      'displayName': displayName,
      'photoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {countField: FieldValue.increment(1)});
  }

  try {
    await batch.commit();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('처리 중 오류가 발생했어요.')),
    );
  }
}

class _SocialSheet extends StatefulWidget {
  const _SocialSheet({
    required this.post,
    required this.type,
  });

  final Post post;
  final _SheetType type;

  @override
  State<_SocialSheet> createState() => _SocialSheetState();
}

class _SocialSheetState extends State<_SocialSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        _SheetType.like => '좋아요',
        _SheetType.comment => '댓글',
        _SheetType.share => '저장',
      };

  CollectionReference<Map<String, dynamic>> get _collection {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    switch (widget.type) {
      case _SheetType.like:
        return postRef.collection('likes');
      case _SheetType.comment:
        return postRef.collection('comments');
      case _SheetType.share:
        return postRef.collection('saves');
    }
  }

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    final commentRef = postRef.collection('comments').doc();
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : '익명';

    final batch = FirebaseFirestore.instance.batch();
    batch.set(commentRef, {
      'uid': user.uid,
      'displayName': displayName,
      'photoUrl': user.photoURL ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});

    try {
      await batch.commit();
      _commentController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 등록에 실패했어요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _collection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        '아직 항목이 없어요.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final name = (data['displayName'] as String?)?.trim();
                      final photo = (data['photoUrl'] as String?)?.trim() ?? '';
                      final text = (data['text'] as String?)?.trim() ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          backgroundColor: const Color(0xFFE7ECF0),
                          child: photo.isEmpty
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        title: Text(
                          name?.isNotEmpty == true ? name! : '익명',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: widget.type == _SheetType.comment
                            ? Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6E7781),
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.type == _SheetType.comment)
              SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: '댓글을 입력하세요',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE3E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE3E7EB)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _sending ? null : _submitComment,
                        icon: Icon(
                          Icons.send_rounded,
                          color: _sending
                              ? Colors.grey
                              : const Color(0xFF1E7AD4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
