import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vomi/services/liked_volunteer_service.dart';
import '../models/volunteer_item.dart';
import '../services/volunteer_api.dart';
import '../services/volunteer_parser.dart';
import 'webview_screen.dart';

class VolunteerDetailScreen extends StatefulWidget {
  final VolunteerItem item;
  final String serviceKey;

  const VolunteerDetailScreen({
    super.key,
    required this.item,
    required this.serviceKey,
  });

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  // "자세한 정보 보기" 접기/펼치기 상태
  bool _expanded = false;
  // 하단 하트 아이콘 상태 (현재 로컬 상태만 토글)
  bool _liked = false;
  final VolunteerApi _api = VolunteerApi();

  String _ageChip = '성인';
  String _categoryChip = '생활편의';
  String _modeChip = '오프라인';
  String _beneficiaryTarget = '정보 없음';
  String? _attachmentUrl;
  bool _hasAttachment = false;

  @override
  void initState() {
    super.initState();
    _loadChipMeta();
    _loadLikedState();
  }

  Future<void> _loadLikedState() async {
    await LikedVolunteerService.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _liked = LikedVolunteerService.isLikedSync(widget.item.id);
    });
  }

  String _thumbnailAssetForItem() {
    final t = widget.item.title.toLowerCase();
    if (t.contains('급식') ||
        t.contains('배식') ||
        t.contains('조리') ||
        t.contains('식당')) {
      return 'assets/images/volunteer/illus_school1.png';
    }
    if (t.contains('환경') ||
        t.contains('쓰레기') ||
        t.contains('쓰줍') ||
        t.contains('플로깅')) {
      return 'assets/images/volunteer/illus_eco1.png';
    }
    if (t.contains('동물') ||
        t.contains('유기') ||
        t.contains('강아지') ||
        t.contains('유기견')) {
      return 'assets/images/volunteer/illus_animal1.png';
    }
    if (t.contains('요양') ||
        t.contains('요양원') ||
        t.contains('노인') ||
        t.contains('어르신') ||
        t.contains('양로원')) {
      return 'assets/images/volunteer/illus_care1.png';
    }
    if (t.contains('교육') ||
        t.contains('멘토') ||
        t.contains('학습') ||
        t.contains('아동') ||
        t.contains('청소년')) {
      return 'assets/images/volunteer/illus_child1.png';
    }
    return 'assets/images/volunteer/illus_people1.png';
  }

  Future<void> _toggleLiked() async {
    final previous = _liked;
    setState(() => _liked = !_liked);
    try {
      await LikedVolunteerService.toggle(
        LikedVolunteer(
          id: widget.item.id,
          title: widget.item.title,
          subtitle: widget.item.place.isEmpty
              ? (widget.item.centerName.isEmpty ? '봉사 정보' : widget.item.centerName)
              : widget.item.place,
          thumbnailAsset: _thumbnailAssetForItem(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _liked = LikedVolunteerService.isLikedSync(widget.item.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _liked = previous);
    }
  }

  Future<void> _loadChipMeta() async {
    _ageChip = _inferAgeFromTitle(widget.item.title);
    _categoryChip = _inferCategoryFromText(widget.item.title);
    _modeChip = _inferModeFromText(widget.item.title, widget.item.place);
    _beneficiaryTarget = _inferBeneficiaryTarget(
      widget.item.title,
      widget.item.place,
    );

    if (!mounted) return;
    setState(() {});

    try {
      final xml = await _api.fetchItemXml(
        serviceKey: widget.serviceKey,
        progrmRegistNo: widget.item.normalizedProgramId,
      );
      final meta = parseVolunteerDetailMeta(xml);

      if (!mounted) return;
      setState(() {
        _ageChip = meta.ageLabel?.trim().isNotEmpty == true
            ? _compactAgeChip(meta.ageLabel!.trim())
            : _ageChip;
        _categoryChip = meta.categoryLabel?.trim().isNotEmpty == true
            ? _compactCategoryChip(meta.categoryLabel!.trim())
            : _categoryChip;
        _modeChip = meta.modeLabel?.trim().isNotEmpty == true
            ? _compactModeChip(meta.modeLabel!.trim())
            : _modeChip;
        _attachmentUrl = meta.attachmentUrl;
        _hasAttachment = meta.hasAttachment;
      });
    } catch (_) {
      // 상세 API 실패 시에는 목록 데이터 기반 추론값 유지
    }
  }

  String _inferAgeFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('청소년') || t.contains('청년') || t.contains('학생')) return '청소년';
    if (t.contains('아동') || t.contains('어린이') || t.contains('유아')) return '아동';
    return '성인';
  }

  String _compactAgeChip(String text) {
    if (text.contains('청소년') || text.contains('청년') || text.contains('학생')) {
      return '청소년';
    }
    if (text.contains('아동') || text.contains('어린이') || text.contains('유아')) {
      return '아동';
    }
    if (text.contains('전연령') || text.contains('전체') || text.contains('누구나')) {
      return '전연령';
    }
    return '성인';
  }

  String _inferCategoryFromText(String text) {
    final t = text.toLowerCase();
    if (t.contains('환경') || t.contains('플로깅') || t.contains('쓰레기')) {
      return '환경보호';
    }
    if (t.contains('교육') || t.contains('멘토') || t.contains('학습')) return '교육';
    if (t.contains('동물') || t.contains('유기견') || t.contains('보호소')) return '동물';
    if (t.contains('행사') || t.contains('축제') || t.contains('공연')) return '문화행사';
    if (t.contains('말벗') || t.contains('돌봄') || t.contains('배달')) return '생활편의';
    return '생활편의';
  }

  String _compactCategoryChip(String text) {
    final t = text.toLowerCase();
    if (t.contains('생활') ||
        t.contains('편의') ||
        t.contains('돌봄') ||
        t.contains('말벗')) {
      return '생활편의';
    }
    if (t.contains('환경') || t.contains('플로깅') || t.contains('정화')) {
      return '환경보호';
    }
    if (t.contains('교육') || t.contains('학습') || t.contains('멘토')) return '교육';
    if (t.contains('문화') || t.contains('행사') || t.contains('축제')) return '문화행사';
    if (t.contains('동물') || t.contains('유기견') || t.contains('보호소')) return '동물';
    if (text.length <= 6 && !text.contains(' ')) return text;
    return '일반';
  }

  String _inferModeFromText(String title, String place) {
    final joined = '${title.toLowerCase()} ${place.toLowerCase()}';
    if (joined.contains('온라인') ||
        joined.contains('비대면') ||
        joined.contains('재택')) {
      return '온라인';
    }
    return '오프라인';
  }

  String _compactModeChip(String text) {
    if (text.contains('온라인') || text.contains('비대면') || text.contains('재택')) {
      return '온라인';
    }
    return '오프라인';
  }

  String _inferBeneficiaryTarget(String title, String place) {
    final t = '$title $place'.toLowerCase();
    if (t.contains('장애')) return '장애인';
    if (t.contains('아동') || t.contains('어린이') || t.contains('유아')) return '아동';
    if (t.contains('청소년') || t.contains('청년') || t.contains('학생')) return '청소년';
    if (t.contains('노인') || t.contains('어르신') || t.contains('시니어')) {
      return '어르신';
    }
    if (t.contains('다문화')) return '다문화가정';
    if (t.contains('독거')) return '독거가구';
    if (t.contains('환자')) return '환자';
    if (t.contains('유기견') || t.contains('유기묘') || t.contains('동물')) return '동물';
    return '지역주민';
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDateKor(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}년${d.month}월${d.day}일';
  }

  String _formatTime(int? hour) {
    if (hour == null) return '-';
    final h = hour % 24;
    return '${h.toString().padLeft(2, '0')}:00';
  }

  String _formatTimeRange(int? beginHour, int? endHour) {
    final b = _formatTime(beginHour);
    final e = _formatTime(endHour);
    if (b == '-' || e == '-') return '-';
    return '$b ~ $e';
  }

  String _weekdayKo(DateTime d) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[d.weekday - 1];
  }

  String _formatWeekdayRange(DateTime? start, DateTime? end) {
    if (start == null) return '정보 없음';
    if (end == null) return _weekdayKo(start);
    final s = _weekdayKo(start);
    final e = _weekdayKo(end);
    return s == e ? s : '$s~$e';
  }

  int? _dday(DateTime? noticeEnd) {
    if (noticeEnd == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(noticeEnd.year, noticeEnd.month, noticeEnd.day);
    return end.difference(today).inDays;
  }

  String _ddayLabel(DateTime? noticeEnd) {
    final d = _dday(noticeEnd);
    if (d == null) return '마감미정';
    if (d < 0) return '마감됨';
    if (d == 0) return '마감 D-day';
    return '마감 D-$d';
  }

  List<Uri> _freshApplyUris() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return widget.item.applyUrls.map((url) {
      final uri = Uri.parse(url);
      return uri.replace(
        queryParameters: <String, String>{
          ...uri.queryParameters,
          '_vomiOpenTs': ts,
        },
      );
    }).toList();
  }

  Future<void> _openApplyUrl() async {
    if (!widget.item.hasValidProgramId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신청 페이지 정보를 찾을 수 없습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final applyUris = _freshApplyUris();
    for (final uri in applyUris) {
      final launchedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (launchedInApp) {
        return;
      }

      final launchedDefault = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launchedDefault) {
        return;
      }

      final launchedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedExternal) {
        return;
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          title: '1365 신청하기',
          initialUrl: applyUris.first.toString(),
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '브라우저 실행에 실패해 앱 내 화면으로 열었어요: ${widget.item.normalizedProgramId}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    await Clipboard.setData(ClipboardData(text: applyUris.first.toString()));
  }

  void _openAttachmentOrShowMessage() {
    if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WebViewScreen(title: '첨부파일', initialUrl: _attachmentUrl!),
        ),
      );
      return;
    }

    if (_hasAttachment) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WebViewScreen(title: '첨부파일', initialUrl: widget.item.applyUrl),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('첨부파일 없음'), duration: Duration(seconds: 1)),
    );
  }

  Widget _chip({
    required String text,
    required double width,
    required Color fg,
    required Color bg,
  }) {
    const chipTextStyle = TextStyle(
      fontFamily: 'Pretendard Variable',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: chipTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final chipWidth = (textPainter.width + 24) > width
        ? (textPainter.width + 24)
        : width;

    return SizedBox(
      width: chipWidth,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: chipTextStyle.copyWith(color: fg),
        ),
      ),
    );
  }

  Widget _infoLine({
    required String imageAsset,
    required String label,
    required Widget value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE1EFF3),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6E767C),
                  fontSize: 14,
                  fontFamily: 'Pretendard Variable',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  height: 21 / 14,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              value,
            ],
          ),
        ),
      ],
    );
  }

  Widget _expandedInfoRow({required String label, required String value}) {
    const rowTextStyle = TextStyle(
      color: Color(0xFF616A70),
      fontSize: 13,
      fontFamily: 'Pretendard Variable',
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      height: 1.0,
      letterSpacing: 0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(label, textAlign: TextAlign.left, style: rowTextStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: rowTextStyle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Figma 시안처럼 종료일은 MM.DD만 노출 (YYYY.MM.DD -> MM.DD)
    final period =
        '${_formatDate(item.programStart)} ~ ${_formatDate(item.programEnd).substring(5)}';
    final timeRange = _formatTimeRange(item.actBeginHour, item.actEndHour);
    final noticePeriod =
        '${_formatDate(item.noticeStart)} ~ ${_formatDate(item.noticeEnd)}';
    final hasRecruitData = item.applyTotal != null && item.recruitTotal != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3),
      body: Column(
        children: [
          // 상단 흰 영역 전체 높이: 디바이스 맨 위 기준 102px
          Container(
            height: 102,
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  left: 24,
                  top: 62.5,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 27,
                      height: 27,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 9.7,
                            top: 5.91,
                            child: Image.asset(
                              'assets/images/volunteer/b.png',
                              width: 7.59375,
                              height: 15.1875,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 169.5,
                  top: 64.5,
                  child: SizedBox(
                    width: 63,
                    height: 23,
                    child: Center(
                      child: Text(
                        '세부 정보',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        strutStyle: StrutStyle(
                          fontSize: 17,
                          height: 22.44 / 17,
                          forceStrutHeight: true,
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w500,
                          height: 22.44 / 17,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              // 하단 고정 바(88px)와 겹치지 않게 bottom 여백 확보
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 122),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 312,
                    child: Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2D3436),
                        fontSize: 22,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w600,
                        height: 28 / 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          text: _ddayLabel(item.noticeEnd),
                          width: 72,
                          fg: const Color(0xFFFFFFFF),
                          bg: const Color(0xFF00A5DF),
                        ),
                        _chip(
                          text: _ageChip,
                          width: 47,
                          fg: const Color(0xFFFF9F43),
                          bg: const Color(0xFFFFE7D1),
                        ),
                        _chip(
                          text: _categoryChip,
                          width: 69,
                          fg: const Color(0xFF00A5DF),
                          bg: const Color(0xFFE5F8FF),
                        ),
                        _chip(
                          text: _modeChip,
                          width: 69,
                          fg: const Color(0xFFFFFFFF),
                          bg: const Color(0xFFACD7E6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 354,
                    height: 212,
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 10,
                          offset: Offset(2, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoLine(
                          imageAsset: 'assets/images/volunteer/cal.png',
                          label: '활동기간',
                          value: Text(
                            period,
                            style: const TextStyle(
                              color: Color(0xFF30363A),
                              fontSize: 16,
                              fontFamily: 'Pretendard Variable',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              height: 24 / 16,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        _infoLine(
                          imageAsset: 'assets/images/volunteer/time2.png',
                          label: '활동시간',
                          value: Text(
                            '$timeRange (최대 8시간 인정)',
                            style: const TextStyle(
                              color: Color(0xFF30363A),
                              fontSize: 16,
                              fontFamily: 'Pretendard Variable',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              height: 24 / 16,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        _infoLine(
                          imageAsset: 'assets/images/volunteer/twopeople.png',
                          label: '모집현황',
                          value: hasRecruitData
                              ? RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFF30363A),
                                      fontSize: 16,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                      height: 24 / 16,
                                      letterSpacing: 0,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${item.applyTotal}명 신청',
                                        style: const TextStyle(
                                          color: Color(0xFF009FDE),
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${item.recruitTotal}명',
                                      ),
                                    ],
                                  ),
                                )
                              : const Text(
                                  '정보 없음',
                                  style: TextStyle(
                                    color: Color(0xFF30363A),
                                    fontSize: 16,
                                    fontFamily: 'Pretendard Variable',
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    height: 24 / 16,
                                    letterSpacing: 0,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    // 요약 정보 영역 토글
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      width: 354,
                      height: 49,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 10,
                            offset: Offset(2, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 24,
                            top: 14,
                            child: Text(
                              '자세한 정보 보기',
                              style: TextStyle(
                                color: Color(0xFF2D3436),
                                fontSize: 14,
                                fontFamily: 'Pretendard Variable',
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                height: 21 / 14,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 24,
                            top: 17.46875, // (49 - 14.062500953674316) / 2
                            child: SizedBox(
                              width: 7.031249523162842,
                              height: 14.062500953674316,
                              child: Image.asset(
                                'assets/images/volunteer/down.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_expanded) ...[
                    // 접기/펼치기 상세 블록
                    const SizedBox(height: 10),
                    Container(
                      width: 353,
                      height: 185,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            offset: Offset(2, 4),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _expandedInfoRow(
                              label: '모집기간',
                              value: noticePeriod,
                            ),
                            const SizedBox(height: 20),
                            _expandedInfoRow(
                              label: '모집기관',
                              value: item.centerName.isEmpty
                                  ? '정보 없음'
                                  : item.centerName,
                            ),
                            const SizedBox(height: 20),
                            _expandedInfoRow(
                              label: '봉사장소',
                              value: item.place.isEmpty ? '정보 없음' : item.place,
                            ),
                            const SizedBox(height: 20),
                            _expandedInfoRow(
                              label: '활동요일',
                              value: _formatWeekdayRange(
                                item.programStart,
                                item.programEnd,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _expandedInfoRow(
                              label: '봉사대상',
                              value: _beneficiaryTarget,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '기관 안내사항',
                          style: TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 18,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            height: 28 / 18,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      Text(
                        '첨부파일',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF636E72),
                          fontSize: 13,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: _openAttachmentOrShowMessage,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 15,
                          height: 18.33,
                          child: Image.asset(
                            'assets/images/volunteer/download.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '1.활동일시: ${_formatDateKor(item.programStart)} ~ ${_formatDateKor(item.programEnd)} / $timeRange\n'
                    '2.활동장소: ${item.place.isEmpty ? '정보 없음' : item.place}\n'
                    '3.활동내용: 설명절 재가장애인 대상 지원 봉사자 모집(예시 문구)\n'
                    '4.문의전화: 정보 없음\n'
                    '5.모집기간: $noticePeriod',
                    style: const TextStyle(
                      color: Color(0xFF636E72),
                      fontSize: 14,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      height: 28 / 14,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        // 화면 하단 고정 액션 바: 디바이스 맨 아래 기준 88px
        height: 88,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9EBED))),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 30,
              top: 28,
              width: 32,
              height: 32,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공유 기능은 추후 연결 예정입니다.')),
                  );
                },
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(
                    'assets/images/volunteer/with.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 100,
              top: 30.5,
              width: 30,
              height: 27.53,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _toggleLiked,
                child: Image.asset(
                  _liked
                      ? 'assets/images/heart3.png'
                      : 'assets/images/volunteer/heart2.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 163,
              top: 17,
              width: 209,
              height: 54,
              child: OutlinedButton(
                onPressed: _openApplyUrl,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB1B3B9), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFFFFFFFF),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 28,
                      child: Image.asset(
                        'assets/images/volunteer/1365.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '바로가기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2D3436),
                        fontSize: 18,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        height: 22.44 / 18,
                        letterSpacing: 0,
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
