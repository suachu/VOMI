import 'dart:math' as math;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/volunteer_item.dart';
import '../services/volunteer_api.dart';
import '../services/volunteer_parser.dart';
import 'volunteer_detail_screen.dart';

class VolunteerListScreen extends StatefulWidget {
  final String serviceKey;
  const VolunteerListScreen({super.key, required this.serviceKey});

  @override
  State<VolunteerListScreen> createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen> {
  static const int _pageSize = 50;
  static const double _topBarHeight = 150;
  final _api = VolunteerApi();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _loading = true;
  bool _loadingMore = false;
  bool _isSearchFocused = false;
  bool _showFilterSheet = false;
  int _selectedFilterTab = 0;
  String? _selectedRegion;
  String? _errorMessage;
  int _pageNo = 1;
  int? _totalCount;
  String _keyword = '';
  List<VolunteerItem> _items = [];
  VolunteerItem? _topPickItem;
  static const List<String> _filterTabs = [
    '봉사지역',
    '봉사분야',
    '활동구분',
    '봉사대상',
    '모집상태',
    '봉사기간',
    '봉사자유형',
  ];

  static const List<String> _regionOptions = [
    '전체',
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
  ];

  static const Map<String, List<String>> _regionDistrictOptions = {
    '서울특별시': ['종로구', '중구', '용산구', '성동구', '광진구', '동대문구', '강남구', '송파구'],
    '부산광역시': ['중구', '서구', '동구', '영도구', '부산진구', '해운대구', '사하구'],
    '대구광역시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구'],
    '인천광역시': ['중구', '동구', '미추홀구', '연수구', '남동구', '부평구', '서구'],
    '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    '세종특별자치시': ['세종시'],
    '경기도': ['수원시', '성남시', '고양시', '용인시', '화성시', '안산시', '부천시'],
  };

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  DateTime _latestBaseDate(VolunteerItem v) {
    return v.noticeStart ?? v.programStart ?? DateTime(1970, 1, 1);
  }

  List<VolunteerItem> _sortLatestFirst(List<VolunteerItem> items) {
    final sorted = List<VolunteerItem>.from(items);
    sorted.sort((a, b) => _latestBaseDate(b).compareTo(_latestBaseDate(a)));
    return sorted;
  }

  List<VolunteerItem> _sortDeadlineFirst(List<VolunteerItem> items) {
    final sorted = List<VolunteerItem>.from(items);
    sorted.sort((a, b) {
      final ad = _dday(a.noticeEnd);
      final bd = _dday(b.noticeEnd);

      // 마감 지난 항목은 뒤로
      final aExpired = ad != null && ad < 0;
      final bExpired = bd != null && bd < 0;
      if (aExpired != bExpired) return aExpired ? 1 : -1;

      // 마감 정보 없는 항목은 뒤로
      if (ad == null && bd != null) return 1;
      if (ad != null && bd == null) return -1;
      if (ad == null && bd == null) {
        return _latestBaseDate(b).compareTo(_latestBaseDate(a));
      }

      // 남은 일수 적은 순(임박 순)
      final cmp = ad!.compareTo(bd!);
      if (cmp != 0) return cmp;
      return _latestBaseDate(b).compareTo(_latestBaseDate(a));
    });
    return sorted;
  }

  List<VolunteerItem> _sortItemsByContext(List<VolunteerItem> items) {
    if (_keyword.isNotEmpty) return _sortDeadlineFirst(items);
    return _sortLatestFirst(items);
  }

  int _safeRecruit(VolunteerItem v) => v.recruitTotal ?? 999999;

  int _deadlinePriority(VolunteerItem v) {
    final d = _dday(v.noticeEnd);
    if (d == null) return 999999;
    if (d < 0) return 999999 + d.abs(); // 마감 지난 건 뒤로
    return d; // 작을수록 임박
  }

