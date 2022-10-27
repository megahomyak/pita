// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
      json['id'] as int,
      json['originalFileName'] as String,
      json['description'] as String?,
    );

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalFileName': instance.fileName,
      'description': instance.description,
    };

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      json['name'] as String,
      json['description'] as String,
      DateTime.parse(json['postDate'] as String),
      (json['attachments'] as List<dynamic>)
          .map((e) => Attachment.fromJson(e))
          .toList(),
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.content,
      'postDate': instance.postDate.toIso8601String(),
      'attachments': instance.attachments,
    };
