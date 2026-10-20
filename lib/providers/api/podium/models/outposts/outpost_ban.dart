import 'package:json_annotation/json_annotation.dart';

part 'outpost_ban.g.dart';

/// A host either removed someone for a while (`kick`) or blocked them until
/// a host lets them back in (`ban`).
enum OutpostBanKind {
  kick,
  ban;

  static OutpostBanKind fromWire(String? value) =>
      value == 'kick' ? OutpostBanKind.kick : OutpostBanKind.ban;

  String get wire => name;
}

/// Why the current user can't be in an outpost right now.
@JsonSerializable()
class OutpostBanInfo {
  final String kind;

  /// When a kick ends, in milliseconds. Null for a ban.
  final int? expires_at;

  const OutpostBanInfo({required this.kind, this.expires_at});

  OutpostBanKind get banKind => OutpostBanKind.fromWire(kind);

  DateTime? get expiresAt => expires_at == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(expires_at!);

  /// A kick stops applying once it runs out, even before the outpost is
  /// fetched again.
  bool get isActive {
    final until = expiresAt;
    return until == null || until.isAfter(DateTime.now());
  }

  factory OutpostBanInfo.fromJson(Map<String, dynamic> json) =>
      _$OutpostBanInfoFromJson(json);
  Map<String, dynamic> toJson() => _$OutpostBanInfoToJson(this);
}

/// A kicked or blocked user, as listed to the outpost's hosts.
@JsonSerializable()
class OutpostBanItem {
  final String user_uuid;
  final String? name;
  final String? image;
  final String address;
  final String? aptos_address;
  final String kind;
  final String? reason;
  final int? expires_at;
  final int created_at;
  final String banned_by_user_uuid;
  final String? banned_by_user_name;

  const OutpostBanItem({
    required this.user_uuid,
    this.name,
    this.image,
    required this.address,
    this.aptos_address,
    required this.kind,
    this.reason,
    this.expires_at,
    required this.created_at,
    required this.banned_by_user_uuid,
    this.banned_by_user_name,
  });

  OutpostBanKind get banKind => OutpostBanKind.fromWire(kind);

  DateTime? get expiresAt => expires_at == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(expires_at!);

  factory OutpostBanItem.fromJson(Map<String, dynamic> json) =>
      _$OutpostBanItemFromJson(json);
  Map<String, dynamic> toJson() => _$OutpostBanItemToJson(this);
}
