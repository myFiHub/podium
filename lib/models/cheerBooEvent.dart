class PaymentTypes {
  static const String cheer = 'cheer';
  static const String boo = 'boo';
  static const String frienTechTicket = 'frienTechTicket';
  static const String arenaTicket = 'arenaTicket';
}

class PaymentEvent {
  String type;
  String targetAddress;
  String targetId;
  String amount;
  String initiatorAddress;
  String initiatorId;
  String chainId;
  String? groupId;
  bool? selfCheer = false;
  List<String>? memberIds = [];

  static String typeKey = 'type';
  static String targetAddressKey = 'targetAddress';
  static String amountKey = 'amount';
  static String initiatorAddressKey = 'initiatorAddress';
  static String initiatorIdKey = 'initiatorId';
  static String targetIdKey = 'targetId';
  static String groupIdKey = 'groupId';
  static String selfCheerKey = 'selfCheer';
  static String memberIdsKey = 'memberIds';
  static String chainIdKey = 'chainId';

  PaymentEvent({
    required this.type,
    required this.targetAddress,
    required this.amount,
    required this.initiatorAddress,
    required this.initiatorId,
    required this.targetId,
    this.groupId,
    this.selfCheer,
    this.memberIds,
    required this.chainId,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[typeKey] = type;
    data[targetAddressKey] = targetAddress;
    data[amountKey] = amount;
    data[initiatorAddressKey] = initiatorAddress;
    data[initiatorIdKey] = initiatorId;
    data[targetIdKey] = targetId;
    data[groupIdKey] = groupId;
    data[selfCheerKey] = selfCheer;
    data[memberIdsKey] = memberIds;
    data[chainIdKey] = chainId;
    return data;
  }
}
