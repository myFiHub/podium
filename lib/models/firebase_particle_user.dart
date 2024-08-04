// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class FirebaseParticleAuthUserInfo {
  final String uuid;
  final List<ParticleAuthWallet> wallets;

  static const String uuidKey = 'uuid';
  static const String walletsKey = 'wallets';

  FirebaseParticleAuthUserInfo({
    required this.uuid,
    required this.wallets,
  });

  FirebaseParticleAuthUserInfo copyWith({
    String? uuid,
    List<ParticleAuthWallet>? wallets,
  }) {
    return FirebaseParticleAuthUserInfo(
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

  factory FirebaseParticleAuthUserInfo.fromMap(Map<String, dynamic> map) {
    return FirebaseParticleAuthUserInfo(
      uuid: map['uuid'] as String,
      wallets: List<ParticleAuthWallet>.from(
        (map['wallets'] as List<int>).map<ParticleAuthWallet>(
          (x) => ParticleAuthWallet.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory FirebaseParticleAuthUserInfo.fromJson(String source) =>
      FirebaseParticleAuthUserInfo.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FirebaseParticleAuthUserInfo(uuid: $uuid, wallets: $wallets)';

  @override
  bool operator ==(covariant FirebaseParticleAuthUserInfo other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.uuid == uuid && listEquals(other.wallets, wallets);
  }

  @override
  int get hashCode => uuid.hashCode ^ wallets.hashCode;
}

class ParticleAuthWallet {
  final String address;
  final String chain;

  static const String addressKey = 'address';
  static const String chainKey = 'chain';

  ParticleAuthWallet({
    required this.address,
    required this.chain,
  });

  ParticleAuthWallet copyWith({
    String? address,
    String? chain,
  }) {
    return ParticleAuthWallet(
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

  factory ParticleAuthWallet.fromMap(Map<String, dynamic> map) {
    return ParticleAuthWallet(
      address: map['address'] as String,
      chain: map['chain'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ParticleAuthWallet.fromJson(String source) =>
      ParticleAuthWallet.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ParticleAuthWallet(address: $address, chain: $chain)';

  @override
  bool operator ==(covariant ParticleAuthWallet other) {
    if (identical(this, other)) return true;

    return other.address == address && other.chain == chain;
  }

  @override
  int get hashCode => address.hashCode ^ chain.hashCode;
}
