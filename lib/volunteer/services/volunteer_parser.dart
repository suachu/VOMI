import 'package:xml/xml.dart';
import '../models/volunteer_item.dart';

class VolunteerDetailMeta {
  final String? ageLabel;
  final String? categoryLabel;
  final String? modeLabel;
  final String? attachmentUrl;
  final bool hasAttachment;

  const VolunteerDetailMeta({
    this.ageLabel,
    this.categoryLabel,
    this.modeLabel,
    this.attachmentUrl,
    this.hasAttachment = false,
  });
}

/// "20260204" 같은 8자리 날짜를 DateTime으로 바꾸는 함수
DateTime? _parseYyyyMmDd(String? s) {
  if (s == null) return null;
  final t = s.trim();
  if (t.length != 8) return null;

  final y = int.tryParse(t.substring(0, 4));
  final m = int.tryParse(t.substring(4, 6));
  final d = int.tryParse(t.substring(6, 8));
  if (y == null || m == null || d == null) return null;

  return DateTime(y, m, d);
}

/// "10" 같은 숫자 문자열을 int로 바꾸는 함수
int? _parseInt(String? s) {
  if (s == null) return null;
  return int.tryParse(s.trim());
}

/// XML 문자열을 받아서 VolunteerItem 리스트로 바꿔준다
List<VolunteerItem> parseVolunteerList(String xmlStr) {
  final document = XmlDocument.parse(xmlStr);

  // XML 안에서 <item> 태그들만 전부 찾기
  final items = document.findAllElements('item');

  // 태그 안의 텍스트를 안전하게 꺼내는 도우미
  String getTag(XmlElement e, String tag) {
    return e.getElement(tag)?.innerText.trim() ?? '';
  }

  // 빈 값이면 null로 처리하는 도우미
  String? getTagNullable(XmlElement e, String tag) {
    final v = e.getElement(tag)?.innerText;
    if (v == null) return null;
    final t = v.trim();
    if (t.isEmpty) return null;
    return t;
  }

  // item 하나를 VolunteerItem 하나로 바꾸기
  return items.map((e) {
    final id = getTag(e, 'progrmRegistNo');
    final title = getTag(e, 'progrmSj');
    final place = getTag(e, 'actPlace');
    final center = getTag(e, 'nanmmbyNm');

    final noticeStart = _parseYyyyMmDd(getTagNullable(e, 'noticeBgnde'));
    final noticeEnd = _parseYyyyMmDd(getTagNullable(e, 'noticeEndde'));

    final programStart = _parseYyyyMmDd(getTagNullable(e, 'progrmBgnde'));
    final programEnd = _parseYyyyMmDd(getTagNullable(e, 'progrmEndde'));

    final actBegin = _parseInt(getTagNullable(e, 'actBeginTm'));
    final actEnd = _parseInt(getTagNullable(e, 'actEndTm'));

    final recruitTotal = _parseInt(getTagNullable(e, 'rcritNmpr'));
    final applyTotal = _parseInt(getTagNullable(e, 'appTotal'));

    return VolunteerItem(
      id: id,
      title: title,
      place: place,
      centerName: center,
      noticeStart: noticeStart,
      noticeEnd: noticeEnd,
      programStart: programStart,
      programEnd: programEnd,
      actBeginHour: actBegin,
      actEndHour: actEnd,
      recruitTotal: recruitTotal,
      applyTotal: applyTotal,
    );
  }).toList();
}

/// XML에서 totalCount를 읽어온다. 없으면 null 반환.
int? parseTotalCount(String xmlStr) {
  final document = XmlDocument.parse(xmlStr);
  final total = document.findAllElements('totalCount').cast<XmlElement?>();
  if (total.isEmpty) return null;
  final text = total.first?.innerText.trim();
  if (text == null || text.isEmpty) return null;
  return int.tryParse(text);
}

VolunteerDetailMeta parseVolunteerDetailMeta(String xmlStr) {
  final document = XmlDocument.parse(xmlStr);
  final item = document.findAllElements('item').firstOrNull;
  if (item == null) return const VolunteerDetailMeta();

  String? firstNonEmpty(List<String> tags) {
    for (final tag in tags) {
      final raw = item.getElement(tag)?.innerText;
      if (raw == null) continue;
      final v = raw.trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  bool? toBool(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toUpperCase();
    if (v == 'Y' || v == 'TRUE' || v == '1' || v == '가능') return true;
    if (v == 'N' || v == 'FALSE' || v == '0' || v == '불가') return false;
    return null;
  }

  String? normalizeAge({String? youthRaw, String? adultRaw, String? ageRaw}) {
    final youth = toBool(youthRaw);
    final adult = toBool(adultRaw);
    if (youth == true && adult == true) return '전연령';
    if (youth == true) return '청소년';
    if (adult == true) return '성인';

    final text = ageRaw?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.contains('청소년') || text.contains('청년')) return '청소년';
    if (text.contains('성인')) return '성인';
    if (text.contains('누구나') || text.contains('전연령') || text.contains('전체')) {
      return '전연령';
    }
    return text;
  }

  String? normalizeMode({
    String? modeRaw,
    String? onlineRaw,
    String? placeRaw,
  }) {
    final online = toBool(onlineRaw);
    if (online == true) return '온라인';
    if (online == false) return '오프라인';

    final text = (modeRaw ?? placeRaw)?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.contains('비대면') || text.contains('온라인')) return '온라인';
    if (text.contains('대면') || text.contains('오프라인')) return '오프라인';
    // 온/오프라인 태그가 아닌 자유 텍스트(예: 활동장소)가 들어온 경우는 무시
    return null;
  }

  String? normalizeCategory(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? normalizeAttachmentUrl(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    if (text.startsWith('/')) return 'https://www.1365.go.kr$text';
    return null;
  }

  final ageLabel = normalizeAge(
    youthRaw: firstNonEmpty(['yngbgsPosblAt', 'teenPosblAt', 'youthPosblAt']),
    adultRaw: firstNonEmpty(['adultPosblAt', 'adltPosblAt']),
    ageRaw: firstNonEmpty(['actAgeInfo', 'ageInfo', 'actAgeNm']),
  );
  final categoryLabel = normalizeCategory(
    firstNonEmpty(['srvcClCodeNm', 'progrmSe', 'actTypeNm', 'actClCodeNm']),
  );
  final modeLabel = normalizeMode(
    modeRaw: firstNonEmpty(['actPlaceSeNm', 'onoffSeNm', 'actTypeNm']),
    onlineRaw: firstNonEmpty(['nonfaceToFaceAt', 'onlineAt']),
    placeRaw: firstNonEmpty(['actPlace']),
  );
  final attachmentUrl = normalizeAttachmentUrl(
    firstNonEmpty([
      'attachFileUrl',
      'atchFileUrl',
      'atchFileDownUrl',
      'fileUrl',
      'downloadUrl',
      'atchUrl',
      'upFileUrl',
      'upfileUrl',
    ]),
  );
  final hasAttachment =
      attachmentUrl != null ||
      firstNonEmpty([
            'attachFileNm',
            'atchFileNm',
            'fileNm',
            'fileName',
            'atchFile',
            'atchmnflNm',
          ]) !=
          null;

  return VolunteerDetailMeta(
    ageLabel: ageLabel,
    categoryLabel: categoryLabel,
    modeLabel: modeLabel,
    attachmentUrl: attachmentUrl,
    hasAttachment: hasAttachment,
  );
}
