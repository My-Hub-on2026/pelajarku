class GradeEntry {
  const GradeEntry({
    required this.id,
    required this.courseId,
    required this.category,
    required this.score,
    required this.maxScore,
    required this.weight,
    required this.date,
  });

  final String id;
  final String courseId;
  final String category;
  final double score;
  final double maxScore;
  final double weight;
  final DateTime date;

  double get percentage => maxScore == 0 ? 0 : (score / maxScore) * 100;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'course_id': courseId,
        'category': category,
        'score': score,
        'max_score': maxScore,
        'weight': weight,
        'date': date.millisecondsSinceEpoch,
      };

  factory GradeEntry.fromMap(Map<String, Object?> map) {
    return GradeEntry(
      id: map['id']! as String,
      courseId: map['course_id']! as String,
      category: map['category']! as String,
      score: (map['score']! as num).toDouble(),
      maxScore: (map['max_score']! as num).toDouble(),
      weight: (map['weight']! as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
    );
  }
}
