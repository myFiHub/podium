import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

String? extractAddressFromUserModel({required UserInfoModel user}) {
  final walletAddress = user.localWalletAddress;
  try {
    if (walletAddress.isEmpty || walletAddress == null) {
      log.d('No local wallet address found for user ${user.id}');
      final firstParticleAddress = user.savedParticleUserInfo?.wallets.where(
        (w) => w.address.isNotEmpty && w.chain == 'evm_chain',
      );
      if (firstParticleAddress != null && firstParticleAddress.isNotEmpty) {
        return firstParticleAddress.first.address;
      } else {
        return null;
      }
    }
  } catch (e) {
    log.e('Error extracting address from user model, error: $e');
    return null;
  }
  return walletAddress;
}
