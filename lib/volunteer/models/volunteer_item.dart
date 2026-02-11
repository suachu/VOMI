/// 봉사활동 1개를 표현하는 데이터 모델
class VolunteerItem {
  /// 봉사 프로그램 고유 번호
  final String id;

  /// 봉사 제목
  final String title;

  /// 활동 장소
  final String place;

  /// 기관명
  final String centerName;

  /// 모집 시작일
  final DateTime? noticeStart;

  /// 모집 마감일
  final DateTime? noticeEnd;

  /// 활동 시작일
  final DateTime? programStart;

  /// 활동 종료일
  final DateTime? programEnd;

  /// 활동 시작 시간 (예: 10)
  final int? actBeginHour;

  /// 활동 종료 시간 (예: 17)
  final int? actEndHour;

  final int? recruitTotal; // rcritNmpr
  final int? applyTotal; // appTotal (제공 안 될 수도 있음)

  /// API 원본 id에서 숫자만 추출한 안정적인 프로그램 id
  String get normalizedProgramId {
    final raw = id.trim();
    if (raw.isEmpty) {
      return raw;
    }

    // 정상 케이스: 이미 숫자만 들어온 progrmRegistNo
    if (RegExp(r'^\d+$').hasMatch(raw)) {
      return raw;
    }

    // 비정형 문자열이면 "가장 긴 숫자 덩어리"를 progrmRegistNo로 사용
    final chunks = RegExp(
      r'\d+',
    ).allMatches(raw).map((m) => m.group(0)!).toList();
    if (chunks.isEmpty) {
      return raw;
    }
    chunks.sort((a, b) => b.length.compareTo(a.length));
    return chunks.first;
  }

  bool get hasValidProgramId => normalizedProgramId.isNotEmpty;

  /// 1365 신청 상세 페이지 링크 후보들(운영 경로 버전 차이 대응)
  List<String> get applyUrls {
    final id = normalizedProgramId;
    return [
      Uri.https('www.1365.go.kr', '/vols/P9210/partcptn/timeCptn.do', {
        'titleNm': '상세보기',
        'type': 'show',
        'progrmRegistNo': id,
      }).toString(),
      Uri.https('www.1365.go.kr', '/vols/1572247904127/partcptn/timeCptn.do', {
        'titleNm': '상세보기',
        'type': 'show',
        'progrmRegistNo': id,
      }).toString(),
    ];
  }

  String get applyUrl => applyUrls.first;

  const VolunteerItem({
    required this.id,
    required this.title,
    required this.place,
    required this.centerName,
    this.noticeStart,
    this.noticeEnd,
    this.programStart,
    this.programEnd,
    this.actBeginHour,
    this.actEndHour,
    this.recruitTotal,
    this.applyTotal,
  });
}