  VolunteerItem? _pickTopPick(List<VolunteerItem> items) {
    if (items.isEmpty) return null;
    final sorted = List<VolunteerItem>.from(items);
    sorted.sort((a, b) {
      final aExpired = (_dday(a.noticeEnd) ?? 999999) < 0;
      final bExpired = (_dday(b.noticeEnd) ?? 999999) < 0;
      if (aExpired != bExpired) return aExpired ? 1 : -1;

      // 1) 모집인원 적은 순
      final recruitCmp = _safeRecruit(a).compareTo(_safeRecruit(b));
      if (recruitCmp != 0) return recruitCmp;

      // 2) 마감 임박 순
      final deadlineCmp = _deadlinePriority(a).compareTo(_deadlinePriority(b));
      if (deadlineCmp != 0) return deadlineCmp;

      return _latestBaseDate(b).compareTo(_latestBaseDate(a));
    });
    return sorted.first;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _pageNo = 1;
      _totalCount = null;
      _items = [];
      _topPickItem = null;
    });

    try {
      final xml = await _api.fetchListXml(
        serviceKey: widget.serviceKey,
        pageNo: _pageNo,
        numOfRows: _pageSize,
        keyword: _keyword,
      );
      final items = parseVolunteerList(xml);
      final total = parseTotalCount(xml);

      setState(() {
        // 추천 봉사 기준: 모집인원 적고, 마감 임박한 항목 우선
        _topPickItem = _pickTopPick(items);
        _items = _sortItemsByContext(items);
        _totalCount = total;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore) return;
    if (_totalCount != null && _items.length >= _totalCount!) return;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _pageNo + 1;
      final xml = await _api.fetchListXml(
        serviceKey: widget.serviceKey,
        pageNo: nextPage,
        numOfRows: _pageSize,
        keyword: _keyword,
      );
      final moreItems = parseVolunteerList(xml);
      final total = parseTotalCount(xml);

      setState(() {
        _pageNo = nextPage;
        _items.addAll(moreItems);
        _items = _sortItemsByContext(_items);
        _totalCount = total ?? _totalCount;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loadingMore = false;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed == _keyword) return;
    _keyword = trimmed;
    _loadFirstPage();
  }

  void _resetSearchToInitial() {
    if (!_isSearchFocused &&
        _keyword.isEmpty &&
        _searchController.text.trim().isEmpty) {
      return;
    }
    _searchController.clear();
    _keyword = '';
    _searchFocusNode.unfocus();
    _loadFirstPage();
  }

  List<String> _filterOptionsForTab() {
    if (_selectedFilterTab == 0) {
      if (_selectedRegion != null) {
        return _regionDistrictOptions[_selectedRegion!] ?? const ['정보 없음'];
      }
      return _regionOptions;
    }
    return const ['전체'];
  }

  List<String> _cityOptionsForFilter() {
    return _regionOptions;
  }

  List<String> _districtOptionsForFilter() {
    final city = _selectedRegion ?? '서울특별시';
    if (city == '전체') return const ['전체'];
    return _regionDistrictOptions[city] ?? const ['정보 없음'];
  }

  // ----------------- format helpers -----------------
  String _formatDate(DateTime? d) {
    if (d == null) return '0000.00.00';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String _formatPeriod(DateTime? s, DateTime? e) {
    return '${_formatDate(s)} ~ ${_formatDate(e)}';
  }

  int? _dday(DateTime? noticeEnd) {
    if (noticeEnd == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(noticeEnd.year, noticeEnd.month, noticeEnd.day);
    return end.difference(today).inDays;
  }

  String _ddayLabel(int? d) {
    if (d == null) return '마감 정보 없음';
    if (d < 0) return '마감됨';
    if (d == 0) return '마감 D-day';
    return '마감 D-$d';
  }

  String _illustrationAssetForTitle(String title, String id) {
    final t = title.toLowerCase();
    if (t.contains('급식') ||
        t.contains('배식') ||
        t.contains('조리') ||
        t.contains('식당')) {
      final idx = (id.hashCode.abs() % 2) + 1;
      return 'assets/images/volunteer/illus_school$idx.png';
    }
    if (t.contains('환경') ||
        t.contains('쓰레기') ||
        t.contains('쓰줍') ||
        t.contains('플로깅')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_eco$idx.png';
    }
    if (t.contains('교육') || t.contains('멘토') || t.contains('학습')) {
      final idx = (id.hashCode.abs() % 2) + 1;
      return 'assets/images/volunteer/illus_school$idx.png';
    }
    if (t.contains('요양') ||
        t.contains('요양원') ||
        t.contains('노인') ||
        t.contains('어르신') ||
        t.contains('양로원')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_care$idx.png';
    }
    if (t.contains('동물') ||
        t.contains('유기') ||
        t.contains('강아지') ||
        t.contains('유기견')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_animal$idx.png';
    }
    if (t.contains('장애') ||
        t.contains('장애인') ||
        t.contains('발달') ||
        t.contains('특수')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_people$idx.png';
    }
    if (t.contains('아이') ||
        t.contains('아동') ||
        t.contains('어린이') ||
        t.contains('유아') ||
        t.contains('청소년') ||
        t.contains('초등') ||
        t.contains('중등') ||
        t.contains('영유아') ||
        t.contains('보육') ||
        t.contains('돌봄')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_child$idx.png';
    }
    if (t.contains('전화') ||
        t.contains('콜') ||
        t.contains('상담') ||
        t.contains('통화') ||
        t.contains('안부')) {
      final idx = (id.hashCode.abs() % 2) + 1;
      return 'assets/images/volunteer/illus_call$idx.png';
    }
    if (t.contains('문화') || t.contains('행사') || t.contains('축제')) {
      final idx = (id.hashCode.abs() % 4) + 1;
      return 'assets/images/volunteer/illus_people$idx.png';
    }
    final idx = (id.hashCode.abs() % 4) + 1;
    return 'assets/images/volunteer/illus_child$idx.png';
  }

  // ----------------- UI parts -----------------
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 60),
      child: Column(
        children: [
          // 검색바
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 311,
              height: 42,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFF636E72)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        cursorColor: const Color(0xFF0A0A0A),
                        onSubmitted: (value) {
                          _onSearchSubmitted(value);
                        },
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                            left: 2,
                            top: 10.5,
                            bottom: 10.5,
                          ),
                          border: InputBorder.none,
                          hintText: '활동 이름, 모집기관 등을 입력하세요',
                          hintStyle: TextStyle(
                            color: Color(0xFFA9A9A9),
                            fontSize: 14,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!_isSearchFocused) const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ✅ 카드 (Figma 스타일 기반)
  Widget _volunteerCard({
    required BuildContext context,
    required VolunteerItem v,
    required bool isTopPick,
  }) {
    final d = _dday(v.noticeEnd);
    final dLabel = _ddayLabel(d);

    return SizedBox(
      width: 360,
      height: 196,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VolunteerDetailScreen(
                  item: v,
                  serviceKey: widget.serviceKey,
                ),
              ),
            );
          },
          child: Container(
            width: 360,
            height: 196,
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: isTopPick
                    ? const BorderSide(width: 1, color: Color(0xFFC1FFEA))
                    : BorderSide.none,
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SizedBox(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 왼쪽 이미지 자리 (제목 기반 일러스트)
                  Container(
                    width: 128,
                    height: 180,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _illustrationAssetForTitle(v.title, v.id),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF0F3F5),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFFB0BEC5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // TopPick이면 추천 봉사 뱃지
                  if (isTopPick)
                    Positioned(
                      left: 5,
                      top: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
                            decoration: BoxDecoration(
                              color: const Color(0x9900FFAB),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 45,
                              height: 14,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '추천 봉사',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard Variable',
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 마감 D-?
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF3FCFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dLabel,
                        style: const TextStyle(
                          color: Color(0xFF00A4DE),
                          fontSize: 13,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // 제목
                  Positioned(
                    left: 146,
                    top: 42,
                    child: SizedBox(
                      width: 172,
                      height: 58,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          v.title.isEmpty ? 'TITLE' : v.title,
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          strutStyle: const StrutStyle(
                            fontSize: 16,
                            height: 1.2,
                            forceStrutHeight: true,
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Location
                  Positioned(
                    left: 146,
                    top: 139,
                    child: SizedBox(
                      width: 13,
                      height: 13,
                      child: Image.asset(
                        'assets/images/volunteer/Iocation.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 163,
                    top: 140,
                    right: 8,
                    child: Text(
                      v.place.isEmpty ? 'Location' : v.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 11,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                  ),

                  // Label + 기간
                  Positioned(
                    left: 146,
                    top: 158,
                    child: SizedBox(
                      width: 13,
                      height: 13,
                      child: Image.asset(
                        'assets/images/volunteer/time.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 163,
                    top: 159,
                    child: Text(
                      '모집기간',
                      style: TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 11,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 210,
                    top: 159,
                    right: 8,
                    child: Text(
                      _formatPeriod(v.noticeStart, v.noticeEnd),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 11,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: 0,
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

  @override
  Widget build(BuildContext context) {
    final isSearchState =
        _isSearchFocused ||
        _keyword.isNotEmpty ||
        _searchController.text.trim().isNotEmpty;
    final showSearchError =
        isSearchState &&
        !_loading &&
        _keyword.isNotEmpty &&
        (_errorMessage != null || _items.isEmpty);
    final showListInSearchState =
        isSearchState &&
        !_loading &&
        _keyword.isNotEmpty &&
        _errorMessage == null &&
        _items.isNotEmpty;
    // ✅ TopPick 1개 + 나머지
    final top = (!isSearchState) ? _topPickItem : null;
    final rest = top == null
        ? _items
        : _items.where((v) => v.id != top.id).toList(growable: false);

    return Scaffold(
      backgroundColor: isSearchState ? Colors.white : const Color(0xFFF9F8F3),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ===== 리스트 영역 (상단바 높이만큼 아래로) =====
              Positioned.fill(
                top: showListInSearchState
                    ? 120
                    : _topBarHeight, // 검색 결과 리스트는 검색창 하단(102) + 18
                child: (isSearchState && !showListInSearchState)
                    ? const SizedBox.shrink()
                    : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_errorMessage != null
                          ? Center(child: Text('에러: $_errorMessage'))
                          : ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(21, 0, 21, 40),
                              children: [
                                if (showListInSearchState)
                                  ..._items.map(
                                    (v) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _volunteerCard(
                                        context: context,
                                        v: v,
                                        isTopPick: false,
                                      ),
                                    ),
                                  )
                                else ...[
                                  if (top != null) ...[
                                    _volunteerCard(
                                      context: context,
                                      v: top,
                                      isTopPick: true,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  ...rest.map(
                                    (v) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _volunteerCard(
                                        context: context,
                                        v: v,
                                        isTopPick: false,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_loadingMore)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            )),
              ),

              // ===== 상단바 =====
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  color: isSearchState ? Colors.white : const Color(0xFFF9F8F3),
                  child: _topBar(),
                ),
              ),

              // ===== 검색 아이콘 (검색창 바깥 배치) =====
              Positioned(
                left: 297,
                top: 70,
                child: GestureDetector(
                  onTap: () {
                    if (_searchController.text.isNotEmpty) {
                      _onSearchSubmitted(_searchController.text);
                    } else {
                      _searchFocusNode.requestFocus();
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Image.asset(
                        'assets/images/volunteer/search.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 351,
                top: 68,
                child:
                    (_isSearchFocused ||
                        _searchController.text.trim().isNotEmpty ||
                        _keyword.isNotEmpty)
                    ? GestureDetector(
                        onTap: _resetSearchToInitial,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 27,
                          height: 27,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 4.13,
                                top: 4.13,
                                child: SizedBox(
                                  width: 18.73104476928711,
                                  height: 18.73104476928711,
                                  child: Image.asset(
                                    'assets/images/volunteer/X.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 22.5,
                        height: 20.64,
                        child: Image.asset(
                          'assets/images/volunteer/heart.png',
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              if (!isSearchState)
                Positioned(
                  left: 24,
                  top: 114,
                  child: GestureDetector(
                    onTap: () => setState(() => _showFilterSheet = true),
                    child: SizedBox(
                      width: 45,
                      height: 16,
                      child: Text(
                        '필터보기',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 13,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isSearchState)
                Positioned(
                  left: 79,
                  top: 120,
                  child: GestureDetector(
                    onTap: () => setState(() => _showFilterSheet = true),
                    child: SizedBox(
                      width: 8,
                      height: 4,
                      child: Image.asset(
                        'assets/images/volunteer/v.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              if (!isSearchState && _showFilterSheet) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showFilterSheet = false),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: const Color(0x33000000), // #000000, 20%
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 399,
                  child: Center(
                    child: Container(
                      width: 402,
                      height: 474,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCFCFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 24, 30, 18),
                            child: Row(
                              children: [
                                const Text(
                                  '필터',
                                  style: TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 40 * 0.44,
                                    fontFamily: 'Pretendard Variable',
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _showFilterSheet = false),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Image.asset(
                                      'assets/images/volunteer/X.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              itemCount: _filterTabs.length,
                              itemBuilder: (context, index) {
                                final selected = index == _selectedFilterTab;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedFilterTab = index;
                                    if (index != 0) _selectedRegion = null;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (selected)
                                          const Center(
                                            child: Text(
                                              '•',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF2D3436),
                                                fontSize: 12,
                                                height: 1.0,
                                              ),
                                            ),
                                          )
                                        else
                                          const SizedBox(height: 12),
                                        Text(
                                          _filterTabs[index],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: selected
                                                ? const Color(0xFF2D3436)
                                                : const Color(0xFFB4B8BC),
                                            fontSize: 26 * 0.54,
                                            fontFamily: 'Pretendard Variable',
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE5E7EA),
                          ),
                          Expanded(
                            child: _selectedFilterTab == 0
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 18,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 331,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 154,
                                              child: ListView.separated(
                                                itemCount:
                                                    _cityOptionsForFilter()
                                                        .length,
                                                separatorBuilder:
                                                    (context, index) =>
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                itemBuilder: (context, index) {
                                                  final city =
                                                      _cityOptionsForFilter()[index];
                                                  final selected =
                                                      (_selectedRegion ??
                                                          '서울특별시') ==
                                                      city;
                                                  return GestureDetector(
                                                    onTap: () => setState(
                                                      () => _selectedRegion =
                                                          city,
                                                    ),
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    child: Text(
                                                      city,
                                                      style: TextStyle(
                                                        color: selected
                                                            ? const Color(
                                                                0xFF2D3436,
                                                              )
                                                            : const Color(
                                                                0xFF5E666D,
                                                              ),
                                                        fontSize: 34 * 0.48,
                                                        fontFamily:
                                                            'Pretendard Variable',
                                                        fontWeight: selected
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width: 154,
                                              child: ListView.separated(
                                                itemCount:
                                                    _districtOptionsForFilter()
                                                        .length,
                                                separatorBuilder:
                                                    (context, index) =>
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                itemBuilder: (context, index) {
                                                  final district =
                                                      _districtOptionsForFilter()[index];
                                                  return Text(
                                                    district,
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle(
                                                      color: Color(0xFF5E666D),
                                                      fontSize: 34 * 0.48,
                                                      fontFamily:
                                                          'Pretendard Variable',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.0,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      84,
                                      16,
                                      38,
                                      18,
                                    ),
                                    itemCount: _filterOptionsForTab().length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 20),
                                    itemBuilder: (context, index) {
                                      final text =
                                          _filterOptionsForTab()[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: const TextStyle(
                                                color: Color(0xFF5E666D),
                                                fontSize: 34 * 0.48,
                                                fontFamily:
                                                    'Pretendard Variable',
                                                fontWeight: FontWeight.w500,
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                          const Text(
                                            '›',
                                            style: TextStyle(
                                              color: Color(0xFFB5B9BE),
                                              fontSize: 24,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (showSearchError)
                Positioned(
                  left: 124,
                  top: 191,
                  child: Opacity(
                    opacity: 0.75,
                    child: Transform.rotate(
                      angle: 6.57 * math.pi / 180,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 141.00000172653594,
                        height: 127.00000155510683,
                        child: Image.asset(
                          'assets/images/volunteer/Error.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showSearchError)
                const Positioned(
                  left: 105,
                  top: 333,
                  child: SizedBox(
                    width: 190,
                    height: 72,
                    child: Center(
                      child: Text(
                        '앗!\n검색 결과를 찾을 수 없어요.\n다른 검색어를 입력해 주시겠나요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF2D3436),
                          fontSize: 18,
                          fontFamily: 'Ownglyph PDH',
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                          height: 24 / 18,
                          letterSpacing: 0,
                        ),
                      ),
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
