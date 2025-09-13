// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buyer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PodiumPassBuyerModelCWProxy {
  PodiumPassBuyerModel address(String address);

  PodiumPassBuyerModel followed_by_me(bool followed_by_me);

  PodiumPassBuyerModel image(String image);

  PodiumPassBuyerModel name(String name);

  PodiumPassBuyerModel uuid(String uuid);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PodiumPassBuyerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PodiumPassBuyerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PodiumPassBuyerModel call({
    String address,
    bool followed_by_me,
    String image,
    String name,
    String uuid,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPodiumPassBuyerModel.copyWith(...)` or call `instanceOfPodiumPassBuyerModel.copyWith.fieldName(value)` for a single field.
class _$PodiumPassBuyerModelCWProxyImpl
    implements _$PodiumPassBuyerModelCWProxy {
  const _$PodiumPassBuyerModelCWProxyImpl(this._value);

  final PodiumPassBuyerModel _value;

  @override
  PodiumPassBuyerModel address(String address) => call(address: address);

  @override
  PodiumPassBuyerModel followed_by_me(bool followed_by_me) =>
      call(followed_by_me: followed_by_me);

  @override
  PodiumPassBuyerModel image(String image) => call(image: image);

  @override
  PodiumPassBuyerModel name(String name) => call(name: name);

  @override
  PodiumPassBuyerModel uuid(String uuid) => call(uuid: uuid);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PodiumPassBuyerModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PodiumPassBuyerModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PodiumPassBuyerModel call({
    Object? address = const $CopyWithPlaceholder(),
    Object? followed_by_me = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? uuid = const $CopyWithPlaceholder(),
  }) {
    return PodiumPassBuyerModel(
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

extension $PodiumPassBuyerModelCopyWith on PodiumPassBuyerModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPodiumPassBuyerModel.copyWith(...)` or `instanceOfPodiumPassBuyerModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PodiumPassBuyerModelCWProxy get copyWith =>
      _$PodiumPassBuyerModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PodiumPassBuyerModel _$PodiumPassBuyerModelFromJson(
        Map<String, dynamic> json) =>
    PodiumPassBuyerModel(
      address: json['address'] as String,
      followed_by_me: json['followed_by_me'] as bool,
      image: json['image'] as String,
      name: json['name'] as String,
      uuid: json['uuid'] as String,
    );

Map<String, dynamic> _$PodiumPassBuyerModelToJson(
        PodiumPassBuyerModel instance) =>
    <String, dynamic>{
      'address': instance.address,
      'followed_by_me': instance.followed_by_me,
      'image': instance.image,
      'name': instance.name,
      'uuid': instance.uuid,
    };
