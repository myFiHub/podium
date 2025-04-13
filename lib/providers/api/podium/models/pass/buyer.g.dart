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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PodiumPassBuyerModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PodiumPassBuyerModel(...).copyWith(id: 12, name: "My name")
  /// ````
  PodiumPassBuyerModel call({
    String address,
    bool followed_by_me,
    String image,
    String name,
    String uuid,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPodiumPassBuyerModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPodiumPassBuyerModel.copyWith.fieldName(...)`
class _$PodiumPassBuyerModelCWProxyImpl
    implements _$PodiumPassBuyerModelCWProxy {
  const _$PodiumPassBuyerModelCWProxyImpl(this._value);

  final PodiumPassBuyerModel _value;

  @override
  PodiumPassBuyerModel address(String address) => this(address: address);

  @override
  PodiumPassBuyerModel followed_by_me(bool followed_by_me) =>
      this(followed_by_me: followed_by_me);

  @override
  PodiumPassBuyerModel image(String image) => this(image: image);

  @override
  PodiumPassBuyerModel name(String name) => this(name: name);

  @override
  PodiumPassBuyerModel uuid(String uuid) => this(uuid: uuid);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PodiumPassBuyerModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PodiumPassBuyerModel(...).copyWith(id: 12, name: "My name")
  /// ````
  PodiumPassBuyerModel call({
    Object? address = const $CopyWithPlaceholder(),
    Object? followed_by_me = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? uuid = const $CopyWithPlaceholder(),
  }) {
    return PodiumPassBuyerModel(
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

extension $PodiumPassBuyerModelCopyWith on PodiumPassBuyerModel {
  /// Returns a callable class that can be used as follows: `instanceOfPodiumPassBuyerModel.copyWith(...)` or like so:`instanceOfPodiumPassBuyerModel.copyWith.fieldName(...)`.
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
