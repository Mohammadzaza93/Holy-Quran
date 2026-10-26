import 'package:flutter/material.dart';

import '../data/book_reference.dart';

/// شاشة «عن المرجع»: تعريف بالكتاب الذي بُنيت عليه الدروس وبصاحبه، وتنبيهات.
class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(label, style: TextStyle(color: scheme.outline, height: 1.6)),
              ),
              Expanded(child: Text(value, style: const TextStyle(height: 1.7, fontSize: 15.5))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('عن المرجع')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Icon(Icons.menu_book, size: 40, color: scheme.primary),
                  const SizedBox(height: 10),
                  const Text(
                    'النور المبين',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'في تجويد القرآن الكريم',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'محاضرات الدكتور الشيخ',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    BookReference.authorShort,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('بيانات الكتاب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  row('العنوان', BookReference.title),
                  row('المحاضر', BookReference.author),
                  row('التفريغ', '${BookReference.transcriber} - ${BookReference.transcriberNote}'),
                  row('الرسوم', BookReference.illustrator),
                  row('الناشر', BookReference.publisher),
                  row('الطبعة', BookReference.edition),
                  row('المقدمة', BookReference.prefaceDate),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('المتون المذكورة في الملاحق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'يضم الكتاب في ملحقه المتون التالية. لا يعيد التطبيق نصوصها، فراجعها في الكتاب نفسه (ص ٧٥–٨٩):',
                    style: TextStyle(height: 1.7),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 2),
                  for (final w in BookReference.appendixWorks)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $w', style: const TextStyle(height: 1.7)),
                    ),
                  const SizedBox(height: 8),
                  const Text(BookReference.structureNote,
                      style: TextStyle(height: 1.7, fontSize: 13.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFFFF4D6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('تنبيه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(BookReference.disclaimer, style: TextStyle(height: 1.8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'نسأل الله أن يجزي الشيخ الدكتور أيمن رشدي سويد ومن ساهم في إخراج هذا العلم خير الجزاء، وأن ينفع به.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.8, fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
