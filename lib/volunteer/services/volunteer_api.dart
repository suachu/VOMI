import 'dart:convert';
import 'package:charset_converter/charset_converter.dart';
import 'package:http/http.dart' as http;

class VolunteerApi {
  static const String _base =
      'http://openapi.1365.go.kr/openapi/service/rest/VolunteerPartcptnService';

  Future<String> fetchListXml({
    required String serviceKey,
    int pageNo = 1,
    int numOfRows = 50,
    String? keyword,
    String? schSido,
    String? schSign1,
  }) async {
    final queryParameters = <String, String>{
      'serviceKey': serviceKey,
      'pageNo': '$pageNo',
      'numOfRows': '$numOfRows',
    };
    if (keyword?.trim().isNotEmpty ?? false) {
      queryParameters['keyword'] = keyword!.trim();
    }
    if (schSido?.trim().isNotEmpty ?? false) {
      queryParameters['schSido'] = schSido!.trim();
    }
    if (schSign1?.trim().isNotEmpty ?? false) {
      queryParameters['schSign1'] = schSign1!.trim();
    }

    final uri = Uri.parse(
      '$_base/getVltrSearchWordList',
    ).replace(queryParameters: queryParameters);

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('목록 API 실패: ${res.statusCode}\n${res.body}');
    }

    return _decodeXml(res);
  }

  Future<String> fetchItemXml({
    required String serviceKey,
    required String progrmRegistNo,
  }) async {
    final uri = Uri.parse('$_base/getVltrPartcptnItem').replace(
      queryParameters: {
        'serviceKey': serviceKey,
        'progrmRegistNo': progrmRegistNo,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('상세 API 실패: ${res.statusCode}\n${res.body}');
    }

    return _decodeXml(res);
  }

  Future<String> _decodeXml(http.Response res) async {
    final ct = (res.headers['content-type'] ?? '').toLowerCase();

    // 1) 서버가 utf-8이라고 명시한 경우
    if (ct.contains('charset=utf-8')) {
      return utf8.decode(res.bodyBytes);
    }

    // 2) euc-kr 명시 (또는 한국 공공API에서 흔함)
    if (ct.contains('euc-kr') ||
        ct.contains('ks_c_5601') ||
        ct.contains('ksc5601')) {
      return await CharsetConverter.decode('euc-kr', res.bodyBytes);
    }

    // 3) 명시가 없으면: 보통 utf-8 먼저 시도 -> 실패하면 euc-kr로 fallback
    try {
      return utf8.decode(res.bodyBytes);
    } catch (_) {
      return await CharsetConverter.decode('euc-kr', res.bodyBytes);
    }
  }
}
