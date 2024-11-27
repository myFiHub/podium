import 'package:web3dart/web3dart.dart';

String weiToDecimalString({
  required EtherAmount wei,
  int decimals = 4,
}) {
  return wei.getValueInUnit(EtherUnit.ether).toStringAsFixed(decimals);
}
