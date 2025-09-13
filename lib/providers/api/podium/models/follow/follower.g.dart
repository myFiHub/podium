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

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `FollowerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FollowerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  FollowerModel call({
    String address,
    bool followed_by_me,
    String image,
    String name,
    String uuid,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfFollowerModel.copyWith(...)` or call `instanceOfFollowerModel.copyWith.fieldName(value)` for a single field.
class _$FollowerModelCWProxyImpl implements _$FollowerModelCWProxy {
  const _$FollowerModelCWProxyImpl(this._value);

  final FollowerModel _value;

  @override
  FollowerModel address(String address) => call(address: address);

  @override
  FollowerModel followed_by_me(bool followed_by_me) =>
      call(followed_by_me: followed_by_me);

  @override
  FollowerModel image(String image) => call(image: image);

  @override
  FollowerModel name(String name) => call(name: name);

  @override
  FollowerModel uuid(String uuid) => call(uuid: uuid);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `FollowerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FollowerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  FollowerModel call({
    Object? address = const $CopyWithPlaceholder(),
    Object? followed_by_me = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? uuid = const $CopyWithPlaceholder(),
  }) {
    return FollowerModel(
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      followed_by_me: followed_by_me == const $CopyWithPlaceholder() ||
              followed_by_me == null
          ? _value.followed_by_me
          // ignore: cast_nullable_to_non_nullable
          : followed_by_me as bool,
      image: image == const $CopyWithPlaceholder() || image == null
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      uuid: uuid == const $CopyWithPlaceholder() || uuid == null
          ? _value.uuid
          // ignore: cast_nullable_to_non_nullable
          : uuid as String,
    );
  }
}

extension $FollowerModelCopyWith on FollowerModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfFollowerModel.copyWith(...)` or `instanceOfFollowerModel.copyWith.fieldName(...)`.
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
