import 'package:flutter/material.dart';

import '../models/question.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.total,
    required this.score,
    required this.wrong,
  });

  final String title;
  final int total;
  final int score;
  final List<Question> wrong;

  String get _message {
    final p = total == 0 ? 0 : score / total;
    if (p == 1) return 'ممتاز! أجبت عن كل الأسئلة بشكل صحيح، بارك الله فيك';
    if (p >= 0.8) return 'أحسنت! مستواك متقدم، راجع أخطاءك القليلة';
    if (p >= 0.5) return 'جيد، تحتاج إلى مراجعة بعض الأحكام';
    return 'لا بأس، كرر المراجعة والاختبار وستتحسن بإذن الله';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = total == 0 ? 0 : (score * 100 / total).round();

    return Scaffold(
      appBar: AppBar(title: const Text('النتيجة')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Text(
                '$score / $total',
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: scheme.primary),
              ),
            ),
            Center(child: Text('$percent%', style: const TextStyle(fontSize: 22))),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.7)),
            const SizedBox(height: 24),
            if (wrong.isNotEmpty) ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => QuizScreen(title: 'إعادة الأسئلة الخاطئة', questions: List.of(wrong)),
                )),
                icon: const Icon(Icons.replay),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('أعد الأسئلة التي أخطأت فيها'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('العودة للرئيسية'),
              ),
            ),
            if (wrong.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('مراجعة الأخطاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final q in wrong)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.6)),
                        const SizedBox(height: 6),
                        Text('الصحيح: ${q.correct}', style: TextStyle(color: scheme.primary, height: 1.6)),
                        if (q.explanation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(q.explanation, style: const TextStyle(height: 1.6)),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
