import 'dart:math';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/storage_service.dart';
import '../widgets/ayah_card.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.title, required this.questions, this.onFinished});

  final String title;
  final List<Question> questions;

  /// يُستدعى عند إنهاء الاختبار بالنتيجة والعدد (للاختبار القبلي/البعدي مثلاً)
  final void Function(int score, int total)? onFinished;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _rng = Random();
  late final List<List<String>> _options;
  final List<Question> _wrong = [];
  int _index = 0;
  int _score = 0;
  String? _selected;

  Question get _q => widget.questions[_index];
  bool get _answered => _selected != null;
  bool get _isLast => _index == widget.questions.length - 1;

  @override
  void initState() {
    super.initState();
    _options = widget.questions.map((q) {
      final o = <String>[q.correct, ...q.wrong];
      o.shuffle(_rng);
      return o;
    }).toList();
  }

  void _answer(String option) {
    if (_answered) return;
    final ok = option == _q.correct;
    setState(() {
      _selected = option;
      if (ok) {
        _score++;
      } else {
        _wrong.add(_q);
      }
    });
    StorageService.instance.recordAnswer(_q, ok);
  }

  void _next() {
    if (_isLast) {
      widget.onFinished?.call(_score, widget.questions.length);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          title: widget.title,
          total: widget.questions.length,
          score: _score,
          wrong: _wrong,
        ),
      ));
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  Color _optionColor(String option) {
    if (!_answered) return Colors.white;
    if (option == _q.correct) return const Color(0xFFD7F0DD);
    if (option == _selected) return const Color(0xFFF8D7D7);
    return Colors.white;
  }

  Color _optionBorder(String option) {
    if (!_answered) return const Color(0xFFCFCFCF);
    if (option == _q.correct) return const Color(0xFF2E8B57);
    if (option == _selected) return const Color(0xFFC0392B);
    return const Color(0xFFCFCFCF);
  }

  IconData? _optionIcon(String option) {
    if (!_answered) return null;
    if (option == _q.correct) return Icons.check_circle;
    if (option == _selected) return Icons.cancel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final q = _q;
    final options = _options[_index];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + (_answered ? 1 : 0)) / total),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'السؤال ${_index + 1} من $total',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.text,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.7),
                    ),
                    const SizedBox(height: 14),
                    AyahCard(key: ValueKey(q.id), question: q),
                    for (final option in options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _answer(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: _optionColor(option),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _optionBorder(option), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(option, style: const TextStyle(fontSize: 17, height: 1.6)),
                                ),
                                if (_optionIcon(option) != null)
                                  Icon(_optionIcon(option), color: _optionBorder(option)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_answered) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected == q.correct ? 'إجابة صحيحة ✓' : 'الإجابة الصحيحة: ${q.correct}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (q.explanation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(q.explanation, style: const TextStyle(fontSize: 15, height: 1.7)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_answered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_isLast ? 'عرض النتيجة' : 'السؤال التالي'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
