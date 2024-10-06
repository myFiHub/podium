// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.0.6
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'jsoner.dart';

void main() {
  /// Web entry point for Jsoner
  run($JsonerInitializer);
}

EntryPoint $getJsonerActivator(SquadronPlatformType platform) {
  if (platform.isJs) {
    return Squadron.uri('~/workers/jsoner.web.g.dart.js');
  } else if (platform.isWasm) {
    return Squadron.uri('~/workers/jsoner.web.g.dart.wasm');
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
