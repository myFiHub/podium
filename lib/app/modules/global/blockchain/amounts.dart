import 'package:decimal/decimal.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Converts a human amount (e.g. 0.1 ETH) to integer base units exactly,
/// without going through floating-point multiplication.
BigInt toBaseUnits(num amount, int decimals) {
  final scaled =
      Decimal.parse(amount.toString()) * Decimal.ten.pow(decimals).toDecimal();
  return scaled.toBigInt();
}

EthereumAddress parseAddress(String address) {
  return EthereumAddress.fromHex(address);
}

/// [amount] is in ether, not wei.
EtherAmount parseValue(num amount) {
  return EtherAmount.inWei(toBaseUnits(amount, 18));
}

double bigIntWeiToDouble(BigInt v) {
  final BigInt weiToEthRatio = BigInt.from(10).pow(18);
  final double vInEth = v.toDouble() / weiToEthRatio.toDouble();
  return vInEth;
}

double bigIntCoinToMoveOnAptos(BigInt v) {
  final BigInt weiToEthRatio = BigInt.from(10).pow(8);
  final double vInEth = v.toDouble() / weiToEthRatio.toDouble();
  return vInEth;
}

BigInt doubleToBigIntMoveForAptos(num v) => toBaseUnits(v, 8);
