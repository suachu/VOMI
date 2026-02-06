import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        selectedLabel: filter,
        onSelect: (v) => setState(() => filter = v),
        onAddPressed: () {
          // TODO: create post
        },
        onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        // logoImage: const AssetImage('assets/logo/vomi.png'),
      ),
      body: Center(
        child: PostCard(
          post: Post(
            userName: "빵준",
            profileImage: const AssetImage("assets/images/bread.JPG"),
            title: "빵주니의 첫번째 유기견 봉사!!",
            date: "2026.04.02",
            location: "경기도 하남시 미사동로40번길 75-91, 하남시유기견보호소",
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
        ),
      ),
    );
  }
}
