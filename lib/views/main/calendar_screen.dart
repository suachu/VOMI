import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vomi/core/layout/figma_scale.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/post_visibility_registry.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/bottom_nav.dart';
import 'package:vomi/views/main/journal/emotion_select_screen.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';
import 'package:vomi/views/main/journal/journal_write_screen.dart';
import 'package:vomi/views/main/journal/journal_storage.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  List<JournalEntry> _entries = const [];
  int? _selectedDay;
  final Set<String> _likedEntryIds = <String>{};
  final UserProfileLocalService _profileService =
      const UserProfileLocalService();
  String _displayName = '이름 없음';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _loadProfile();
    _loadEntries();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _profileService.ensure(user);
    if (!mounted) return;
    setState(() {
      _displayName = profile.name;
    });
  }

  Future<void> _loadEntries() async {
    final entries = await JournalStorage.loadEntries(_uid);
    if (!mounted) return;
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _openWriteFlow() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmotionSelectScreen()),
    );
    if (saved == true) {
      await _loadProfile();
      await _loadEntries();
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
      _selectedDay = null;
    });
  }

  Set<int> get _markedDays {
    return _entries
        .where(
          (e) =>
              e.createdAt.year == _displayedMonth.year &&
              e.createdAt.month == _displayedMonth.month,
        )
        .map((e) => e.createdAt.day)
        .toSet();
  }

  List<JournalEntry> get _visibleEntries {
    final monthEntries = _entries.where(
      (e) =>
          e.createdAt.year == _displayedMonth.year &&
          e.createdAt.month == _displayedMonth.month,
    );
    if (_selectedDay == null) {
      return monthEntries.toList();
    }
    return monthEntries.where((e) => e.createdAt.day == _selectedDay).toList();
  }

  @override
  Widget build(BuildContext context) {
    final f = FigmaScale.fromContext(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Text(
              '로그인이 필요해요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final displayName = _displayName;
    final visibleEntries = _visibleEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(f.x(24), 0, f.x(24), f.y(140)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: f.y(450),
                  child: Stack(
                    children: [
                      Positioned(
                        left: f.x(4),
                        top: f.y(138),
                        child: Container(
                          width: f.x(345),
                          height: f.y(289),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(f.x(20)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: f.x(4),
                        top: f.y(68),
                        child: const Text(
                          '날짜를 눌러 나의 봉사기록을 확인해보세요.',
                          style: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 24 / 14,
                            color: Color(0xFF6B747B),
                          ),
                        ),
                      ),
                      Positioned(
                        left: f.x(4),
                        top: f.y(92),
                        child: Text(
                          '${_displayedMonth.month}월 일지',
                          style: const TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 30 / 20,
                            color: Color(0xFF2B3339),
                          ),
                        ),
                      ),
                      Positioned(
                        right: f.x(8),
                        top: f.y(96),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _changeMonth(-1),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: _CalendarArrow(isRight: false),
                              ),
                            ),
                            SizedBox(width: f.x(22)),
                            GestureDetector(
                              onTap: () => _changeMonth(1),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: _CalendarArrow(isRight: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: f.x(16),
                        top: f.y(150),
                        right: f.x(16),
                        bottom: f.y(35),
                        child: _MonthCalendarCard(
                          month: _displayedMonth,
                          markedDays: _markedDays,
                          selectedDay: _selectedDay,
                          onTapDay: (day) {
                            setState(() {
                              _selectedDay = _selectedDay == day ? null : day;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: f.y(18)),
                Row(
                  children: [
                    CircleAvatar(
                      radius: f.x(30),
                      backgroundColor: const Color(0xFFE8E8E8),
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: Color(0xFF8D8D8D),
                            )
                          : null,
                    ),
                    SizedBox(width: f.x(14)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: 0,
                            color: Color(0xFF20282E),
                          ),
                        ),
                        SizedBox(height: f.y(2)),
                        Text(
                          '게시글 ${_entries.length}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7A838A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: f.y(16)),
                Text(
                  '$displayName님의 지난 일기',
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 42 / 25,
                    letterSpacing: 0,
                    color: Color(0xFF283035),
                  ),
                ),
                SizedBox(height: f.y(16)),
                if (visibleEntries.isEmpty)
                  Container(
                    width: f.x(354),
                    height: f.y(166),
                    padding: EdgeInsets.symmetric(
                      horizontal: f.x(20),
                      vertical: f.y(20),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(f.x(20)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8.02,
                          offset: Offset(0, 4.01),
                        ),
                      ],
                    ),
                    child: const Text(
                      '아직 작성한 일기가 없어요.\n글쓰기 버튼으로 첫 일기를 작성해보세요!',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF7A838A),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < visibleEntries.length; i++) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context)
                                .push<_PostDetailResult>(
                                  MaterialPageRoute(
                                    builder: (_) => _PostDetailScreen(
                                      entry: visibleEntries[i],
                                      isLiked: _likedEntryIds.contains(
                                        visibleEntries[i].id,
                                      ),
                                      displayLikeCount:
                                          visibleEntries[i].likeCount +
                                          (_likedEntryIds.contains(
                                                visibleEntries[i].id,
                                              )
                                              ? 1
                                              : 0),
                                    ),
                                  ),
                                )
                                .then((result) async {
                                  if (result == null) return;
                                  await _loadProfile();
                                  await _loadEntries();
                                });
                          },
                          child: _DiaryPreviewCard(
                            entry: visibleEntries[i],
                            isLiked: _likedEntryIds.contains(
                              visibleEntries[i].id,
                            ),
                            displayLikeCount:
                                visibleEntries[i].likeCount +
                                (_likedEntryIds.contains(visibleEntries[i].id)
                                    ? 1
                                    : 0),
                            onTapLike: () {
                              final id = visibleEntries[i].id;
                              setState(() {
                                if (_likedEntryIds.contains(id)) {
                                  _likedEntryIds.remove(id);
                                } else {
                                  _likedEntryIds.add(id);
                                }
                              });
                            },
                          ),
                        ),
                        if (i != visibleEntries.length - 1)
                          SizedBox(height: f.y(12)),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            left: f.x(304),
            top: f.y(715),
            child: GestureDetector(
              onTap: _openWriteFlow,
              child: Container(
                constraints: BoxConstraints(minHeight: f.y(43)),
                padding: EdgeInsets.symmetric(
                  horizontal: f.x(10),
                  vertical: f.y(9),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFACD7E6),
                  borderRadius: BorderRadius.circular(f.x(20)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      '글쓰기',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 21.04 / 15,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryPreviewCard extends StatelessWidget {
  const _DiaryPreviewCard({
    required this.entry,
    required this.isLiked,
    required this.displayLikeCount,
    required this.onTapLike,
  });

  final JournalEntry entry;
  final bool isLiked;
  final int displayLikeCount;
  final VoidCallback onTapLike;

  static const _scopeLabel = {'비공개': '비공개', '친구공개': '친구공개', '전체공개': '전체공개'};

  @override
  Widget build(BuildContext context) {
    final f = FigmaScale.fromContext(context);
    final dt =
        '${entry.createdAt.year.toString().padLeft(4, '0')}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.day.toString().padLeft(2, '0')}';
    final hasImage = entry.imagePaths.isNotEmpty;
    final thumb = f.x(60);
    return Container(
      width: f.x(354),
      height: f.y(166),
      padding: EdgeInsets.fromLTRB(f.x(20), f.y(16), f.x(20), f.y(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(f.x(20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8.02,
            offset: Offset(0, 4.01),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: 0,
                    color: Color(0xFF2B3137),
                  ),
                ),
              ),
              _EmotionBadge(index: entry.emotionIndex),
            ],
          ),
          Text(
            '$dt · ${_scopeLabel[entry.scope] ?? '전체공개'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 11,
              fontWeight: FontWeight.w300,
              height: 1.0,
              letterSpacing: 0,
              color: Color(0xFFB1B3B9),
            ),
          ),
          SizedBox(height: f.y(10)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final raw = constraints.maxHeight;
                final contentHeight = raw.isFinite ? raw : thumb;
                final thumbSize = hasImage
                    ? (contentHeight < thumb ? contentHeight : thumb)
                    : 0.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          letterSpacing: 0,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ),
                    if (hasImage) ...[
                      SizedBox(width: f.x(2)),
                      Transform.translate(
                        offset: Offset(0, -f.y(3)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(f.x(10)),
                          child: _journalImageFromPath(
                            entry.imagePaths.first,
                            width: thumbSize,
                            height: thumbSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          SizedBox(height: f.y(4)),
          Row(
            children: [
              GestureDetector(
                onTap: onTapLike,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: isLiked
                        ? const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Color(0xFFFF5A70),
                          )
                        : const Image(
                            image: AssetImage('assets/images/love2.png'),
                            width: 16,
                            height: 16,
                          ),
                  ),
                ),
              ),
              SizedBox(width: f.x(4)),
              Text(
                '$displayLikeCount',
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 12,
                  color: Color(0xFF9AA2A9),
                ),
              ),
              SizedBox(width: f.x(18)),
              const Image(
                image: AssetImage('assets/images/chat.png'),
                width: 16,
                height: 16,
              ),
              SizedBox(width: f.x(4)),
              Text(
                '${entry.commentCount}',
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 12,
                  color: Color(0xFF9AA2A9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmotionBadge extends StatelessWidget {
  const _EmotionBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const imagePaths = [
      'assets/images/love.png',
      'assets/images/emotion_neutral.png',
      'assets/images/sad.png',
      'assets/images/emotion_proud.png',
      'assets/images/emotion_happy.png',
    ];
    final safe = index.clamp(0, 4);
    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _emotionFillColor(safe),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: Image.asset(imagePaths[safe], alignment: Alignment.center),
        ),
      ),
    );
  }
}

class _PostDetailScreen extends StatelessWidget {
  const _PostDetailScreen({
    required this.entry,
    required this.isLiked,
    required this.displayLikeCount,
  });

  final JournalEntry entry;
  final bool isLiked;
  final int displayLikeCount;

  static const _scopeLabel = {'비공개': '비공개', '친구공개': '친구공개', '전체공개': '전체공개'};

  Future<void> _showMoreMenu(
    BuildContext context,
    BuildContext anchorContext,
  ) async {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonBox = anchorContext.findRenderObject() as RenderBox;
    final buttonOffset = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    const menuWidth = 176.0;
    final left = (buttonOffset.dx + buttonBox.size.width - menuWidth).clamp(
      8.0,
      overlayBox.size.width - menuWidth - 8.0,
    );
    final menuRect = Rect.fromLTWH(
      left,
      buttonOffset.dy + buttonBox.size.height + 6,
      menuWidth,
      0,
    );

    final action = await showMenu<_PostMenuAction>(
      context: context,
      color: const Color(0xFFF7F8F9),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromRect(menuRect, Offset.zero & overlayBox.size),
      items: const [
        PopupMenuItem<_PostMenuAction>(
          value: _PostMenuAction.edit,
          child: _PostMenuItemContent(
            label: '수정하기',
            icon: Icons.edit_outlined,
            color: Color(0xFF636E72),
          ),
        ),
        PopupMenuItem<_PostMenuAction>(
          value: _PostMenuAction.copyUrl,
          child: _PostMenuItemContent(
            label: 'URL 복사',
            icon: Icons.link_rounded,
            color: Color(0xFF636E72),
          ),
        ),
        PopupMenuItem<_PostMenuAction>(
          value: _PostMenuAction.delete,
          child: _PostMenuItemContent(
            label: '삭제하기',
            icon: Icons.delete_outline_rounded,
            color: Color(0xFFFF4646),
          ),
        ),
      ],
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _PostMenuAction.edit:
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => JournalWriteScreen(
              selectedEmotionIndex: entry.emotionIndex,
              initialEntry: entry,
            ),
          ),
        );
        if (!context.mounted) return;
        if (saved == true) {
          PostVisibilityRegistry.showEntry(entry);
          Navigator.of(context).pop(_PostDetailResult.edited);
        }
        break;
      case _PostMenuAction.copyUrl:
        await Clipboard.setData(
          ClipboardData(text: 'https://vomi.app/journal/${entry.id}'),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('URL을 복사했어요.')));
        break;
      case _PostMenuAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('삭제하기'),
              content: const Text('이 게시글을 삭제할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '삭제',
                    style: TextStyle(color: Color(0xFFFF4646)),
                  ),
                ),
              ],
            );
          },
        );
        if (!context.mounted || confirmed != true) return;
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
        await JournalStorage.deleteEntry(uid, entry);
        PostVisibilityRegistry.hideEntry(entry);
        if (!context.mounted) return;
        Navigator.of(context).pop(_PostDetailResult.deleted);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FigmaScale.fromContext(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final navWScaled = screenW < BottomNavBar.navW
        ? screenW - 24
        : BottomNavBar.navW;
    final navHeight = BottomNavBar.navH * (navWScaled / BottomNavBar.navW);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = entry.authorName.trim().isNotEmpty
        ? entry.authorName.trim()
        : ((user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : '사용자');
    final ImageProvider? profileImage = user?.photoURL != null
        ? NetworkImage(user!.photoURL!)
        : null;
    final dt =
        '${entry.createdAt.year.toString().padLeft(4, '0')}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: Container(
        height: navHeight,
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: f.x(24)),
        child: Row(
          children: [
            isLiked
                ? const Icon(Icons.favorite, size: 16, color: Color(0xFFFF5A70))
                : const Image(
                    image: AssetImage('assets/images/love2.png'),
                    width: 16,
                    height: 16,
                  ),
            SizedBox(width: f.x(8)),
            Text(
              '$displayLikeCount',
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                color: Color(0xFF69747C),
              ),
            ),
            SizedBox(width: f.x(24)),
            const Image(
              image: AssetImage('assets/images/chat.png'),
              width: 16,
              height: 16,
            ),
            SizedBox(width: f.x(8)),
            Text(
              '${entry.commentCount}',
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                color: Color(0xFF69747C),
              ),
            ),
            SizedBox(width: f.x(24)),
            const Icon(Icons.send_outlined, size: 18, color: Color(0xFF69747C)),
            SizedBox(width: f.x(8)),
            const Text(
              '2',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                color: Color(0xFF69747C),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: f.y(62),
              child: Stack(
                children: [
                  Positioned(
                    left: f.x(24),
                    top: f.y(26),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Image(
                        image: AssetImage('assets/images/volunteer/b.png'),
                        width: 20,
                        height: 10,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '게시글',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: 0,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  f.x(24),
                  f.y(28),
                  f.x(24),
                  f.y(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: f.x(354),
                      padding: EdgeInsets.fromLTRB(
                        f.x(20),
                        f.y(18),
                        f.x(20),
                        f.y(20),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(f.x(20)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 8.02,
                            offset: Offset(0, 4.01),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: f.x(15),
                                backgroundColor: const Color(0xFFE8E8E8),
                                backgroundImage: profileImage,
                                child: profileImage == null
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: f.x(16),
                                        color: const Color(0xFF8D8D8D),
                                      )
                                    : null,
                              ),
                              SizedBox(width: f.x(10)),
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F272D),
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (anchorContext) => GestureDetector(
                                  onTap: () =>
                                      _showMoreMenu(context, anchorContext),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Image(
                                    image: AssetImage('assets/images/점3.png'),
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: f.y(16)),
                          SizedBox(height: f.y(12)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                    color: Color(0xFF2B3137),
                                  ),
                                ),
                              ),
                              SizedBox(width: f.x(8)),
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _emotionFillColor(entry.emotionIndex),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  _emotionImagePath(entry.emotionIndex),
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: f.y(0.5)),
                          Transform.translate(
                            offset: Offset(0, -f.y(10)),
                            child: Text(
                              '$dt · ${_scopeLabel[entry.scope] ?? '전체공개'}',
                              style: const TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFFB1B3B9),
                              ),
                            ),
                          ),
                          SizedBox(height: f.y(2)),
                          Transform.translate(
                            offset: Offset(0, -f.y(10)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Image(
                                  image: AssetImage('assets/images/location.png'),
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: f.x(4)),
                                Expanded(
                                  child: Text(
                                    entry.location.isNotEmpty
                                        ? entry.location
                                        : '위치 정보 없음',
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF7D878F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: f.y(24)),
                          Text(
                            entry.content,
                            style: const TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                              color: Color(0xFF2C343A),
                            ),
                          ),
                          if (entry.imagePaths.isNotEmpty) ...[
                            SizedBox(height: f.y(18)),
                            for (
                              var i = 0;
                              i < entry.imagePaths.length;
                              i++
                            ) ...[
                              _journalImageFromPath(
                                entry.imagePaths[i],
                                width: double.infinity,
                                height: f.y(280),
                                fit: BoxFit.cover,
                              ),
                              if (i != entry.imagePaths.length - 1)
                                SizedBox(height: f.y(16)),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PostMenuAction { edit, copyUrl, delete }

enum _PostDetailResult { edited, deleted }

class _PostMenuItemContent extends StatelessWidget {
  const _PostMenuItemContent({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        Icon(icon, size: 22, color: color),
      ],
    );
  }
}

String _emotionImagePath(int index) {
  const imagePaths = [
    'assets/images/love.png',
    'assets/images/emotion_neutral.png',
    'assets/images/sad.png',
    'assets/images/emotion_proud.png',
    'assets/images/emotion_happy.png',
  ];
  final safe = index.clamp(0, 4);
  return imagePaths[safe];
}

Color _emotionFillColor(int index) {
  const fillColors = [
    Color(0xFFFFE7D1), // heart
    Color(0xFFE5FFFA), // neutral
    Color(0xFFEFFEFF), // sad
    Color(0xFFEEFFF0), // thumbs up
    Color(0xFFFFFAE7), // smile
  ];
  final safe = index.clamp(0, 4);
  return fillColors[safe];
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.month,
    required this.markedDays,
    required this.selectedDay,
    required this.onTapDay,
  });

  final DateTime month;
  final Set<int> markedDays;
  final int? selectedDay;
  final ValueChanged<int> onTapDay;

  @override
  Widget build(BuildContext context) {
    final focusedDay = DateTime(month.year, month.month, 1);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekRows = ((firstWeekday + daysInMonth) / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const weekLabelBlock = 24.0;
        const weekGap = 6.0;
        final tableHeight = (constraints.maxHeight - weekLabelBlock - weekGap)
            .clamp(120.0, 320.0);
        final rowHeight = tableHeight / weekRows;

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: weekGap),
              child: Row(
                children: [
                  _KoreanWeekLabel('일'),
                  _KoreanWeekLabel('월'),
                  _KoreanWeekLabel('화'),
                  _KoreanWeekLabel('수'),
                  _KoreanWeekLabel('목'),
                  _KoreanWeekLabel('금'),
                  _KoreanWeekLabel('토'),
                ],
              ),
            ),
            TableCalendar<void>(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: focusedDay,
              currentDay: null,
              headerVisible: false,
              daysOfWeekVisible: false,
              calendarFormat: CalendarFormat.month,
              sixWeekMonthsEnforced: false,
              availableGestures: AvailableGestures.none,
              rowHeight: rowHeight,
              selectedDayPredicate: (day) =>
                  selectedDay != null &&
                  day.year == month.year &&
                  day.month == month.month &&
                  day.day == selectedDay,
              enabledDayPredicate: (day) =>
                  day.year == month.year && day.month == month.month,
              onDaySelected: (selected, focused) {
                if (selected.month != month.month ||
                    selected.year != month.year) {
                  return;
                }
                onTapDay(selected.day);
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                isTodayHighlighted: false,
                defaultTextStyle: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 21 / 14,
                  letterSpacing: 0,
                  color: Color(0xFF364047),
                ),
                weekendTextStyle: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 21 / 14,
                  letterSpacing: 0,
                  color: Color(0xFF364047),
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isMarked = markedDays.contains(day.day);
                  return _CalendarDayCell(
                    day: day.day,
                    isMarked: isMarked,
                    isSelected: false,
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final isMarked = markedDays.contains(day.day);
                  return _CalendarDayCell(
                    day: day.day,
                    isMarked: isMarked,
                    isSelected: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isMarked,
    required this.isSelected,
  });

  final int day;
  final bool isMarked;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isSelected || isMarked;
    final boxSize = isHighlighted ? 38.0 : 30.0;
    return Center(
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFF3FCFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 21 / 14,
                letterSpacing: 0,
                color: isMarked || isSelected
                    ? const Color(0xFF99CFE6)
                    : const Color(0xFF364047),
              ),
            ),
            if (isMarked)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8EC8DF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _journalImageFromPath(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  );
}

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({required this.isRight});

  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final arrow = ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF6D767D), BlendMode.srcIn),
      child: const Image(
        image: AssetImage('assets/images/volunteer/b.png'),
        width: 8,
        height: 16,
        fit: BoxFit.contain,
      ),
    );

    if (!isRight) return arrow;
    return Transform.flip(flipX: true, child: arrow);
  }
}

class _KoreanWeekLabel extends StatelessWidget {
  const _KoreanWeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 18 / 12,
            letterSpacing: 0,
            color: Color(0xFFB2BEC3),
          ),
        ),
      ),
    );
  }
}
