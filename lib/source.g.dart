// GENERATED CODE - DO NOT MODIFY BY HAND

part of source;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceResults _$SourceResultsFromJson(Map<String, dynamic> json) {
  return SourceResults()
    ..name = (json['name'] as List)?.map((e) => e as String)?.toList()
    ..studentID = json['studentID'] as String
    ..stateID = json['stateID'] as String
    ..imageFilePath = json['imageFilePath'] as String
    ..grade = json['grade'] as String
    ..html = json['html'] as String
    ..errorID = json['errorID'] as String
    ..classes = (json['classes'] as List)
        ?.map((e) =>
            e == null ? null : SourceClass.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$SourceResultsToJson(SourceResults instance) =>
    <String, dynamic>{
      'name': instance.name,
      'studentID': instance.studentID,
      'stateID': instance.stateID,
      'imageFilePath': instance.imageFilePath,
      'grade': instance.grade,
      'html': instance.html,
      'errorID': instance.errorID,
      'classes': instance.classes
    };

SourceClass _$SourceClassFromJson(Map<String, dynamic> json) {
  return SourceClass(
      className: json['className'] as String,
      period: json['period'] as String,
      teacherName: json['teacherName'] as String,
      teacherEmail: json['teacherEmail'] as String,
      roomNumber: json['roomNumber'] as String,
      overallGrades: (json['overallGrades'] as Map<String, dynamic>)?.map(
          (k, e) => MapEntry(
              k,
              e == null
                  ? null
                  : SourceClassGrade.fromJson(e as Map<String, dynamic>))),
      assignments: (json['assignments'] as List)
          ?.map((e) => e == null
              ? null
              : SourceAssignment.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      categories: (json['categories'] as List)
          ?.map((e) => e == null
              ? null
              : SourceCategory.fromJson(e as Map<String, dynamic>))
          ?.toList())
    ..gpaWeight = (json['gpaWeight'] as num)?.toDouble();
}

Map<String, dynamic> _$SourceClassToJson(SourceClass instance) =>
    <String, dynamic>{
      'className': instance.className,
      'period': instance.period,
      'teacherName': instance.teacherName,
      'teacherEmail': instance.teacherEmail,
      'roomNumber': instance.roomNumber,
      'gpaWeight': instance.gpaWeight,
      'overallGrades': instance.overallGrades,
      'assignments': instance.assignments,
      'categories': instance.categories
    };

SourceAssignment _$SourceAssignmentFromJson(Map<String, dynamic> json) {
  return SourceAssignment(
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      category: json['category'] == null
          ? null
          : SourceCategory.fromJson(json['category'] as Map<String, dynamic>),
      name: json['name'] as String,
      flags: (json['flags'] as List)?.map((e) => e as String)?.toList(),
      grade: json['grade'] == null
          ? null
          : SourceAssignmentGrade.fromJson(
              json['grade'] as Map<String, dynamic>),
      quarters: (json['quarters'] as List)?.map((e) => e as String)?.toList());
}

Map<String, dynamic> _$SourceAssignmentToJson(SourceAssignment instance) =>
    <String, dynamic>{
      'dueDate': instance.dueDate?.toIso8601String(),
      'category': instance.category,
      'quarters': instance.quarters,
      'name': instance.name,
      'flags': instance.flags,
      'grade': instance.grade
    };

SourceAssignmentGrade _$SourceAssignmentGradeFromJson(
    Map<String, dynamic> json) {
  return SourceAssignmentGrade(json['score'], json['maxScore'], json['graded'])
    ..letter = json['letter'] as String
    ..percent = (json['percent'] as num)?.toDouble()
    ..color = json['color'] as int;
}

Map<String, dynamic> _$SourceAssignmentGradeToJson(
        SourceAssignmentGrade instance) =>
    <String, dynamic>{
      'letter': instance.letter,
      'percent': instance.percent,
      'score': instance.score,
      'maxScore': instance.maxScore,
      'graded': instance.graded,
      'color': instance.color
    };

SourceClassGrade _$SourceClassGradeFromJson(Map<String, dynamic> json) {
  return SourceClassGrade(json['percent'])
    ..letter = json['letter'] as String
    ..color = json['color'] as int;
}

Map<String, dynamic> _$SourceClassGradeToJson(SourceClassGrade instance) =>
    <String, dynamic>{
      'letter': instance.letter,
      'percent': instance.percent,
      'color': instance.color
    };

SourceCategory _$SourceCategoryFromJson(Map<String, dynamic> json) {
  return SourceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: (json['weight'] as num)?.toDouble());
}

Map<String, dynamic> _$SourceCategoryToJson(SourceCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'weight': instance.weight
    };
