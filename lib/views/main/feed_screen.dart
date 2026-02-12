import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/auth/pages/login_method_page.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/facility_detail_screen.dart';
import 'package:vomi/views/main/facility_models.dart';
import 'package:vomi/views/main/post_actions.dart';
import 'post_card.dart';
import 'top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const Set<String> _friendNames = {'미스터츄'};
  static const Set<String> _publicScopes = {'전체공개', '전체'};
  static const Set<String> _friendVisibleScopes = {'전체공개', '전체', '친구공개', '친구'};
  String filter = '전체';
  bool _isLiked = false;
  bool _isSaved = false;

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _promptLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginMethodPage()),
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    return FirebaseFirestore.instance
        .collection('posts')
        // Read recent posts first and apply visibility in app code to avoid
        // requiring composite indexes for every scope filter variant.
        .orderBy('createdAt', descending: true);
  }

  String _normalizeScope(dynamic rawScope) {
    if (rawScope == null) return '';
    return '$rawScope'.replaceAll(' ', '').trim();
  }

  bool _isVisibleForCurrentFilter(Map<String, dynamic> data) {
    final scope = _normalizeScope(data['scope']);
    if (filter == '내 친구') return _friendVisibleScopes.contains(scope);
    return _publicScopes.contains(scope);
  }

  Post _postFromDoc(Map<String, dynamic> data) {
    final authorName =
        (data['authorName'] as String?)?.trim().isNotEmpty == true
            ? (data['authorName'] as String).trim()
            : '익명';
    final authorPhotoUrl = (data['authorPhotoUrl'] as String?) ?? '';
    final title = (data['title'] as String?)?.trim() ?? '';
    final content = (data['content'] as String?)?.trim() ?? '';
    final location = (data['location'] as String?)?.trim() ?? '';
    final createdAtRaw = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    }
    final date =
        '${createdAt.year.toString().padLeft(4, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';

    final imageUrls = ((data['imageUrls'] as List?) ?? [])
        .map((e) => '$e')
        .where((url) => url.isNotEmpty)
        .toList();

    final blocks = <PostBlock>[
      if (content.isNotEmpty) TextBlock(content),
      ...imageUrls.map((url) => ImageBlock(NetworkImage(url))),
    ];

    final emotionIndex = data['emotionIndex'] as int? ?? 0;
    final emojiAsset = switch (emotionIndex) {
      0 => 'assets/images/love.png',
      1 => 'assets/images/emotion_neutral.png',
      2 => 'assets/images/sad.png',
      3 => 'assets/images/emotion_proud.png',
      4 => 'assets/images/emotion_happy.png',
      _ => 'assets/images/smiling.png',
    };

    return Post(
      userName: authorName,
      profileImage: authorPhotoUrl.isNotEmpty
          ? NetworkImage(authorPhotoUrl)
          : const AssetImage('assets/images/V.png'),
      title: title.isNotEmpty ? title : '제목 없음',
      date: date,
      location: location.isNotEmpty ? location : '위치 정보 없음',
      facility: Facility(
        name: location.isNotEmpty ? location : '봉사 장소',
        address: location.isNotEmpty ? location : '주소 정보 없음',
        description: content.isNotEmpty ? content : '설명 정보 없음',
      ),
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      shareCount: 0,
      emojiImage: AssetImage(emojiAsset),
      blocks: blocks.isNotEmpty ? blocks : [TextBlock('내용이 없습니다.')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset =
        BottomNavBar.navH + MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopBar(
        selectedLabel: filter,
        onSelect: (v) {
          if (v == '내 친구' && !_isLoggedIn) {
            _promptLogin();
            return;
          }
          setState(() => filter = v);
        },
        onAddPressed: () {
          // TODO: create post
        },
        onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        logoImage: const AssetImage('assets/images/vomi.png'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                '피드를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                style: TextStyle(fontSize: 15, color: Color(0xFF7A838A)),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? const [];
          final posts = docs
              .where((doc) => _isVisibleForCurrentFilter(doc.data()))
              .map((doc) => _postFromDoc(doc.data()))
              .where(
                (post) => filter != '내 친구' || _friendNames.contains(post.userName),
              )
              .toList();

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                '아직 게시글이 없어요',
                style: TextStyle(fontSize: 15, color: Color(0xFF7A838A)),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(0, 16, 0, bottomInset),
            itemCount: posts.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              return Column(
                children: [
                  PostCard(post: post),
                  const SizedBox(height: 10),
                  PostActionsRow(
                    post: post,
                    isLiked: _isLiked,
                    isSaved: _isSaved,
                    onToggleLike: () {
                      if (!_isLoggedIn) {
                        _promptLogin();
                        return;
                      }
                      setState(() => _isLiked = !_isLiked);
                    },
                    onToggleSave: () {
                      if (!_isLoggedIn) {
                        _promptLogin();
                        return;
                      }
                      setState(() => _isSaved = !_isSaved);
                    },
                    onOpenFacility: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FacilityDetailScreen(
                            facility: post.facility,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
