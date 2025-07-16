// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Todo _$TodoFromJson(Map<String, dynamic> json) => Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      status: $enumDecodeNullable(_$TodoStatusEnumMap, json['status']) ??
          TodoStatus.todo,
      priority: $enumDecodeNullable(_$TodoPriorityEnumMap, json['priority']) ??
          TodoPriority.medium,
      tag: $enumDecode(_$TodoTagEnumMap, json['tag']),
    );

Map<String, dynamic> _$TodoToJson(Todo instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'status': _$TodoStatusEnumMap[instance.status]!,
      'priority': _$TodoPriorityEnumMap[instance.priority]!,
      'tag': _$TodoTagEnumMap[instance.tag]!,
    };

const _$TodoStatusEnumMap = {
  TodoStatus.todo: 'todo',
  TodoStatus.pending: 'pending',
  TodoStatus.doing: 'doing',
  TodoStatus.needsReview: 'needsReview',
  TodoStatus.done: 'done',
};

const _$TodoPriorityEnumMap = {
  TodoPriority.low: 'low',
  TodoPriority.medium: 'medium',
  TodoPriority.high: 'high',
  TodoPriority.urgent: 'urgent',
};

const _$TodoTagEnumMap = {
  TodoTag.work: 'work',
  TodoTag.personal: 'personal',
};
