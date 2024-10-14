import 'package:podium/models/referral.dart';

Referral singleReferralParser(referral) {
  return Referral(
    usedBy: referral[Referral.usedByKey],
  );
}

Map<String, Referral> referralsParser(referrals) {
  final referalsMap = <String, Referral>{};
  referrals.keys.toList().forEach((element) {
    final referral = singleReferralParser(referrals[element]);
    referalsMap[element] = referral;
  });
  return referalsMap;
}
