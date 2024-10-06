// file hello_world.dart
import 'dart:async';
import 'package:squadron/squadron.dart';
import 'jsoner.activator.g.dart';
part 'jsoner.worker.g.dart';

@SquadronService(
    baseUrl: '~/workers',
    targetPlatform: TargetPlatform.vm | TargetPlatform.web)
base class Jsoner {
  @SquadronMethod()
  Future<dynamic> jsoner([dynamic data]) async {
    return data.toJson();
  }
}
