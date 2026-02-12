import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/views/main/journal/emotion_select_screen.dart';
import 'package:vomi/views/main/journal/journal_entry.dart';
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

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await JournalStorage.loadEntries(_uid);
    if (!mounted) return;
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _openWriteFlow() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EmotionSelectScreen()));
    if (saved == true) {
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : '이름 없음';
    final visibleEntries = _visibleEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 450,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 4,
                        top: 138,
                        child: Container(
                          width: 345,
                          height: 289,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                      const Positioned(
                        left: 4,
                        top: 68,
                        child: Text(
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
                        left: 4,
                        top: 92,
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
                        right: 8,
                        top: 96,
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
                            const SizedBox(width: 18),
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
                        left: 16,
                        top: 158,
                        right: 16,
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE8E8E8),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: Color(0xFF8D8D8D),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
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
                        const SizedBox(height: 2),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                if (visibleEntries.isEmpty)
                  Container(
                    width: 354,
                    height: 166,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        _DiaryPreviewCard(entry: visibleEntries[i]),
                        if (i != visibleEntries.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            left: 304,
            top: 715,
            child: GestureDetector(
              onTap: _openWriteFlow,
              child: Container(
                constraints: const BoxConstraints(minHeight: 43),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFACD7E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
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
  const _DiaryPreviewCard({required this.entry});

  final JournalEntry entry;

  static const _scopeLabel = {
    '비공개': '비공개',
    '친구공개': '친구공개',
    '전체공개': '전체공개',
  };

  @override
  Widget build(BuildContext context) {
    final dt =
        '${entry.createdAt.year.toString().padLeft(4, '0')}.${entry.createdAt.month.toString().padLeft(2, '0')}.${entry.createdAt.day.toString().padLeft(2, '0')}';
    final hasImage = entry.imagePaths.isNotEmpty;
    return Container(
      width: 354,
      height: 166,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    height: 21.04 / 18,
                    letterSpacing: 0,
                    color: Color(0xFF2B3137),
                  ),
                ),
              ),
              _EmotionBadge(index: entry.emotionIndex),
            ],
          ),
          const SizedBox(height: 0.5),
          Text(
            '$dt · ${_scopeLabel[entry.scope] ?? '전체공개'}',
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 11,
              fontWeight: FontWeight.w300,
              height: 18.03 / 11,
              letterSpacing: 0,
              color: Color(0xFFB1B3B9),
            ),
          ),
          if (entry.location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9DA7AE),
              ),
            ),
            const SizedBox(height: 2),
          ] else ...[
            const SizedBox(height: 2),
          ],
          Row(
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
                    height: 24.05 / 13,
                    letterSpacing: 0,
                    color: Color(0xFF636E72),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(entry.imagePaths.first),
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 22,
                          color: Color(0xFF98A4AD),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Image(
                image: AssetImage('assets/images/love2.png'),
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.likeCount}',
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 12,
                  color: Color(0xFF9AA2A9),
                ),
              ),
              const SizedBox(width: 18),
              const Image(
                image: AssetImage('assets/images/chat.png'),
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
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
    const fillColors = [
      Color(0xFFFFE8D2),
      Color(0xFFDDF6F3),
      Color(0xFFDBF1F6),
      Color(0xFFE1F4E5),
      Color(0xFFFFF7D8),
    ];
    final safe = index.clamp(0, 4) as int;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: fillColors[safe],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          imagePaths[safe],
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
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
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
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
          sixWeekMonthsEnforced: true,
          availableGestures: AvailableGestures.none,
          rowHeight: 42,
          selectedDayPredicate: (day) =>
              selectedDay != null &&
              day.year == month.year &&
              day.month == month.month &&
              day.day == selectedDay,
          enabledDayPredicate: (day) =>
              day.year == month.year && day.month == month.month,
          onDaySelected: (selected, focused) {
            if (selected.month != month.month || selected.year != month.year) {
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
    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD9F0F9)
              : isMarked
              ? const Color(0xFFEFF8FC)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF8EC8DF),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({required this.isRight});

  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final arrow = ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFF6D767D),
        BlendMode.srcIn,
      ),
      child: const Image(
        image: AssetImage('assets/images/volunteer/b.png'),
        width: 8,
        height: 16,
        fit: BoxFit.contain,
      ),
    );

    if (!isRight) return arrow;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0),
      child: arrow,
    );
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFB0B8BF),
          ),
        ),
      ),
    );
  }
}
