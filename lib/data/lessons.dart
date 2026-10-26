import '../models/lesson.dart';
import 'lessons_advanced.dart';
import 'lessons_basics.dart';

/// كل الدروس بترتيبها في الكتاب.
const List<Lesson> allLessons = [...basicLessons, ...advancedLessons];

/// أسماء الأبواب بترتيب ظهورها.
List<String> lessonParts() {
  final parts = <String>[];
  for (final l in allLessons) {
    if (!parts.contains(l.part)) parts.add(l.part);
  }
  return parts;
}

Lesson? lessonById(String id) {
  for (final l in allLessons) {
    if (l.id == id) return l;
  }
  return null;
}
