class BlockedUserModel {
  final String uuid;
  final String? address;
  final String? name;
  final String? image;
  final DateTime? blockedAt;

  const BlockedUserModel({
    required this.uuid,
    this.address,
    this.name,
    this.image,
    this.blockedAt,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) =>
      BlockedUserModel(
        uuid: json['uuid'] as String,
        address: json['address'] as String?,
        name: json['name'] as String?,
        image: json['image'] as String?,
        blockedAt: DateTime.tryParse(json['blocked_at'] as String? ?? ''),
      );
}
