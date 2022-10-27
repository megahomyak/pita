import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class Attachment {
  Attachment(this.id, this.fileName, this.description);

  final int id;
  @JsonKey(name: "originalFileName")
  final String fileName;
  final String? description;

  factory Attachment.fromJson(dynamic json) => _$AttachmentFromJson(json);
}

@JsonSerializable()
class Announcement {
  Announcement(this.name, this.content, this.postDate, this.attachments);

  final String name;
  @JsonKey(name: "description")
  final String content;
  final DateTime postDate;
  final List<Attachment> attachments;

  factory Announcement.fromJson(dynamic json) => _$AnnouncementFromJson(json);
}
