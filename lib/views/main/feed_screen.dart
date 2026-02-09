import 'package:flutter/material.dart';
import 'package:vomi/core/theme/colors.dart';
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
  String filter = '전체';
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final friendNames = <String>{'미스터츄'};

    final postsAll = [
      Post(
        userName: "빵준",
        profileImage: const AssetImage("assets/images/bread.JPG"),
        title: "빵주니의 첫번째 유기견 봉사!!",
        date: "2026.04.02",
        location: "경기도 하남시 미사동로40번길 75-91, 하남시유기견보호소",
        facility: const Facility(
          name: "하남시유기견보호소",
          address: "경기도 하남시 미사동로40번길 75-91",
          description:
              "유기견 보호와 입양 연계를 위한 시설입니다. "
              "봉사자는 산책, 청소, 놀이 활동 등을 지원할 수 있어요.",
          phone: "031-000-0000",
          hours: "매일 10:00 - 18:00",
        ),
        likeCount: 26,
        commentCount: 13,
        shareCount: 1,
        emojiImage: const AssetImage("assets/images/smiling.png"),
        blocks: [
          TextBlock("오늘 포항시 동물보호센터에 가서 자원봉사를 했다!"),
          ImageBlock(const AssetImage('assets/images/dog1.png')),
          ImageBlock(const AssetImage('assets/images/dog2.png')),
          TextBlock(
            "같이 산책도 하고, 옆에서 쓰다듬어 주면서 웃기도 했다. "
            "사람을 너무 좋아해서 먼저 다가와 주고, 꼬리를 흔들며 따라오는 모습이 참 예뻤다. "
            "그런데 이렇게 사람을 좋아하는 아이들이 왜 여기 있을까 생각하니 마음이 아파졌다.",
          ),
        ],
      ),
      Post(
        userName: "빵준",
        profileImage: const AssetImage("assets/images/bread.JPG"),
        title: "빵주니의 첫번째 유기견 봉사!!",
        date: "2026.04.02",
        location: "경기도 하남시 미사동로40번길 75-91, 하남시유기견보호소",
        facility: const Facility(
          name: "하남시유기견보호소",
          address: "경기도 하남시 미사동로40번길 75-91",
          description:
              "유기견 보호와 입양 연계를 위한 시설입니다. "
              "봉사자는 산책, 청소, 놀이 활동 등을 지원할 수 있어요.",
          phone: "031-000-0000",
          hours: "매일 10:00 - 18:00",
        ),
        likeCount: 26,
        commentCount: 13,
        shareCount: 1,
        emojiImage: const AssetImage("assets/images/smiling.png"),
        blocks: [
          TextBlock("오늘 포항시 동물보호센터에 가서 자원봉사를 했다!"),
          ImageBlock(const AssetImage('assets/images/dog1.png')),
          ImageBlock(const AssetImage('assets/images/dog2.png')),
          TextBlock(
            "같이 산책도 하고, 옆에서 쓰다듬어 주면서 웃기도 했다. "
            "사람을 너무 좋아해서 먼저 다가와 주고, 꼬리를 흔들며 따라오는 모습이 참 예뻤다. "
            "그런데 이렇게 사람을 좋아하는 아이들이 왜 여기 있을까 생각하니 마음이 아파졌다.",
          ),
        ],
      ),
      Post(
        userName: "미스터츄",
        profileImage: const AssetImage("assets/images/V.png"),
        title: "빵주니의 첫번째 유기견 봉사!!",
        date: "2026.04.02",
        location: "경기도 하남시 미사동로40번길 75-91, 하남시유기견보호소",
        facility: const Facility(
          name: "하남시유기견보호소",
          address: "경기도 하남시 미사동로40번길 75-91",
          description:
              "유기견 보호와 입양 연계를 위한 시설입니다. "
              "봉사자는 산책, 청소, 놀이 활동 등을 지원할 수 있어요.",
          phone: "031-000-0000",
          hours: "매일 10:00 - 18:00",
        ),
        likeCount: 26,
        commentCount: 13,
        shareCount: 1,
        emojiImage: const AssetImage("assets/images/smiling.png"),
        blocks: [
          TextBlock("오늘 포항시 동물보호센터에 가서 자원봉사를 했다!"),
          ImageBlock(const AssetImage('assets/images/dog1.png')),
          ImageBlock(const AssetImage('assets/images/dog2.png')),
          TextBlock(
            "같이 산책도 하고, 옆에서 쓰다듬어 주면서 웃기도 했다. "
            "사람을 너무 좋아해서 먼저 다가와 주고, 꼬리를 흔들며 따라오는 모습이 참 예뻤다. "
            "그런데 이렇게 사람을 좋아하는 아이들이 왜 여기 있을까 생각하니 마음이 아파졌다.",
          ),
        ],
      ),
    ];
    final postsFriends =
        postsAll.where((post) => friendNames.contains(post.userName)).toList();
    final posts = filter == '내 친구' ? postsFriends : postsAll;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopBar(
        selectedLabel: filter,
        onSelect: (v) => setState(() => filter = v),
        onAddPressed: () {
          // TODO: create post
        },
        onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        logoImage: const AssetImage('assets/images/vomi.png'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                onToggleLike: () => setState(() => _isLiked = !_isLiked),
                onToggleSave: () => setState(() => _isSaved = !_isSaved),
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
      ),
    );
  }
}
