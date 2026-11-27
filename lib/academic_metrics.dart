class AcademicMetrics {
  final int completedAssignments;
  final int totalAssignments;
  final int totalStudyMinutes;
  final double quizScore;
  final double quizMaximum;

  const AcademicMetrics({
    required this.completedAssignments,
    required this.totalAssignments,
    required this.totalStudyMinutes,
    required this.quizScore,
    required this.quizMaximum,
  });

  factory AcademicMetrics.fromRecords({
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> studySessions,
    required List<Map<String, dynamic>> quizAttempts,
  }) {
    return AcademicMetrics(
      completedAssignments:
          assignments.where((row) => row['status'] == 'completed').length,
      totalAssignments: assignments.length,
      totalStudyMinutes: studySessions.fold<int>(
        0,
        (sum, row) => sum + ((row['duration_minutes'] as num?)?.toInt() ?? 0),
      ),
      quizScore: quizAttempts.fold<double>(
        0,
        (sum, row) => sum + ((row['score'] as num?)?.toDouble() ?? 0),
      ),
      quizMaximum: quizAttempts.fold<double>(
        0,
        (sum, row) => sum + ((row['max_score'] as num?)?.toDouble() ?? 0),
      ),
    );
  }

  double? get quizPercent =>
      quizMaximum == 0 ? null : quizScore / quizMaximum * 100;
  double? get assignmentPercent =>
      totalAssignments == 0 ? null : completedAssignments / totalAssignments;
  double get studyHours => totalStudyMinutes / 60;
}
