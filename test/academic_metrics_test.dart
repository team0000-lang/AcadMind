import 'package:flutter_test/flutter_test.dart';
import 'package:acadmind/academic_metrics.dart';

void main() {
  group('AcademicMetrics.fromRecords', () {
    test('derives completion and study totals only from supplied records', () {
      final metrics = AcademicMetrics.fromRecords(
        assignments: const [
          {'status': 'completed'},
          {'status': 'in_progress'},
          {'status': 'not_started'},
        ],
        studySessions: const [
          {'duration_minutes': 30},
          {'duration_minutes': 45},
        ],
        quizAttempts: const [
          {'score': 8, 'max_score': 10},
          {'score': 4, 'max_score': 5},
        ],
      );

      expect(metrics.completedAssignments, 1);
      expect(metrics.totalAssignments, 3);
      expect(metrics.assignmentPercent, closeTo(1 / 3, 0.00001));
      expect(metrics.totalStudyMinutes, 75);
      expect(metrics.studyHours, 1.25);
      expect(metrics.quizPercent, 80);
    });

    test('keeps missing activity empty rather than inventing progress', () {
      final metrics = AcademicMetrics.fromRecords(
        assignments: const [],
        studySessions: const [],
        quizAttempts: const [],
      );

      expect(metrics.completedAssignments, 0);
      expect(metrics.totalAssignments, 0);
      expect(metrics.assignmentPercent, isNull);
      expect(metrics.studyHours, 0);
      expect(metrics.quizPercent, isNull);
    });

    test('preserves fractional quiz scores', () {
      final metrics = AcademicMetrics.fromRecords(
        assignments: const [],
        studySessions: const [],
        quizAttempts: const [
          {'score': 7.5, 'max_score': 10.0},
        ],
      );

      expect(metrics.quizPercent, 75);
    });
  });
}
