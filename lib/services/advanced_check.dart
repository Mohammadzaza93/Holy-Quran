import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// خطأ واحد أبلغ عنه خادم «المعلّم» (quran-muaalem).
class MuaalemError {
  final String type; // tajweed | normal | tashkeel
  final String action; // insert | delete | replace
  final String expected;
  final String heard;
  final int? expectedLen;
  final int? heardLen;
  final List<String> ruleNames;

  const MuaalemError({
    required this.type,
    required this.action,
    required this.expected,
    required this.heard,
    this.expectedLen,
    this.heardLen,
    this.ruleNames = const [],
  });

  String get typeLabel => switch (type) {
        'tashkeel' => 'حركة (تشكيل)',
        'tajweed' => 'حكم تجويد',
        _ => 'حرف',
      };

  String get actionLabel => switch (action) {
        'insert' => 'زيادة',
        'delete' => 'نقص',
        _ => 'إبدال',
      };

  factory MuaalemError.fromJson(Map<String, dynamic> j) {
    List<String> names(String key) => [
          for (final r in (j[key] as List? ?? const []))
            if (r is Map && r['name'] is Map) (r['name']['ar'] ?? '').toString(),
        ].where((e) => e.isNotEmpty).toList();
    return MuaalemError(
      type: (j['error_type'] ?? '').toString(),
      action: (j['speech_error_type'] ?? '').toString(),
      expected: (j['expected_ph'] ?? '').toString(),
      heard: (j['preditected_ph'] ?? '').toString(),
      expectedLen: j['expected_len'] as int?,
      heardLen: j['predicted_len'] as int?,
      ruleNames: {
        ...names('ref_tajweed_rules'),
        ...names('missing_tajweed_rules'),
        ...names('replaced_tajweed_rules'),
        ...names('inserted_tajweed_rules'),
      }.toList(),
    );
  }
}

class AdvancedCheckResult {
  final String? uthmaniText;
  final List<MuaalemError> errors;
  final String? message; // عند عدم العثور على مطابقة

  const AdvancedCheckResult({this.uthmaniText, this.errors = const [], this.message});

  bool get matched => uthmaniText != null;

  /// يحلّل ردّ `/correct-recitation` (200 أو 404).
  static AdvancedCheckResult parse(int status, String body) {
    final j = jsonDecode(body);
    if (j is! Map<String, dynamic>) {
      return const AdvancedCheckResult(message: 'ردّ غير متوقع من الخادم');
    }
    if (status == 404) {
      return AdvancedCheckResult(
        message: (j['message'] ?? 'لم يُعثر على آية مطابقة').toString(),
      );
    }
    return AdvancedCheckResult(
      uthmaniText: (j['uthmani_text'] ?? '').toString(),
      errors: [
        for (final e in (j['errors'] as List? ?? const []))
          if (e is Map<String, dynamic>) MuaalemError.fromJson(e),
      ],
    );
  }
}

/// عميل الفحص المتقدم: يرسل تسجيلاً إلى خادم quran-muaalem يشغّله المستخدم بنفسه.
class AdvancedCheck {
  static String normalizeUrl(String raw) {
    var u = raw.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.isNotEmpty && !u.startsWith('http')) u = 'http://$u';
    return u;
  }

  static Future<bool> ping(String baseUrl) async {
    try {
      final r = await http
          .get(Uri.parse('${normalizeUrl(baseUrl)}/health'))
          .timeout(const Duration(seconds: 8));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<AdvancedCheckResult> analyze(String baseUrl, File wav) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${normalizeUrl(baseUrl)}/correct-recitation'),
    )..files.add(await http.MultipartFile.fromPath('file', wav.path, filename: 'audio.wav'));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 404) {
      throw HttpException('الخادم أجاب برمز ${res.statusCode}');
    }
    return AdvancedCheckResult.parse(res.statusCode, utf8.decode(res.bodyBytes));
  }
}
