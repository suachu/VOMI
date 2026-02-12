import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class MyPageSummary {
  const MyPageSummary({
    required this.totalHours,
    required this.appliedCount,
    required this.completedCount,
    required this.likedCount,
  });

  final int totalHours;
  final int appliedCount;
  final int completedCount;
  final int likedCount;

  factory MyPageSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return MyPageSummary(
      totalHours: asInt(
        json['totalHours'] ?? json['totalVolunteerHours'] ?? json['total_time'],
      ),
      appliedCount: asInt(
        json['appliedCount'] ??
            json['appliedVolunteerCount'] ??
            json['applied_count'],
      ),
      completedCount: asInt(
        json['completedCount'] ??
            json['completedVolunteerCount'] ??
            json['completed_count'],
      ),
      likedCount: asInt(
        json['likedCount'] ?? json['likedVolunteerCount'] ?? json['liked_count'],
      ),
    );
  }
}

class MyPageService {
  const MyPageService();

  static const String _apiBaseUrl =
      String.fromEnvironment('MY_PAGE_API_BASE_URL');
  static const String _summaryPath = String.fromEnvironment(
    'MY_PAGE_SUMMARY_PATH',
    defaultValue: '/mypage/summary',
  );

  Future<MyPageSummary> fetchSummary({required User user}) async {
    if (_apiBaseUrl.trim().isEmpty) {
      throw StateError(
        'MY_PAGE_API_BASE_URL is not configured. '
        'Run with --dart-define=MY_PAGE_API_BASE_URL=https://your-api-domain',
      );
    }

    final idToken = await user.getIdToken();
    final baseUri = Uri.parse(_apiBaseUrl);
    final uri = baseUri
        .resolve(_summaryPath)
        .replace(queryParameters: {'uid': user.uid});

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('마이페이지 요약 API 실패: ${res.statusCode}');
    }

    final raw = jsonDecode(utf8.decode(res.bodyBytes));
    final payload = (raw is Map<String, dynamic> && raw['data'] is Map)
        ? (raw['data'] as Map).cast<String, dynamic>()
        : (raw as Map).cast<String, dynamic>();

    return MyPageSummary.fromJson(payload);
  }
}
