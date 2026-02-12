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
  String? _selectedDistrict;
  final Set<String> _selectedVolunteerFields = <String>{};
  final Map<String, Set<String>> _selectedOptionsByTab = <String, Set<String>>{};
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
    '재난 일감',
    '요일',
    '인정시간',
  ];

  static const List<String> _volunteerFieldOptions = [
    '전체',
    '주거환경',
    '교육',
    '농어촌 봉사',
    '환경·생태계보호',
    '지역안전·보호',
    '재난·재해',
    '기타',
    '생활편의',
    '상담·멘토링',
    '보건·의료',
    '문화·체육·예술·관광',
    '사무행정',
    '인권·공익',
    '국제협력·해외봉사',
    '자원봉사 기본교육',
  ];

  static const List<String> _activityTypeOptions = [
    '전체',
    '오프라인',
    '온라인',
    '온라인+오프라인',
  ];

  static const List<String> _targetOptions = [
    '전체',
    '장애인',
    '쪽방촌',
    '여성',
    '사회적기업',
    '기타',
    '아동·청소년',
    '노인',
    '다문화가정',
    '환경',
    '고향봉사',
  ];

  static const List<String> _recruitStateOptions = [
    '전체',
    '모집중',
    '모집완료',
  ];

  static const List<String> _periodOptions = [
    '전체',
    '당일',
    '1주일 이내',
    '1개월 이내',
    '1개월 이상',
  ];

  static const List<String> _volunteerTypeOptions = [
    '성인',
    '청소년',
  ];

  static const List<String> _disasterTaskOptions = [
    '재난일감 포함',
    '재난',
  ];

  static const List<String> _weekdayOptions = [
    '평일',
    '주말',
  ];

  static const List<String> _creditHourOptions = [
    '전체',
    '2시간',
    '4시간',
    '6시간',
    '8시간 이상',
    '1시간',
    '3시간',
    '5시간',
    '7시간',
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
    '강원특별자치도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];

  static const Map<String, List<String>> _regionDistrictOptions = {
    '서울특별시': [
      '종로구',
      '중구',
      '용산구',
      '성동구',
      '광진구',
      '동대문구',
      '중랑구',
      '성북구',
      '강북구',
      '도봉구',
      '노원구',
      '은평구',
      '서대문구',
      '마포구',
      '양천구',
      '강서구',
      '구로구',
      '금천구',
      '영등포구',
      '동작구',
      '관악구',
      '서초구',
      '강남구',
      '송파구',
      '강동구',
    ],
    '부산광역시': [
      '중구',
      '서구',
      '동구',
      '영도구',
      '부산진구',
      '동래구',
      '남구',
      '북구',
      '해운대구',
      '사하구',
      '금정구',
      '강서구',
      '연제구',
      '수영구',
      '사상구',
      '기장군',
    ],
    '대구광역시': ['중구', '동구', '서구', '남구', '북구', '수성구', '달서구', '달성군', '군위군'],
    '인천광역시': [
      '중구',
      '동구',
      '미추홀구',
      '연수구',
      '남동구',
      '부평구',
      '계양구',
      '서구',
      '강화군',
      '옹진군',
    ],
    '광주광역시': ['동구', '서구', '남구', '북구', '광산구'],
    '대전광역시': ['동구', '중구', '서구', '유성구', '대덕구'],
    '울산광역시': ['중구', '남구', '동구', '북구', '울주군'],
    '세종특별자치시': ['세종시'],
    '경기도': [
      '수원시',
      '성남시',
      '고양시',
      '용인시',
      '부천시',
      '안산시',
      '안양시',
      '남양주시',
      '화성시',
      '평택시',
      '의정부시',
      '시흥시',
      '파주시',
      '광명시',
      '김포시',
      '군포시',
      '하남시',
      '오산시',
      '양주시',
      '이천시',
      '구리시',
      '안성시',
      '의왕시',
      '포천시',
      '여주시',
      '동두천시',
      '과천시',
      '가평군',
      '양평군',
      '연천군',
    ],
    '강원특별자치도': [
      '춘천시',
      '원주시',
      '강릉시',
      '동해시',
      '태백시',
      '속초시',
      '삼척시',
      '홍천군',
      '횡성군',
      '영월군',
      '평창군',
      '정선군',
      '철원군',
      '화천군',
      '양구군',
      '인제군',
      '고성군',
      '양양군',
    ],
    '충청북도': [
      '청주시',
      '충주시',
      '제천시',
      '보은군',
      '옥천군',
      '영동군',
      '증평군',
      '진천군',
      '괴산군',
      '음성군',
      '단양군',
    ],
    '충청남도': [
      '천안시',
      '공주시',
      '보령시',
      '아산시',
      '서산시',
      '논산시',
      '계룡시',
      '당진시',
      '금산군',
      '부여군',
      '서천군',
      '청양군',
      '홍성군',
      '예산군',
      '태안군',
    ],
    '전북특별자치도': [
      '전주시',
      '군산시',
      '익산시',
      '정읍시',
      '남원시',
      '김제시',
      '완주군',
      '진안군',
      '무주군',
      '장수군',
      '임실군',
      '순창군',
      '고창군',
      '부안군',
    ],
    '전라남도': [
      '목포시',
      '여수시',
      '순천시',
      '나주시',
      '광양시',
      '담양군',
      '곡성군',
      '구례군',
      '고흥군',
      '보성군',
      '화순군',
      '장흥군',
      '강진군',
      '해남군',
      '영암군',
      '무안군',
      '함평군',
      '영광군',
      '장성군',
      '완도군',
      '진도군',
      '신안군',
    ],
    '경상북도': [
      '포항시',
      '경주시',
      '김천시',
      '안동시',
      '구미시',
      '영주시',
      '영천시',
      '상주시',
      '문경시',
      '경산시',
      '의성군',
      '청송군',
      '영양군',
      '영덕군',
      '청도군',
      '고령군',
      '성주군',
      '칠곡군',
      '예천군',
      '봉화군',
      '울진군',
      '울릉군',
    ],
    '경상남도': [
      '창원시',
      '진주시',
      '통영시',
      '사천시',
      '김해시',
      '밀양시',
      '거제시',
      '양산시',
      '의령군',
      '함안군',
      '창녕군',
      '고성군',
      '남해군',
      '하동군',
      '산청군',
      '함양군',
      '거창군',
      '합천군',
    ],
    '제주특별자치도': ['제주시', '서귀포시'],
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
    final city = _selectedRegion;
    if (city == null) return const [];
    if (city == '전체') return const ['전체'];
    final districts = _regionDistrictOptions[city] ?? const ['정보 없음'];
    return ['전체', ...districts];
  }

  List<String> get _fieldLeftColumn {
    final options = _optionsForCurrentCheckTab();
    final half = (options.length / 2).ceil();
    return options.sublist(0, half);
  }

  List<String> get _fieldRightColumn {
    final options = _optionsForCurrentCheckTab();
    final half = (options.length / 2).ceil();
    return options.sublist(half);
  }

  String get _currentTabLabel => _filterTabs[_selectedFilterTab];

  List<String> _optionsForCurrentCheckTab() {
    switch (_currentTabLabel) {
      case '봉사분야':
        return _volunteerFieldOptions;
      case '활동구분':
        return _activityTypeOptions;
      case '봉사대상':
        return _targetOptions;
      case '모집상태':
        return _recruitStateOptions;
      case '봉사기간':
        return _periodOptions;
      case '봉사자유형':
        return _volunteerTypeOptions;
      case '재난 일감':
        return _disasterTaskOptions;
      case '요일':
        return _weekdayOptions;
      case '인정시간':
        return _creditHourOptions;
      default:
        return const ['전체'];
    }
  }

  Set<String> _selectedSetForCurrentTab() {
    return _selectedOptionsByTab.putIfAbsent(_currentTabLabel, () => <String>{});
  }

  bool _isSelectedForCurrentTab(String option) {
    return _selectedSetForCurrentTab().contains(option);
  }

  void _toggleOptionForCurrentTab(String option) {
    final selectedSet = _selectedSetForCurrentTab();
    final options = _optionsForCurrentCheckTab();
    final nonAll = options.where((e) => e != '전체').toList();

    if (option == '전체') {
      if (selectedSet.contains('전체')) {
        selectedSet.clear();
      } else {
        selectedSet
          ..clear()
          ..addAll(options);
      }
      return;
    }

    selectedSet.remove('전체');
    if (selectedSet.contains(option)) {
      selectedSet.remove(option);
    } else {
      selectedSet.add(option);
      final selectedNonAllCount =
          selectedSet.where((e) => e != '전체').length;
      if (selectedNonAllCount == nonAll.length) {
        selectedSet.add('전체');
      }
    }
  }

  bool _matchesRegionFilter(VolunteerItem item) {
    final region = _selectedRegion;
    if (region == null || region == '전체') return true;

    final haystack = '${item.place} ${item.centerName} ${item.title}';
    final regionKeywords = <String, List<String>>{
      '서울특별시': ['서울특별시', '서울시', '서울'],
      '부산광역시': ['부산광역시', '부산시', '부산'],
      '대구광역시': ['대구광역시', '대구시', '대구'],
      '인천광역시': ['인천광역시', '인천시', '인천'],
      '광주광역시': ['광주광역시', '광주시', '광주'],
      '대전광역시': ['대전광역시', '대전시', '대전'],
      '울산광역시': ['울산광역시', '울산시', '울산'],
      '세종특별자치시': ['세종특별자치시', '세종시', '세종'],
      '경기도': ['경기도', '경기'],
      '강원특별자치도': ['강원특별자치도', '강원도', '강원'],
      '충청북도': ['충청북도', '충북'],
      '충청남도': ['충청남도', '충남'],
      '전북특별자치도': ['전북특별자치도', '전라북도', '전북'],
      '전라남도': ['전라남도', '전남'],
      '경상북도': ['경상북도', '경북'],
      '경상남도': ['경상남도', '경남'],
      '제주특별자치도': ['제주특별자치도', '제주도', '제주'],
    };

    final district = _selectedDistrict;
    if (district != null && district != '전체') {
      return haystack.contains(district);
    }

    final regionList = regionKeywords[region] ?? [region];
    final districtList = _regionDistrictOptions[region] ?? const <String>[];
    return regionList.any(haystack.contains) ||
        districtList.any(haystack.contains);
  }

  Set<String> _selectedNonAllForTab(String tabLabel) {
    final selected = _selectedOptionsByTab[tabLabel] ?? const <String>{};
    return selected.where((e) => e != '전체').toSet();
  }

  bool _containsAny(String haystack, List<String> keywords) {
    return keywords.any(haystack.contains);
  }

  String _itemHaystack(VolunteerItem item) {
    return '${item.title} ${item.place} ${item.centerName}'.toLowerCase();
  }

  bool _matchesVolunteerFieldFilter(VolunteerItem item) {
    final selected = _selectedNonAllForTab('봉사분야');
    if (selected.isEmpty) return true;

    final h = _itemHaystack(item);
    final fieldKeywords = <String, List<String>>{
      '주거환경': ['주거', '주택', '집수리', '도배', '환경개선', '정리수납'],
      '교육': ['교육', '학습', '공부', '지도', '멘토', '교실', '학습지도'],
      '농어촌 봉사': ['농촌', '어촌', '농어촌', '일손돕기', '모내기'],
      '환경·생태계보호': ['환경', '생태', '보호', '플로깅', '줍깅', '정화', '쓰레기'],
      '지역안전·보호': ['안전', '순찰', '보호', '방범', '캠페인'],
      '재난·재해': ['재난', '재해', '복구', '구호', '수해', '산불'],
      '기타': [],
      '생활편의': ['생활', '편의', '이동지원', '배달', '도움'],
      '상담·멘토링': ['상담', '멘토', '멘토링', '코칭'],
      '보건·의료': ['보건', '의료', '건강', '병원', '간호', '검진'],
      '문화·체육·예술·관광': ['문화', '체육', '예술', '관광', '행사', '축제'],
      '사무행정': ['사무', '행정', '문서', '데이터', '정리'],
      '인권·공익': ['인권', '공익', '권리', '인식개선'],
      '국제협력·해외봉사': ['국제', '해외', '다문화', '글로벌'],
      '자원봉사 기본교육': ['기본교육', '교육수료', '오리엔테이션', '봉사교육'],
    };

    for (final option in selected) {
      if (option == '기타') {
        return true;
      }
      final keywords = fieldKeywords[option] ?? const <String>[];
      if (_containsAny(h, keywords)) return true;
    }
    return false;
  }

  bool _matchesActivityTypeFilter(VolunteerItem item) {
    final selected = _selectedNonAllForTab('활동구분');
    if (selected.isEmpty) return true;

    final h = _itemHaystack(item);
    final isOnline = _containsAny(h, ['온라인', '비대면', '줌', 'zoom', 'remote']);
    final isHybrid = _containsAny(h, ['온라인+오프라인', '온·오프라인', '온오프라인']);
    final isOffline = !isOnline || _containsAny(h, ['오프라인', '대면', '현장']);

    for (final option in selected) {
      if (option == '온라인' && isOnline) return true;
      if (option == '오프라인' && isOffline) return true;
      if (option == '온라인+오프라인' && isHybrid) return true;
    }
    return false;
  }

  bool _matchesTargetFilter(VolunteerItem item) {
    final selected = _selectedNonAllForTab('봉사대상');
    if (selected.isEmpty) return true;

    final h = _itemHaystack(item);
    final targetKeywords = <String, List<String>>{
      '장애인': ['장애'],
      '쪽방촌': ['쪽방'],
      '여성': ['여성'],
      '사회적기업': ['사회적기업', '소셜벤처'],
      '기타': [],
      '아동·청소년': ['아동', '청소년', '어린이', '유아', '학생'],
      '노인': ['노인', '어르신', '실버', '요양'],
      '다문화가정': ['다문화', '이주', '외국인'],
      '환경': ['환경', '생태'],
      '고향봉사': ['고향', '농촌', '귀촌'],
    };

    for (final option in selected) {
      if (option == '기타') {
        return true;
      }
      final keywords = targetKeywords[option] ?? const <String>[];
      if (_containsAny(h, keywords)) return true;
    }
    return false;
  }

  bool _matchesRecruitStateFilter(VolunteerItem item) {
    final selected = _selectedNonAllForTab('모집상태');
    if (selected.isEmpty) return true;

    final d = _dday(item.noticeEnd);
    final isRecruiting = d == null || d >= 0;
    final isClosed = !isRecruiting;

    for (final option in selected) {
      if (option == '모집중' && isRecruiting) return true;
      if (option == '모집완료' && isClosed) return true;
    }
    return false;
  }

  bool _matchesAllFilters(VolunteerItem item) {
    return _matchesRegionFilter(item) &&
        _matchesVolunteerFieldFilter(item) &&
        _matchesActivityTypeFilter(item) &&
        _matchesTargetFilter(item) &&
        _matchesRecruitStateFilter(item);
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
    final visibleItems = _items
        .where(_matchesAllFilters)
        .toList(growable: false);
    final visibleTopPick =
        _topPickItem != null && _matchesAllFilters(_topPickItem!)
        ? _topPickItem
        : null;

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
        visibleItems.isNotEmpty;
    // ✅ TopPick 1개 + 나머지
    final top = (!isSearchState) ? visibleTopPick : null;
    final rest = top == null
        ? visibleItems
        : visibleItems.where((v) => v.id != top.id).toList(growable: false);

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
                                  ...visibleItems.map(
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
                  top: 370,
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
                                    if (index != 0) {
                                      _selectedRegion = null;
                                      _selectedDistrict = null;
                                    }
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
                                      top: 0,
                                      bottom: 18,
                                    ),
                                    child: Center(
                                      child: Transform.translate(
                                        offset: const Offset(0, -40),
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
                                                            height: 14,
                                                          ),
                                                  itemBuilder: (context, index) {
                                                    final city =
                                                        _cityOptionsForFilter()[index];
                                                    final selected =
                                                        (_selectedRegion ??
                                                            '서울특별시') ==
                                                        city;
                                                    return GestureDetector(
                                                      onTap: () => setState(() {
                                                        _selectedRegion = city;
                                                        _selectedDistrict =
                                                            null;
                                                      }),
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              city,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: selected
                                                                    ? const Color(
                                                                        0xFF2D3436,
                                                                      )
                                                                    : const Color(
                                                                        0xFF5E666D,
                                                                      ),
                                                                fontSize:
                                                                    34 * 0.48,
                                                                fontFamily:
                                                                    'Pretendard Variable',
                                                                fontWeight:
                                                                    selected
                                                                    ? FontWeight
                                                                          .w600
                                                                    : FontWeight
                                                                          .w500,
                                                                height: 1.0,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.chevron_right,
                                                            size: 18,
                                                            color: selected
                                                                ? const Color(
                                                                    0xFF111111,
                                                                  )
                                                                : const Color(
                                                                    0xFFB5B9BE,
                                                                  ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: 154,
                                                child: _selectedRegion == null
                                                    ? const SizedBox.shrink()
                                                    : ListView.separated(
                                                        itemCount:
                                                            _districtOptionsForFilter()
                                                                .length,
                                                        separatorBuilder:
                                                            (context, index) =>
                                                                const SizedBox(
                                                                  height: 14,
                                                                ),
                                                        itemBuilder: (context, index) {
                                                          final district =
                                                              _districtOptionsForFilter()[index];
                                                          return GestureDetector(
                                                            onTap: () => setState(() {
                                                              final city =
                                                                  _selectedRegion ??
                                                                  '서울특별시';
                                                              _selectedRegion =
                                                                  city;
                                                              _selectedDistrict =
                                                                  district;
                                                              _showFilterSheet =
                                                                  false;
                                                            }),
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            child: Text(
                                                              district,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF5E666D,
                                                                    ),
                                                                fontSize:
                                                                    34 * 0.48,
                                                                fontFamily:
                                                                    'Pretendard Variable',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                height: 1.0,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : _selectedFilterTab >= 1
                                ? Transform.translate(
                                    offset: const Offset(0, -40),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        28,
                                        12,
                                        28,
                                        18,
                                      ),
                                      child: ListView.separated(
                                        itemCount: _fieldLeftColumn.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 20),
                                        itemBuilder: (context, index) {
                                          final left = _fieldLeftColumn[index];
                                          final right =
                                              index < _fieldRightColumn.length
                                              ? _fieldRightColumn[index]
                                              : null;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: _FieldFilterTile(
                                                  label: left,
                                                  selected:
                                                      _isSelectedForCurrentTab(
                                                        left,
                                                      ),
                                                  onTap: () => setState(
                                                    () => _toggleOptionForCurrentTab(left),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 22),
                                              Expanded(
                                                child: right == null
                                                    ? const SizedBox.shrink()
                                                    : _FieldFilterTile(
                                                        label: right,
                                                        selected:
                                                            _isSelectedForCurrentTab(
                                                              right,
                                                            ),
                                                        onTap: () => setState(() {
                                                          _toggleOptionForCurrentTab(right);
                                                        }),
                                                      ),
                                              ),
                                            ],
                                          );
                                        },
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

class _FieldFilterTile extends StatelessWidget {
  const _FieldFilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            selected ? 'assets/images/On.png' : 'assets/images/Off.png',
            width: 17,
            height: 17,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF111111)
                    : const Color(0xFF5E666D),
                fontSize: 14,
                fontFamily: 'Pretendard Variable',
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
