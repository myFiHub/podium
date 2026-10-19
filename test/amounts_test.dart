import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/global/blockchain/amounts.dart';

void main() {
  test('ether amounts convert exactly to wei', () {
    expect(toBaseUnits(0.1, 18), BigInt.parse('100000000000000000'));
    expect(toBaseUnits(1.23456789, 18), BigInt.parse('1234567890000000000'));
    expect(toBaseUnits(25, 18), BigInt.parse('25000000000000000000'));
    expect(toBaseUnits(1e-7, 18), BigInt.parse('100000000000'));
    expect(parseValue(0.3).getInWei, BigInt.parse('300000000000000000'));
  });

  test('aptos amounts convert exactly to octas', () {
    expect(doubleToBigIntMoveForAptos(0.29), BigInt.from(29000000));
    expect(doubleToBigIntMoveForAptos(1.1), BigInt.from(110000000));
  });
}
