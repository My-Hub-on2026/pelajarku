class Course {
  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.room,
    required this.colorValue,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String id;
  final String name;
  final String teacher;
  final String room;
  final int colorValue;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;

  Course copyWith({
    String? id,
    String? name,
    String? teacher,
    String? room,
    int? colorValue,
    int? dayOfWeek,
    int? startMinutes,
    int? endMinutes,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      colorValue: colorValue ?? this.colorValue,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'teacher': teacher,
        'room': room,
        'color_value': colorValue,
        'day_of_week': dayOfWeek,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
      };

  factory Course.fromMap(Map<String, Object?> map) {
    return Course(
      id: map['id']! as String,
      name: map['name']! as String,
      teacher: (map['teacher'] as String?) ?? '',
      room: (map['room'] as String?) ?? '',
      colorValue: map['color_value']! as int,
      dayOfWeek: map['day_of_week']! as int,
      startMinutes: map['start_minutes']! as int,
      endMinutes: map['end_minutes']! as int,
    );
  }
}
