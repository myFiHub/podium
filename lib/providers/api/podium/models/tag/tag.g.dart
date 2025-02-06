// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagModel _$TagModelFromJson(Map<String, dynamic> json) => TagModel(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      outpostIds: (json['outpostIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'outpostIds': instance.outpostIds,
    };
