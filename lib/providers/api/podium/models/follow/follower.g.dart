// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FollowerModelCWProxy {
  FollowerModel address(String address);

  FollowerModel followed_by_me(bool followed_by_me);

  FollowerModel image(String image);

  FollowerModel name(String name);

  FollowerModel uuid(String uuid);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FollowerModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FollowerModel(...).copyWith(id: 12, name: "My name")
  /// ````
  FollowerModel call({
    String address,
    bool followed_by_me,
    String image,
    String name,
    String uuid,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFollowerModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFollowerModel.copyWith.fieldName(...)`
class _$FollowerModelCWProxyImpl implements _$FollowerModelCWProxy {
  const _$FollowerModelCWProxyImpl(this._value);

  final FollowerModel _value;

  @override
  FollowerModel address(String address) => this(address: address);

  @override
  FollowerModel followed_by_me(bool followed_by_me) =>
      this(followed_by_me: followed_by_me);

  @override
  FollowerModel image(String image) => this(image: image);

  @override
  FollowerModel name(String name) => this(name: name);

  @override
  FollowerModel uuid(String uuid) => this(uuid: uuid);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FollowerModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FollowerModel(...).copyWith(id: 12, name: "My name")
  /// ````
  FollowerModel call({
    Object? address = const $CopyWithPlaceholder(),
    Object? followed_by_me = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? uuid = const $CopyWithPlaceholder(),
  }) {
    return FollowerModel(
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      followed_by_me: followed_by_me == const $CopyWithPlaceholder()
          ? _value.followed_by_me
          // ignore: cast_nullable_to_non_nullable
          : followed_by_me as bool,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      uuid: uuid == const $CopyWithPlaceholder()
          ? _value.uuid
          // ignore: cast_nullable_to_non_nullable
          : uuid as String,
    );
  }
}

extension $FollowerModelCopyWith on FollowerModel {
  /// Returns a callable class that can be used as follows: `instanceOfFollowerModel.copyWith(...)` or like so:`instanceOfFollowerModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FollowerModelCWProxy get copyWith => _$FollowerModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowerModel _$FollowerModelFromJson(Map<String, dynamic> json) =>
    FollowerModel(
      address: json['address'] as String,
      followed_by_me: json['followed_by_me'] as bool,
      image: json['image'] as String,
      name: json['name'] as String,
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$FollowerModelToJson(FollowerModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'followed_by_me': instance.followed_by_me,
      'image': instance.image,
      'name': instance.name,
      'uuid': instance.uuid,
    };
