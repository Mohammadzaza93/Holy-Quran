import '../models/book_lesson.dart';
import 'book_lessons_advanced.dart';
import 'book_lessons_basics.dart';

/// كل الدروس بترتيبها في الكتاب.
const List<BookLesson> allBookLessons = [...basicBookLessons, ...advancedBookLessons];

/// أسماء الأبواب بترتيب ظهورها.
List<String> bookLessonParts() {
  final parts = <String>[];
  for (final l in allBookLessons) {
    if (!parts.contains(l.part)) parts.add(l.part);
  }
  return parts;
}

BookLesson? bookLessonById(String id) {
  for (final l in allBookLessons) {
    if (l.id == id) return l;
  }
  return null;
}
