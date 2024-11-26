// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class FirebaseInternalWalletInfo {
  final String uuid;
  final List<InternalWallet> wallets;

  static const String uuidKey = 'uuid';
  static const String walletsKey = 'wallets';

  FirebaseInternalWalletInfo({
    required this.uuid,
    required this.wallets,
  });

  FirebaseInternalWalletInfo copyWith({
    String? uuid,
    List<InternalWallet>? wallets,
  }) {
    return FirebaseInternalWalletInfo(
      uuid: uuid ?? this.uuid,
      wallets: wallets ?? this.wallets,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'wallets': wallets.map((x) => x.toMap()).toList(),
    };
  }

  factory FirebaseInternalWalletInfo.fromMap(Map<String, dynamic> map) {
    return FirebaseInternalWalletInfo(
      uuid: map['uuid'] as String,
      wallets: List<InternalWallet>.from(
        (map['wallets'] as List<int>).map<InternalWallet>(
          (x) => InternalWallet.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory FirebaseInternalWalletInfo.fromJson(String source) =>
      FirebaseInternalWalletInfo.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FirebaseParticleAuthUserInfo(uuid: $uuid, wallets: $wallets)';

  @override
  bool operator ==(covariant FirebaseInternalWalletInfo other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.uuid == uuid && listEquals(other.wallets, wallets);
  }

  @override
  int get hashCode => uuid.hashCode ^ wallets.hashCode;
}

class InternalWallet {
  final String address;
  final String chain;

  static const String addressKey = 'address';
  static const String chainKey = 'chain';

  InternalWallet({
    required this.address,
    required this.chain,
  });

  InternalWallet copyWith({
    String? address,
    String? chain,
  }) {
    return InternalWallet(
      address: address ?? this.address,
      chain: chain ?? this.chain,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address,
      'chain': chain,
    };
  }

  factory InternalWallet.fromMap(Map<String, dynamic> map) {
    return InternalWallet(
      address: map['address'] as String,
      chain: map['chain'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory InternalWallet.fromJson(String source) =>
      InternalWallet.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ParticleAuthWallet(address: $address, chain: $chain)';

  @override
  bool operator ==(covariant InternalWallet other) {
    if (identical(this, other)) return true;

    return other.address == address && other.chain == chain;
  }

  @override
  int get hashCode => address.hashCode ^ chain.hashCode;
}
