import 'package:flutter/material.dart';

import '../data/book_reference.dart';
import '../data/lessons.dart';
import '../services/storage_service.dart';
import 'lesson_screen.dart';
import 'reference_screen.dart';

/// قائمة دروس «تعلّم التجويد» المبنية على كتاب النور المبين للدكتور أيمن رشدي سويد.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Future<void> _open(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonScreen(index: index)),
    );
    if (mounted) setState(() {});
  }

  void _openReference() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferenceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final store = StorageService.instance;
    final scheme = Theme.of(context).colorScheme;
    final total = allLessons.length;
    final done = allLessons.where((l) => store.isLessonRead(l.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعلّم التجويد'),
        actions: [
          IconButton(
            tooltip: 'عن المرجع',
            icon: const Icon(Icons.info_outline),
            onPressed: _openReference,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openReference,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book, color: scheme.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'المرجع: ${BookReference.title}',
                            style: TextStyle(fontWeight: FontWeight.bold, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'محاضرات ${BookReference.author}',
                      style: TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: total == 0 ? 0 : done / total),
                    const SizedBox(height: 6),
                    Text('أنهيت $done من $total درساً', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          for (final part in lessonParts()) ...[
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              child: Text(
                part,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.primary),
              ),
            ),
            for (var i = 0; i < allLessons.length; i++)
              if (allLessons[i].part == part) _lessonTile(i, store, scheme),
          ],
          const SizedBox(height: 16),
          const Text(
            'الدروس ملخصات بصياغة التطبيق، والمرجع هو الكتاب. لا يغني هذا عن التلقي والمشافهة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.7, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _lessonTile(int index, StorageService store, ColorScheme scheme) {
    final lesson = allLessons[index];
    final read = store.isLessonRead(lesson.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _open(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: read ? Colors.green.shade100 : scheme.primaryContainer,
          child: read
              ? Icon(Icons.check, color: Colors.green.shade800)
              : Text('${index + 1}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${lesson.summary}\nالكتاب: ص ${lesson.pages}',
              style: const TextStyle(fontSize: 13, height: 1.6)),
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
