import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/post_visibility_registry.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/auth/pages/login_method_page.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/facility_detail_screen.dart';
import 'package:vomi/views/main/facility_models.dart';
import 'package:vomi/views/main/journal/journal_storage.dart';
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
  final UserProfileLocalService _profileService = const UserProfileLocalService();
  static const Set<String> _friendNames = {'미스터츄'};
<<<<<<< HEAD
  static const Set<String> _publicScopes = {'전체공개', '전체 공개', '전체'};
  static const Set<String> _friendVisibleScopes = {
    '전체공개',
    '전체 공개',
    '전체',
    '친구공개',
    '친구 공개',
    '친구',
  };
  String filter = '전체';
=======
  static const Set<String> _publicScopes = {'전체공개', '전체'};
  static const Set<String> _friendVisibleScopes = {
    '전체공개',
    '전체',
    '친구공개',
    '친구',
  };
  String filter = '전체';
  bool _isLiked = false;
  bool _isSaved = false;
  List<Post> _lastGoodPosts = const [];
  String _myDisplayName = '';
>>>>>>> 9d5ec26 (내 작업 내용)

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadMyName();
    UserProfileLocalService.profileChanged.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    UserProfileLocalService.profileChanged.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    _loadMyName();
  }

  Future<void> _loadMyName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _profileService.ensure(user);
    if (!mounted) return;
    setState(() {
      _myDisplayName = profile.name;
    });
    await JournalStorage.cleanupDanglingPostsForUser(
      uid: user.uid,
      legacyAuthorNames: {
        profile.name,
        (user.displayName ?? '').trim(),
      },
    );
  }

  Future<void> _promptLogin() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginMethodPage()));
  }

  Query<Map<String, dynamic>> _buildQuery() {
<<<<<<< HEAD
    final effectiveFilter =
        (!_isLoggedIn && filter == '내 친구') ? '전체' : filter;
    final scopes = effectiveFilter == '내 친구'
        ? _friendVisibleScopes.toList()
        : _publicScopes.toList();
    return FirebaseFirestore.instance
        .collection('posts')
        .where('scope', whereIn: scopes);
=======
    return FirebaseFirestore.instance.collection('posts').limit(300);
  }

  int _createdAtMillis(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) return createdAtRaw.millisecondsSinceEpoch;
    if (createdAtRaw is String) {
      return DateTime.tryParse(createdAtRaw)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
>>>>>>> 9d5ec26 (내 작업 내용)
  }

  String _normalizeScope(dynamic rawScope) {
    if (rawScope == null) return '';
    return '$rawScope'.replaceAll(' ', '').trim();
  }

  DateTime _parseCreatedAt(dynamic createdAtRaw) {
    if (createdAtRaw is Timestamp) {
      return createdAtRaw.toDate();
    }
    if (createdAtRaw is String) {
      return DateTime.tryParse(createdAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isVisibleForCurrentFilter(Map<String, dynamic> data) {
    final effectiveFilter =
        (!_isLoggedIn && filter == '내 친구') ? '전체' : filter;
    final scope = _normalizeScope(data['scope']);
    if (effectiveFilter == '내 친구') {
      return _friendVisibleScopes.contains(scope);
    }
    return _publicScopes.contains(scope);
  }

<<<<<<< HEAD
  Post _postFromDoc(String id, Map<String, dynamic> data) {
    final authorName =
        (data['authorName'] as String?)?.trim().isNotEmpty == true
            ? (data['authorName'] as String).trim()
            : '익명';
=======
  Post _postFromDoc(Map<String, dynamic> data) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authorUid = (data['authorUid'] as String?) ?? '';
    final authorName = (authorUid == myUid && _myDisplayName.trim().isNotEmpty)
        ? _myDisplayName.trim()
        : ((data['authorName'] as String?)?.trim().isNotEmpty == true
              ? (data['authorName'] as String).trim()
              : '익명');
>>>>>>> 9d5ec26 (내 작업 내용)
    final authorPhotoUrl = (data['authorPhotoUrl'] as String?) ?? '';
    final title = (data['title'] as String?)?.trim() ?? '';
    final content = (data['content'] as String?)?.trim() ?? '';
    final location = (data['location'] as String?)?.trim() ?? '';
    final createdAtRaw = data['createdAt'];
    final createdAt = _parseCreatedAt(createdAtRaw);
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
      id: id,
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
      saveCount: data['saveCount'] as int? ?? data['shareCount'] as int? ?? 0,
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
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: PostVisibilityRegistry.hiddenPostIds,
        builder: (context, hiddenIds, _) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: PostVisibilityRegistry.hiddenPostKeys,
            builder: (context, hiddenKeys, __) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _buildQuery().snapshots(),
            builder: (context, snapshot) {
          if (snapshot.hasError) {
<<<<<<< HEAD
            debugPrint('Feed load error: ${snapshot.error}');
=======
            if (_lastGoodPosts.isNotEmpty) {
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(0, 16, 0, bottomInset),
                itemCount: _lastGoodPosts.length,
                separatorBuilder: (_, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = _lastGoodPosts[index];
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
            }
>>>>>>> 9d5ec26 (내 작업 내용)
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

<<<<<<< HEAD
          final docs = (snapshot.data?.docs ?? const [])
              .toList()
            ..sort(
              (a, b) => _parseCreatedAt(b.data()['createdAt'])
                  .compareTo(_parseCreatedAt(a.data()['createdAt'])),
            );
          final posts = docs
              .where((doc) => _isVisibleForCurrentFilter(doc.data()))
              .map((doc) => _postFromDoc(doc.id, doc.data()))
=======
          final docs = snapshot.data?.docs ?? const [];
          final filteredDocs = docs
              .where((doc) => _isVisibleForCurrentFilter(doc.data()))
              .where((doc) {
                final data = doc.data();
                final postId = ((data['id'] as String?)?.trim().isNotEmpty ??
                        false)
                    ? (data['id'] as String).trim()
                    : doc.id;
                if (hiddenIds.contains(postId)) return false;
                final createdAtMillis = _createdAtMillis(data);
                final signature = PostVisibilityRegistry.keyFromRaw(
                  authorUid: (data['authorUid'] as String?) ?? '',
                  title: (data['title'] as String?) ?? '',
                  location: (data['location'] as String?) ?? '',
                  content: (data['content'] as String?) ?? '',
                  createdAtMillis: createdAtMillis,
                );
                return !hiddenKeys.contains(signature);
              })
              .toList()
            ..sort(
              (a, b) =>
                  _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())),
            );
          final posts = filteredDocs
              .map((doc) => _postFromDoc(doc.data()))
>>>>>>> 9d5ec26 (내 작업 내용)
              .where(
                (post) => filter != '내 친구' || _friendNames.contains(post.userName),
              )
              .toList();

          if (posts.isNotEmpty) {
            _lastGoodPosts = posts;
          }

          if (posts.isEmpty) {
            if (_lastGoodPosts.isNotEmpty) {
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(0, 16, 0, bottomInset),
                itemCount: _lastGoodPosts.length,
                separatorBuilder: (_, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = _lastGoodPosts[index];
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
            }
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
                    onRequireLogin: _promptLogin,
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
          );
            },
          );
        },
      ),
    );
  }
}
