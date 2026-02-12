import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/my_page_service.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/main/profile_edit_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final figmaTopFromScreen = 83.0;
    final listTopPadding = (figmaTopFromScreen - safeTop).clamp(0.0, figmaTopFromScreen);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return const Center(
                child: Text(
                  '로그인이 필요해요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(24, listTopPadding, 24, 28),
              children: [
                _ProfileSummaryCard(user: user),
                const SizedBox(height: 19),
                _ArrowListTile(
                  leading: const Image(
                    image: AssetImage('assets/images/volunteer/twopeople.png'),
                    width: 20,
                    height: 20,
                  ),
                  title: '친구 목록',
                  trailingValue: '0',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TitleOnlyScreen(title: '친구 목록'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 19),
                const _SettingsCard(),
                const SizedBox(height: 29),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        letterSpacing: 0,
                        color: Color(0xFFFF4646),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFFF4646),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatefulWidget {
  const _ProfileSummaryCard({required this.user});

  final User user;

  @override
  State<_ProfileSummaryCard> createState() => _ProfileSummaryCardState();
}

class _ProfileSummaryCardState extends State<_ProfileSummaryCard> {
  final MyPageService _myPageService = const MyPageService();
  final UserProfileLocalService _profileService = const UserProfileLocalService();
  late Future<MyPageSummary> _summaryFuture;
  String _displayName = '이름 없음';
  String _appId = 'vomi_user';
  String _photoPath = '';

  Future<void> _loadProfile() async {
    final profile = await _profileService.ensure(widget.user);
    if (!mounted) return;
    setState(() {
      _displayName = profile.name;
      _appId = profile.appId;
      _photoPath = profile.photoPath;
    });
  }

  @override
  void initState() {
    super.initState();
    _summaryFuture = _myPageService.fetchSummary(user: widget.user);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _ProfileSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _summaryFuture = _myPageService.fetchSummary(user: widget.user);
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localPhotoAvailable =
        _photoPath.isNotEmpty && File(_photoPath).existsSync();
    final ImageProvider? profileImage = localPhotoAvailable
        ? FileImage(File(_photoPath))
        : (widget.user.photoURL != null
            ? NetworkImage(widget.user.photoURL!)
            : null);
    return Center(
      child: Container(
        width: 354,
        height: 457,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 78,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundColor: const Color(0xFFE8E8E8),
                        backgroundImage: profileImage,
                        child: !localPhotoAvailable && widget.user.photoURL == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 34,
                                color: Color(0xFF8D8D8D),
                              )
                            : null,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  letterSpacing: 0,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '@$_appId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 14,
                                  letterSpacing: -0.15,
                                  color: Color(0xFF6A7282),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 270,
                    top: 26.5,
                    child: TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileEditScreen(user: widget.user),
                          ),
                        );
                        _loadProfile();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF636E72),
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '프로필 편집',
                        style: TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 2.0,
                          letterSpacing: 0,
                          color: Color(0xFF636E72),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF636E72),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FutureBuilder<MyPageSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 313,
                        height: 124,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3FCFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFDFE6E9),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image(
                                    image: AssetImage('assets/images/time22.png'),
                                    width: 13.333333969116211,
                                    height: 13.333333969116211,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '총 봉사시간',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 20 / 14,
                                      letterSpacing: 0,
                                      color: Color(0xFF07A2D8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const _TotalTimeText(hoursText: '128'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 29),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            imagePath: 'assets/images/cal2.png',
                            imageWidth: 16,
                            imageHeight: 17.78,
                            value: '3',
                            label: '신청한\n봉사',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TitleOnlyScreen(title: '신청한 봉사'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            imagePath: 'assets/images/check.png',
                            imageWidth: 16,
                            imageHeight: 16,
                            value: '28',
                            label: '참여 완료\n봉사',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TitleOnlyScreen(
                                    title: '참여 완료한 봉사',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            imagePath: 'assets/images/heart2.png',
                            imageWidth: 16,
                            imageHeight: 14,
                            value: summary?.likedCount.toString() ??
                                (isLoading ? '...' : '0'),
                            label: '찜한\n봉사',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TitleOnlyScreen(title: '찜한 봉사'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalTimeText extends StatelessWidget {
  const _TotalTimeText({required this.hoursText});

  final String hoursText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          hoursText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A9FD6),
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 4),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            '시간',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 28 / 20,
              letterSpacing: 0,
              color: Color(0xFF0A9FD6),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String imagePath;
  final double imageWidth;
  final double imageHeight;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 100,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEFEFEF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Image.asset(imagePath, width: imageWidth, height: imageHeight),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0,
                color: Color(0xFFFF9F43),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF636E72),
                height: 14.4 / 12,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowListTile extends StatelessWidget {
  const _ArrowListTile({
    required this.leading,
    required this.title,
    this.trailingValue,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String? trailingValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 354,
          height: 48,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                      letterSpacing: 0,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  if (trailingValue != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      trailingValue!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 20 / 13,
                        letterSpacing: 0,
                        color: Color(0xFF00A5DF),
                      ),
                    ),
                  ],
                  const Spacer(),
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFB1B3B9),
                      BlendMode.srcIn,
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0),
                      child: const Image(
                        image: AssetImage('assets/images/volunteer/b.png'),
                        width: 4.89,
                        height: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  static const _items = <({
    String iconPath,
    double iconWidth,
    double iconHeight,
    String label,
  })>[
    (
      iconPath: 'assets/images/설정.png',
      iconWidth: 16,
      iconHeight: 16,
      label: '계정 설정',
    ),
    (
      iconPath: 'assets/images/벨 아이콘.png',
      iconWidth: 11.75,
      iconHeight: 12.74,
      label: '알림 설정',
    ),
    (
      iconPath: 'assets/images/활동 내역 관리 아이콘.png',
      iconWidth: 15,
      iconHeight: 15,
      label: '활동 내역 관리',
    ),
    (
      iconPath: 'assets/images/소셜 아이콘.png',
      iconWidth: 14,
      iconHeight: 14,
      label: '소셜 로그인 연동 관리',
    ),
    (
      iconPath: 'assets/images/개인정보 아이콘.png',
      iconWidth: 14,
      iconHeight: 14,
      label: '개인정보 처리방침 / 이용약관',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 354,
        height: 267,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8EAEE), width: 1),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: const Text(
                '설정',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 20 / 15,
                  letterSpacing: 0,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
            for (var i = 0; i < _items.length; i++)
              _SettingsRow(
                iconPath: _items[i].iconPath,
                iconWidth: _items[i].iconWidth,
                iconHeight: _items[i].iconHeight,
                label: _items[i].label,
                height: i == _items.length - 1 ? 49 : 42,
                showBottomBorder: i < _items.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconPath,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    required this.height,
    required this.showBottomBorder,
  });

  final String iconPath;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final double height;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFE8EAEE), width: 1),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconPath,
                    width: iconWidth,
                    height: iconHeight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 20 / 13,
                    letterSpacing: 0,
                    color: Color(0xFF636E72),
                  ),
                ),
              ),
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFFB1B3B9),
                  BlendMode.srcIn,
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: const Image(
                    image: AssetImage('assets/images/volunteer/b.png'),
                    width: 4.89,
                    height: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
